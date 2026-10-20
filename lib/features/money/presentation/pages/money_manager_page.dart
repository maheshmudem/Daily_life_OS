import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_decorations.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/widgets/app_shimmer_loader.dart';
import '../../../../core/widgets/quick_capture_sheet.dart';
import '../../../../di/injection_container.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../bloc/money_bloc.dart';

class MoneyManagerPage extends StatelessWidget {
  const MoneyManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MoneyBloc>()..add(const LoadMoney()),
      child: const _MoneyView(),
    );
  }
}

class _MoneyView extends StatefulWidget {
  const _MoneyView();

  @override
  State<_MoneyView> createState() => _MoneyViewState();
}

class _MoneyViewState extends State<_MoneyView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkScaffoldBackground : AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(
          StringConstants.navMoney,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.moduleMoney),
            onPressed: () => QuickCaptureSheet.show(context, mode: QuickCaptureMode.text),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.moduleMoney,
          unselectedLabelColor: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
          indicatorColor: AppColors.moduleMoney,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Subscriptions'),
            Tab(text: 'Lend & Borrow (IOU)'),
          ],
        ),
      ),
      body: BlocBuilder<MoneyBloc, MoneyState>(
        builder: (context, state) {
          if (state is MoneyLoading || state is MoneyInitial) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const AppShimmerLoader.card(height: 160),
                const SizedBox(height: 16),
                const AppShimmerLoader.card(height: 60),
                const SizedBox(height: 16),
                const AppShimmerLoader.card(height: 180),
              ],
            );
          }
          if (state is MoneyError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          if (state is MoneyLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildExpensesTab(context, state, isDark),
                _buildSubscriptionsTab(context, state, isDark),
                _buildIouTab(context, state, isDark),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ── Tab 1: Expenses ────────────────────────────────────────────────────────
  Widget _buildExpensesTab(BuildContext context, MoneyLoaded state, bool isDark) {
    final budget = state.budget;
    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 90),
      children: [
        // Hero Safe-to-Spend Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppDecorations.heroMoneyGradient,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SAFE-TO-SPEND TODAY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: AppRadius.radiusFull,
                    ),
                    child: Text(
                      '${budget.daysRemaining} Days Left',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '₹${budget.dailySafeSpend.toStringAsFixed(0)}',
                style: AppTextStyles.currencyHero.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 6),
              const Text(
                'Formula: (Budget - Fixed Bills - Spent) / Days',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetricStat('Spent', '₹${budget.totalSpent.toStringAsFixed(0)}'),
                  _buildMetricStat('Bills', '₹${budget.fixedBills.toStringAsFixed(0)}'),
                  _buildMetricStat('Budget', '₹${budget.monthlyBudget.toStringAsFixed(0)}'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Quick Category Pills
        const Text('Quick Category Logging', style: AppTextStyles.titleMedium),
        const SizedBox(height: 10),
        _buildCategoryPills(context, isDark),
        const SizedBox(height: 20),

        // Recent Transactions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Transactions', style: AppTextStyles.titleMedium),
            Text(
              'Auto-Sync & Manual',
              style: AppTextStyles.caption.copyWith(color: AppColors.moduleMoney),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (state.transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No transactions yet. Tap + to add one.',
                style: TextStyle(color: isDark ? AppColors.darkTextCaption : AppColors.textCaption),
              ),
            ),
          )
        else
          ...state.transactions.take(15).map((tx) => _buildExpenseItem(tx, isDark)),
      ],
    );
  }

  Widget _buildMetricStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
      ],
    );
  }

  Widget _buildCategoryPills(BuildContext context, bool isDark) {
    final categories = [
      {'name': 'Food', 'icon': Icons.restaurant_rounded},
      {'name': 'Travel', 'icon': Icons.directions_car_rounded},
      {'name': 'Bills', 'icon': Icons.bolt_rounded},
      {'name': 'Shopping', 'icon': Icons.shopping_bag_rounded},
      {'name': 'Health', 'icon': Icons.medical_services_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          return GestureDetector(
            onTap: () => QuickCaptureSheet.show(context, mode: QuickCaptureMode.text),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
                borderRadius: AppRadius.radiusFull,
                border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
              ),
              child: Row(
                children: [
                  Icon(cat['icon'] as IconData, size: 16, color: AppColors.moduleMoney),
                  const SizedBox(width: 6),
                  Text(
                    cat['name'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpenseItem(TransactionEntity tx, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.moduleMoney.withValues(alpha: 0.12),
            child: Icon(tx.icon, color: AppColors.moduleMoney, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(
                  '${tx.category} • ${tx.formattedDate}',
                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextCaption : AppColors.textCaption),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-₹${tx.amount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.moduleMoney),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                  borderRadius: AppRadius.radiusSm,
                ),
                child: Text(
                  tx.mode,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextCaption : AppColors.textCaption),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Subscriptions ───────────────────────────────────────────────────
  Widget _buildSubscriptionsTab(BuildContext context, MoneyLoaded state, bool isDark) {
    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 90),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.moneyWarning80.withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: AppRadius.radiusLg,
            border: Border.all(color: AppColors.moneyWarning80.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.moneyWarning80, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Auto-Kill alerts remind you 2 days prior to auto-debit so you never pay for unused services.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...state.subscriptions.map((sub) => _buildSubItem(context, sub, isDark)),
      ],
    );
  }

  Widget _buildSubItem(BuildContext context, SubscriptionEntity sub, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Icon(sub.icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sub.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(
                  'Renews ${sub.renewalLabel}',
                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextCaption : AppColors.textCaption),
                ),
                if (sub.autoKillEnabled)
                  GestureDetector(
                    onTap: () => context.read<MoneyBloc>().add(ToggleAutoKill(sub.id)),
                    child: const Text(
                      '⚡ Auto-Kill Protection ON • tap to disable',
                      style: TextStyle(fontSize: 11, color: AppColors.moduleMoney, fontWeight: FontWeight.w700),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () => context.read<MoneyBloc>().add(ToggleAutoKill(sub.id)),
                    child: Text(
                      'Tap to enable Auto-Kill',
                      style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextCaption : AppColors.textCaption),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '₹${sub.amount.toStringAsFixed(0)}/mo',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── Tab 3: Lend & Borrow (IOU) ────────────────────────────────────────────
  Widget _buildIouTab(BuildContext context, MoneyLoaded state, bool isDark) {
    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 90),
      children: [
        if (state.ious.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'No active IOUs.',
                style: TextStyle(color: isDark ? AppColors.darkTextCaption : AppColors.textCaption),
              ),
            ),
          )
        else
          ...state.ious.map((iou) {
            final color = iou.isLent ? AppColors.moduleMoney : AppColors.error;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
                borderRadius: AppRadius.radiusLg,
                border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(
                      iou.isLent ? Icons.call_made_rounded : Icons.call_received_rounded,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(iou.person, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        Text(
                          '${iou.typeLabel} • ${iou.note}',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextCaption : AppColors.textCaption),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${iou.amount.toStringAsFixed(0)}',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color),
                      ),
                      GestureDetector(
                        onTap: () => context.read<MoneyBloc>().add(SettleIou(iou.id)),
                        child: Text(
                          'Settle',
                          style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
