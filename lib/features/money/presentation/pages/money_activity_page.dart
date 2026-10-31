import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/search_bar_widget.dart';
import '../../domain/entities/money_category.dart';
import '../../domain/entities/transaction_entity.dart';
import '../bloc/money_bloc.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/money_shell_scope.dart';
import '../widgets/month_picker_sheet.dart';
import '../widgets/transaction_tile.dart';

/// Money Tab 1 — Activity:
/// Clean, grouped transaction history matching `docs/expensetracker-main/lib/screens/transactions_screen.dart`
/// with search, type & category filters, day-grouped cards with indented dividers,
/// tap-to-edit, and swipe-to-delete with confirmation.
class MoneyActivityPage extends StatefulWidget {
  const MoneyActivityPage({super.key});

  @override
  State<MoneyActivityPage> createState() => _MoneyActivityPageState();
}

class _MoneyActivityPageState extends State<MoneyActivityPage> {
  String _query = '';
  String _typeFilter = 'all'; // 'all' | 'expense' | 'income'
  String _categoryFilter = 'all';
  bool _allMonths = false;

  List<TransactionEntity> _applyFilters(MoneyLoaded state) {
    final source = _allMonths ? state.allTransactions : state.monthTransactions;
    final q = _query.trim().toLowerCase();
    return source.where((tx) {
      if (_typeFilter != 'all' && tx.type != _typeFilter) return false;
      if (_categoryFilter != 'all' && tx.categoryInfo.key != _categoryFilter) {
        return false;
      }
      if (q.isNotEmpty) {
        final matchTitle = tx.title.toLowerCase().contains(q);
        final matchCat = tx.categoryInfo.label.toLowerCase().contains(q);
        final matchMode = tx.mode.toLowerCase().contains(q);
        final matchNote = (tx.note ?? '').toLowerCase().contains(q);
        if (!matchTitle && !matchCat && !matchMode && !matchNote) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkScaffoldBackground
          : AppColors.scaffoldBackground,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => MoneyShellScope.handleBack(context),
        ),
        titleSpacing: 0,
        title: const Text(
          StringConstants.moneyNavActivity,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          BlocBuilder<MoneyBloc, MoneyState>(
            builder: (context, state) {
              if (state is! MoneyLoaded) return const SizedBox.shrink();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilterChip(
                    label: const Text(
                      'All time',
                      style: TextStyle(fontSize: 11.5),
                    ),
                    selected: _allMonths,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    selectedColor: AppColors.primary.withValues(alpha: 0.16),
                    onSelected: (v) => setState(() => _allMonths = v),
                  ),
                  const SizedBox(width: 6),
                  if (!_allMonths)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: MonthSelectorChip(
                        selectedMonth: state.selectedMonth,
                        onChanged: (m) =>
                            context.read<MoneyBloc>().add(ChangeMonth(m)),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<MoneyBloc, MoneyState>(
        builder: (context, state) {
          if (state is! MoneyLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final filtered = _applyFilters(state);
          final totalIn = filtered
              .where((t) => t.isIncome)
              .fold<double>(0, (s, t) => s + t.amount);
          final totalOut = filtered
              .where((t) => t.isExpense)
              .fold<double>(0, (s, t) => s + t.amount);

          // Group by calendar day
          final grouped = <DateTime, List<TransactionEntity>>{};
          for (final tx in filtered) {
            final dt = tx.dateTime;
            final key = DateTime(dt.year, dt.month, dt.day);
            grouped.putIfAbsent(key, () => []).add(tx);
          }
          final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
                child: SearchBarWidget(
                  hintText: StringConstants.searchTransactions,
                  onChanged: (val) => setState(() => _query = val),
                  onClear: () => setState(() => _query = ''),
                ),
              ),

              // Type + Category filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildTypeChip(StringConstants.allTypes, 'all', isDark),
                    const SizedBox(width: 6),
                    _buildTypeChip(StringConstants.expenses, 'expense', isDark),
                    const SizedBox(width: 6),
                    _buildTypeChip(StringConstants.income, 'income', isDark),
                    const SizedBox(width: 10),
                    ...MoneyCategory.all.map((cat) {
                      final selected = _categoryFilter == cat.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          visualDensity: VisualDensity.compact,
                          avatar: Icon(
                            cat.icon,
                            size: 13,
                            color: selected ? Colors.white : cat.color,
                          ),
                          label: Text(cat.shortLabel),
                          selected: selected,
                          showCheckmark: false,
                          selectedColor: cat.color,
                          labelStyle: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary),
                          ),
                          onSelected: (_) => setState(
                            () => _categoryFilter = selected ? 'all' : cat.key,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Summary strip
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SummaryPair(
                        label: StringConstants.income,
                        value: '+${CurrencyUtils.format(totalIn)}',
                        color: AppColors.success,
                      ),
                      _SummaryPair(
                        label: StringConstants.expenses,
                        value: '-${CurrencyUtils.format(totalOut)}',
                        color: AppColors.error,
                      ),
                      _SummaryPair(
                        label: StringConstants.netCashflow,
                        value: CurrencyUtils.signed(
                          totalIn - totalOut,
                          isCredit: totalIn >= totalOut,
                        ),
                        color: totalIn >= totalOut
                            ? AppColors.primary
                            : AppColors.error,
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: filtered.isEmpty
                    ? AppEmptyState(
                        icon: Icons.receipt_long_rounded,
                        title:
                            _query.isEmpty &&
                                _typeFilter == 'all' &&
                                _categoryFilter == 'all'
                            ? StringConstants.noTransactionsTitle
                            : StringConstants.noMatchingTransactions,
                        description:
                            _query.isEmpty &&
                                _typeFilter == 'all' &&
                                _categoryFilter == 'all'
                            ? StringConstants.noTransactionsMessage
                            : StringConstants.noMatchingTransactionsMessage,
                        actionLabel: StringConstants.addExpense,
                        onAction: () => AddTransactionSheet.show(context),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
                        itemCount: days.length,
                        itemBuilder: (context, dayIdx) {
                          final day = days[dayIdx];
                          final items = grouped[day]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 10,
                                  bottom: 6,
                                ),
                                child: Text(
                                  AppDateUtils.formatDayHeader(day),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkSurface
                                      : AppColors.surface,
                                  borderRadius: AppRadius.borderLg,
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.border,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  children: [
                                    for (var i = 0; i < items.length; i++) ...[
                                      if (i > 0)
                                        Divider(
                                          height: 1,
                                          indent: 68,
                                          color: isDark
                                              ? AppColors.darkBorder
                                              : AppColors.border,
                                        ),
                                      Dismissible(
                                        key: ValueKey('tx_${items[i].id}'),
                                        direction: DismissDirection.endToStart,
                                        background: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                          ),
                                          alignment: Alignment.centerRight,
                                          color: AppColors.error,
                                          child: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.white,
                                          ),
                                        ),
                                        confirmDismiss: (_) =>
                                            ConfirmationDialog.show(
                                              context,
                                              title: StringConstants
                                                  .deleteTransactionTitle,
                                              message: StringConstants
                                                  .deleteTransactionMessage,
                                              confirmLabel:
                                                  StringConstants.delete,
                                              isDestructive: true,
                                            ),
                                        onDismissed: (_) {
                                          context.read<MoneyBloc>().add(
                                            DeleteTransaction(items[i].id),
                                          );
                                          SnackbarUtils.showInfo(
                                            context,
                                            StringConstants.transactionDeleted,
                                          );
                                        },
                                        child: TransactionTile(
                                          transaction: items[i],
                                          showCard: false,
                                          onTap: () => AddTransactionSheet.show(
                                            context,
                                            existing: items[i],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTypeChip(String label, String value, bool isDark) {
    final selected = _typeFilter == value;
    return ChoiceChip(
      visualDensity: VisualDensity.compact,
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: selected
            ? Colors.white
            : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
      ),
      onSelected: (_) => setState(() => _typeFilter = value),
    );
  }
}

class _SummaryPair extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryPair({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
