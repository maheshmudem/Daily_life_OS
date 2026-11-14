import '../../../../config/theme/app_colors.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../money/domain/usecases/get_transactions_and_budget_usecase.dart';
import '../../../money/domain/usecases/manage_subscriptions_and_ious_usecase.dart';
import '../../../notes/domain/usecases/get_notes_usecase.dart';
import '../../../planner/domain/usecases/get_planner_items_usecase.dart';
import '../../../security/domain/repositories/security_repository.dart';
import '../../../today_hub/domain/usecases/get_habits_usecase.dart';
import '../../../today_hub/domain/usecases/get_today_timeline_usecase.dart';
import '../../../vault/domain/usecases/get_vault_items_usecase.dart';
import '../../domain/entities/command_palette_entry_entity.dart';
import '../models/command_palette_entry_model.dart';

/// Reads searchable items from every module.
///
/// Each loader **throws** [CacheException] on failure; the repository decides
/// how to aggregate partial results.
abstract class CommandPaletteLocalDataSource {
  List<CommandPaletteEntryModel> getQuickCommands();
  Future<List<CommandPaletteEntryModel>> getTodayEntries();
  Future<List<CommandPaletteEntryModel>> getPlannerEntries();
  Future<List<CommandPaletteEntryModel>> getMoneyEntries();
  Future<List<CommandPaletteEntryModel>> getNotesEntries();
  Future<List<CommandPaletteEntryModel>> getVaultEntries();
}

class CommandPaletteLocalDataSourceImpl
    implements CommandPaletteLocalDataSource {
  /// Upper bound on transactions indexed, keeps the palette fast for
  /// users with years of history.
  static const int maxIndexedTransactions = 25;

  final GetHabitsUseCase _getHabits;
  final GetTodayTimelineUseCase _getTodayTimeline;
  final GetPlannerItemsUseCase _getPlannerItems;
  final GetAllTransactionsUseCase _getAllTransactions;
  final GetSubscriptionsUseCase _getSubscriptions;
  final GetIousUseCase _getIous;
  final GetNotesUseCase _getNotes;
  final GetVaultPasswordsUseCase _getVaultPasswords;
  final GetVaultDocumentsUseCase _getVaultDocuments;
  final SecurityRepository? securityRepository;

  const CommandPaletteLocalDataSourceImpl({
    required GetHabitsUseCase getHabitsUseCase,
    required GetTodayTimelineUseCase getTodayTimelineUseCase,
    required GetPlannerItemsUseCase getPlannerItemsUseCase,
    required GetAllTransactionsUseCase getAllTransactionsUseCase,
    required GetSubscriptionsUseCase getSubscriptionsUseCase,
    required GetIousUseCase getIousUseCase,
    required GetNotesUseCase getNotesUseCase,
    required GetVaultPasswordsUseCase getVaultPasswordsUseCase,
    required GetVaultDocumentsUseCase getVaultDocumentsUseCase,
    this.securityRepository,
  }) : _getHabits = getHabitsUseCase,
       _getTodayTimeline = getTodayTimelineUseCase,
       _getPlannerItems = getPlannerItemsUseCase,
       _getAllTransactions = getAllTransactionsUseCase,
       _getSubscriptions = getSubscriptionsUseCase,
       _getIous = getIousUseCase,
       _getNotes = getNotesUseCase,
       _getVaultPasswords = getVaultPasswordsUseCase,
       _getVaultDocuments = getVaultDocumentsUseCase;

  /// Wraps low-level errors (SQLite, secure storage, ...) in [CacheException].
  Future<List<CommandPaletteEntryModel>> _load(
    String module,
    Future<List<CommandPaletteEntryModel>> Function() loader,
  ) async {
    try {
      return await loader();
    } on CacheException {
      rethrow;
    } catch (e) {
      throw CacheException(message: 'Failed to index $module: $e');
    }
  }

  @override
  List<CommandPaletteEntryModel> getQuickCommands() {
    return [
      CommandPaletteEntryModel(
        id: 'cmd_quick_type',
        title: 'Quick Capture (Smart NLP)',
        subtitle: 'Type an expense, reminder, task, or note with auto-routing',
        module: CommandPaletteModules.actions,
        iconType: CommandPaletteIconType.bolt,
        accentColorValue: AppColors.primary.toARGB32(),
        badgeText: 'Command',
        captureModeName: 'text',
      ),
      CommandPaletteEntryModel(
        id: 'cmd_voice',
        title: 'Voice Capture (Hold to Speak)',
        subtitle: 'Dictate hands-free into Today, Planner, Money, or Notes',
        module: CommandPaletteModules.actions,
        iconType: CommandPaletteIconType.mic,
        accentColorValue: AppColors.voiceWaveform.toARGB32(),
        badgeText: 'Voice',
        captureModeName: 'voice',
      ),
      CommandPaletteEntryModel(
        id: 'cmd_scan',
        title: 'Scan Bill / Receipt OCR',
        subtitle: 'Extract merchant, amount, or text from bills and documents',
        module: CommandPaletteModules.actions,
        iconType: CommandPaletteIconType.scanner,
        accentColorValue: AppColors.moduleMoney.toARGB32(),
        badgeText: 'Scanner',
        captureModeName: 'scan',
      ),
      CommandPaletteEntryModel(
        id: 'cmd_pomodoro',
        title: 'Start Focus Sprint (Pomodoro)',
        subtitle: 'Jump to Planner Focus Timer, Flowtime & Ambience Mixer',
        module: CommandPaletteModules.actions,
        iconType: CommandPaletteIconType.timer,
        accentColorValue: AppColors.moduleTime.toARGB32(),
        badgeText: CommandPaletteModules.planner,
        targetTabIndex: 1,
      ),
      CommandPaletteEntryModel(
        id: 'cmd_money',
        title: 'Open Money Manager & Budgets',
        subtitle: 'View Safe-to-Spend, 14-day trend, subscriptions & IOUs',
        module: CommandPaletteModules.actions,
        iconType: CommandPaletteIconType.wallet,
        accentColorValue: AppColors.moduleMoney.toARGB32(),
        badgeText: CommandPaletteModules.money,
        targetTabIndex: 2,
      ),
      CommandPaletteEntryModel(
        id: 'cmd_notes',
        title: 'Open Notes & Daily Scratchpad',
        subtitle: 'Jot ideas, interactive checklists, and @tagged notes',
        module: CommandPaletteModules.actions,
        iconType: CommandPaletteIconType.lightbulb,
        accentColorValue: AppColors.moduleNotes.toARGB32(),
        badgeText: CommandPaletteModules.notes,
        targetTabIndex: 3,
      ),
      CommandPaletteEntryModel(
        id: 'cmd_vault',
        title: 'Open AES-256 Secure Vault',
        subtitle: 'Access encrypted logins, key generator & Warranty Locker',
        module: CommandPaletteModules.actions,
        iconType: CommandPaletteIconType.security,
        accentColorValue: AppColors.moduleVault.toARGB32(),
        badgeText: CommandPaletteModules.vault,
        targetTabIndex: 4,
      ),
      CommandPaletteEntryModel(
        id: 'cmd_profile',
        title: 'Profile & OS Preferences',
        subtitle:
            'Edit name, avatar, Quick-Access Ball, theme, currency & focus goal',
        module: CommandPaletteModules.actions,
        iconType: CommandPaletteIconType.bolt,
        accentColorValue: AppColors.primary.toARGB32(),
        badgeText: 'OS Prefs',
        targetTabIndex: 0,
      ),
    ];
  }

  @override
  Future<List<CommandPaletteEntryModel>> getTodayEntries() {
    return _load(CommandPaletteModules.today, () async {
      final habits = await _getHabits();
      final timeline = await _getTodayTimeline();
      return [
        for (final h in habits)
          CommandPaletteEntryModel(
            id: 'habit_${h.id}',
            title: h.title,
            subtitle:
                'Habit • ${h.streakDays}d streak • ${h.isDoneToday ? 'Completed today' : 'Pending'}',
            module: CommandPaletteModules.today,
            iconType: CommandPaletteIconType.repeat,
            accentColorValue: AppColors.primary.toARGB32(),
            badgeText: 'Habit',
            targetTabIndex: 0,
          ),
        for (final t in timeline)
          CommandPaletteEntryModel(
            id: 'timeline_${t.id}',
            title: t.title,
            subtitle: '${t.time} • ${t.category}',
            module: CommandPaletteModules.today,
            iconType: CommandPaletteIconType.schedule,
            accentColorValue: AppColors.primary.toARGB32(),
            badgeText: 'Timeline',
            targetTabIndex: 0,
          ),
      ];
    });
  }

  @override
  Future<List<CommandPaletteEntryModel>> getPlannerEntries() {
    return _load(CommandPaletteModules.planner, () async {
      final plannerItems = await _getPlannerItems('all');
      return [
        for (final p in plannerItems)
          CommandPaletteEntryModel(
            id: 'planner_${p.id}',
            title: p.title,
            subtitle:
                '${p.category} • ${p.dateDisplay}${p.timeRange.isNotEmpty ? ' • ${p.timeRange}' : ''}',
            module: CommandPaletteModules.planner,
            iconType: CommandPaletteIconType.eventAvailable,
            accentColorValue: AppColors.moduleTime.toARGB32(),
            badgeText: p.isDone ? 'Done' : 'Task',
            targetTabIndex: 1,
          ),
      ];
    });
  }

  @override
  Future<List<CommandPaletteEntryModel>> getMoneyEntries() {
    return _load(CommandPaletteModules.money, () async {
      final txs = await _getAllTransactions();
      final subs = await _getSubscriptions();
      final ious = await _getIous();
      return [
        for (final tx in txs.take(maxIndexedTransactions))
          CommandPaletteEntryModel(
            id: 'tx_${tx.id}',
            title: tx.title,
            subtitle:
                '${tx.category} • ${tx.mode} • ${CurrencyUtils.signed(tx.amount, isCredit: !tx.isExpense)}',
            module: CommandPaletteModules.money,
            iconType: tx.isExpense
                ? CommandPaletteIconType.northEast
                : CommandPaletteIconType.southWest,
            accentColorValue: AppColors.moduleMoney.toARGB32(),
            badgeText: tx.isExpense ? 'Expense' : 'Income',
            targetTabIndex: 2,
          ),
        for (final s in subs)
          CommandPaletteEntryModel(
            id: 'sub_${s.id}',
            title: s.name,
            subtitle:
                'Subscription • ${CurrencyUtils.format(s.amount)}/mo • Renews ${s.renewalDate}',
            module: CommandPaletteModules.money,
            iconType: CommandPaletteIconType.autorenew,
            accentColorValue: AppColors.moduleMoney.toARGB32(),
            badgeText: 'Sub',
            targetTabIndex: 2,
          ),
        for (final iou in ious)
          CommandPaletteEntryModel(
            id: 'iou_${iou.id}',
            title: iou.person,
            subtitle:
                '${iou.isLent ? 'Lent' : 'Borrowed'} • ${CurrencyUtils.format(iou.amount)} • ${iou.dueDate}',
            module: CommandPaletteModules.money,
            iconType: CommandPaletteIconType.handshake,
            accentColorValue: AppColors.moduleMoney.toARGB32(),
            badgeText: 'IOU',
            targetTabIndex: 2,
          ),
      ];
    });
  }

  @override
  Future<List<CommandPaletteEntryModel>> getNotesEntries() {
    return _load(CommandPaletteModules.notes, () async {
      final notes = await _getNotes();
      return [
        for (final n in notes)
          CommandPaletteEntryModel(
            id: 'note_${n.id}',
            title: n.title,
            subtitle: n.content.replaceAll('\n', ' '),
            module: CommandPaletteModules.notes,
            iconType: n.isPinned
                ? CommandPaletteIconType.pushPin
                : CommandPaletteIconType.stickyNote,
            accentColorValue: AppColors.moduleNotes.toARGB32(),
            badgeText: n.isPinned ? 'Pinned' : 'Note',
            targetTabIndex: 3,
          ),
      ];
    });
  }

  @override
  Future<List<CommandPaletteEntryModel>> getVaultEntries() {
    return _load(CommandPaletteModules.vault, () async {
      final secRepo = securityRepository;
      if (secRepo != null) {
        final config = await secRepo.getConfig();
        if (config.isSecurityEnabled && !secRepo.isMasterSessionUnlocked) {
          return const <CommandPaletteEntryModel>[];
        }
      }
      final passwords = await _getVaultPasswords();
      final docs = await _getVaultDocuments();
      return [
        for (final pw in passwords)
          CommandPaletteEntryModel(
            id: 'vault_pw_${pw.id}',
            title: pw.title,
            subtitle: '${pw.category} Login • ${pw.username}',
            module: CommandPaletteModules.vault,
            iconType: CommandPaletteIconType.key,
            accentColorValue: AppColors.moduleVault.toARGB32(),
            badgeText: 'Login',
            targetTabIndex: 4,
          ),
        for (final doc in docs)
          CommandPaletteEntryModel(
            id: 'vault_doc_${doc.id}',
            title: doc.title,
            subtitle: '${doc.category} • ${doc.expiry}',
            module: CommandPaletteModules.vault,
            iconType: CommandPaletteIconType.verifiedUser,
            accentColorValue: AppColors.moduleVault.toARGB32(),
            badgeText: doc.isExpiringSoon ? 'Expiring' : 'Warranty',
            targetTabIndex: 4,
          ),
      ];
    });
  }
}
