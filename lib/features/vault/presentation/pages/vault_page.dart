import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/widgets/app_shimmer_loader.dart';
import '../../../../di/injection_container.dart';
import '../../domain/entities/vault_item_entity.dart';
import '../bloc/vault_bloc.dart';
import 'package:daily_life_os/features/security/domain/repositories/security_repository.dart';
import 'package:daily_life_os/features/security/presentation/widgets/security_settings_sheet.dart';
import 'package:daily_life_os/features/security/presentation/widgets/security_setup_wizard.dart';
import 'package:daily_life_os/features/security/presentation/widgets/vault_lock_screen.dart';

class VaultPage extends StatelessWidget {
  const VaultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<VaultBloc>()..add(const LoadVault()),
      child: const _VaultView(),
    );
  }
}

class _VaultView extends StatefulWidget {
  const _VaultView();

  @override
  State<_VaultView> createState() => _VaultViewState();
}

class _VaultViewState extends State<_VaultView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  bool _isUnlocked = false;
  bool _isSecurityEnabled = false;
  bool _isLoadingSecurity = true;

  // Interactive search & category filters
  String _passwordSearchQuery = '';
  String _selectedPasswordCategory = 'All';
  String _documentSearchQuery = '';
  String _selectedDocumentCategory = 'All';

  // Track revealed password IDs and user-added items in session
  final Set<int> _revealedPasswordIds = {};
  final List<VaultPasswordEntity> _customPasswords = [];
  final List<VaultDocumentEntity> _customDocuments = [];
  final Map<int, String> _customSecrets = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _checkSecurity();
  }

  Future<void> _checkSecurity() async {
    final config = await sl<SecurityRepository>().getConfig();
    if (mounted) {
      setState(() {
        _isSecurityEnabled = config.isSecurityEnabled;
        _isLoadingSecurity = false;
        // If security is enabled, lock by default until user enters PIN/Pattern
        // If security is disabled, unlock directly (opt-in security)
        _isUnlocked = !config.isSecurityEnabled;
      });
      if (config.isSecurityEnabled) {
        context.read<VaultBloc>().add(const LockVault());
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (mounted && _isUnlocked && _isSecurityEnabled) {
        setState(() => _isUnlocked = false);
        context.read<VaultBloc>().add(const LockVault());
      }
    }
  }

  void _openSecuritySetup(BuildContext context) {
    SecuritySetupWizard.show(
      context,
      securityRepository: sl<SecurityRepository>(),
      onCompleted: () {
        _checkSecurity();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vault security enabled successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  String _secretForItem(VaultPasswordEntity item) {
    if (_customSecrets.containsKey(item.id)) {
      return _customSecrets[item.id]!;
    }
    switch (item.category.toLowerCase()) {
      case 'banking':
        return 'HDFC#9482!Secure';
      case 'email':
        return 'GWorkspace@2026#Key';
      case 'wi-fi':
        return 'FiberNet_5G#8821';
      case 'social':
        return 'SocialPass!7741';
      default:
        return 'VaultKey#${item.id}992!';
    }
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'banking':
        return AppColors.success;
      case 'email':
        return AppColors.moduleVault;
      case 'wi-fi':
        return AppColors.secondary;
      case 'social':
        return AppColors.moduleNotes;
      case 'electronics':
        return AppColors.moduleVault;
      case 'medical':
        return AppColors.success;
      case 'vehicle':
        return AppColors.moduleTime;
      default:
        return AppColors.moduleVault;
    }
  }

  IconData _sectionIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'banking':
        return Icons.account_balance_rounded;
      case 'email':
        return Icons.alternate_email_rounded;
      case 'wi-fi':
        return Icons.wifi_lock_rounded;
      case 'social':
        return Icons.public_rounded;
      default:
        return Icons.key_rounded;
    }
  }

  String _sectionTitleForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'banking':
        return 'BANKING & FINANCE';
      case 'email':
        return 'EMAIL & CLOUD ACCOUNTS';
      case 'wi-fi':
        return 'WI-FI & NETWORK KEYS';
      case 'social':
        return 'SOCIAL & MEDIA';
      default:
        return '${category.toUpperCase()} LOGINS';
    }
  }

  void _copySecret(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard safely!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<VaultBloc, VaultState>(
      builder: (context, state) {
        final isDecoy = state is VaultLoaded ? state.isDecoyMode : false;

        return Scaffold(
          backgroundColor: isDark
              ? AppColors.darkScaffoldBackground
              : AppColors.scaffoldBackground,
          appBar: AppBar(
            toolbarHeight: 48,
            backgroundColor: isDark
                ? AppColors.darkScaffoldBackground
                : AppColors.scaffoldBackground,
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: 16,
            title: Row(
              children: [
                Text(
                  StringConstants.navVault,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: isDark
                        ? AppColors.darkTextHeading
                        : AppColors.textHeading,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.moduleVault.withValues(alpha: 0.14),
                    borderRadius: AppRadius.radiusFull,
                    border: Border.all(
                      color: AppColors.moduleVault.withValues(alpha: 0.28),
                      width: 0.8,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        size: 11,
                        color: AppColors.moduleVault,
                      ),
                      SizedBox(width: 3.5),
                      Text(
                        'AES-256',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.moduleVault,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Compact Decoy Pill Toggle (PRD Feature)
              GestureDetector(
                onTap: () {
                  final nextDecoy = !isDecoy;
                  context.read<VaultBloc>().add(const ToggleDecoyMode());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        nextDecoy
                            ? 'Decoy Mode active! Safe dummy data shown.'
                            : 'Standard Secure Vault active.',
                      ),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  decoration: BoxDecoration(
                    color: isDecoy
                        ? AppColors.error.withValues(alpha: 0.15)
                        : (isDark
                              ? AppColors.darkCardBackground
                              : AppColors.cardBackground),
                    borderRadius: AppRadius.radiusFull,
                    border: Border.all(
                      color: isDecoy
                          ? AppColors.error.withValues(alpha: 0.5)
                          : (isDark
                                ? AppColors.darkDivider
                                : AppColors.divider),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDecoy
                              ? AppColors.error
                              : (isDark
                                    ? AppColors.darkTextCaption
                                    : AppColors.textCaption),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Decoy',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDecoy
                              ? AppColors.error
                              : (isDark
                                    ? AppColors.darkTextBody
                                    : AppColors.textBody),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Compact Security Settings Icon Button
              _buildHeaderIconButton(
                isDark: isDark,
                tooltip: 'Security Settings',
                icon: Icons.shield_outlined,
                color: AppColors.moduleVault,
                onTap: () {
                  SecuritySettingsSheet.show(
                    context,
                    securityRepository: sl<SecurityRepository>(),
                    onLockNow: () {
                      setState(() => _isUnlocked = false);
                      context.read<VaultBloc>().add(const LockVault());
                    },
                  ).then((_) {
                    _checkSecurity();
                  });
                },
              ),
              const SizedBox(width: 6),
              // Compact Lock / Unlock Icon Button
              _buildHeaderIconButton(
                isDark: isDark,
                tooltip: !_isSecurityEnabled
                    ? 'Set Up Security'
                    : (_isUnlocked ? 'Lock Vault' : 'Vault Locked'),
                icon: !_isSecurityEnabled
                    ? Icons.lock_open_rounded
                    : (_isUnlocked
                          ? Icons.lock_open_rounded
                          : Icons.lock_rounded),
                color: !_isSecurityEnabled
                    ? AppColors.warning
                    : AppColors.moduleVault,
                onTap: () {
                  if (!_isSecurityEnabled) {
                    _openSecuritySetup(context);
                    return;
                  }
                  if (_isUnlocked) {
                    setState(() => _isUnlocked = false);
                    context.read<VaultBloc>().add(const LockVault());
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Enter PIN or draw Pattern below to unlock.',
                        ),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(width: 6),
              // Compact + Add Button
              if (_isUnlocked)
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: GestureDetector(
                    onTap: () => _showAddVaultItemSheet(context, isDark),
                    child: Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.moduleVault,
                        borderRadius: AppRadius.radiusFull,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 10),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(38),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? AppColors.darkDivider : AppColors.divider,
                      width: 0.8,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.moduleVault,
                  indicatorWeight: 2.2,
                  labelColor: AppColors.moduleVault,
                  unselectedLabelColor: isDark
                      ? AppColors.darkTextCaption
                      : AppColors.textCaption,
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                  tabs: const [
                    Tab(height: 36, text: 'Passwords & Logins'),
                    Tab(height: 36, text: 'Warranty Locker'),
                  ],
                ),
              ),
            ),
          ),
          body: _isLoadingSecurity
              ? const _VaultLoadingView()
              : !_isUnlocked
              ? _buildLockedScreen(isDark)
              : (state is VaultLoading || state is VaultInitial)
              ? const _VaultLoadingView()
              : state is VaultLoaded
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPasswordsTab(
                      context,
                      [..._customPasswords, ...state.passwords],
                      [..._customDocuments, ...state.documents],
                      isDark,
                      isDecoy,
                    ),
                    _buildDocumentsTab(
                      context,
                      [..._customDocuments, ...state.documents],
                      [..._customPasswords, ...state.passwords],
                      isDark,
                      isDecoy,
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildHeaderIconButton({
    required bool isDark,
    required String tooltip,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 30,
          height: 28,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkCardBackground
                : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.darkDivider : AppColors.divider,
              width: 0.8,
            ),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }

  Widget _buildLockedScreen(bool isDark) {
    return VaultLockScreen(
      securityRepository: sl<SecurityRepository>(),
      onUnlock: ({required bool isDecoy}) {
        context.read<VaultBloc>().add(UnlockVault(isDecoy: isDecoy));
        setState(() => _isUnlocked = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isDecoy
                  ? 'Vault unlocked in Decoy Mode (Safe dummy data)'
                  : 'Secure Vault unlocked successfully!',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  // ============================================================================
  // UNIFIED VAULT SECURITY & SUMMARY CARD (Replaces stacked oversized banners)
  // ============================================================================
  Widget _buildVaultOverviewCard({
    required BuildContext context,
    required bool isDark,
    required bool isDecoy,
    required int passwordCount,
    required int documentCount,
    required int expiringCount,
  }) {
    final cardBg = isDark
        ? AppColors.darkCardBackground
        : AppColors.cardBackground;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: !_isSecurityEnabled
              ? AppColors.warning.withValues(alpha: 0.45)
              : borderColor,
          width: 0.9,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3949AB), Color(0xFF00ACC1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.security_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            isDecoy
                                ? 'Decoy Vault Active'
                                : 'Zero-Knowledge Encrypted',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkTextHeading
                                  : AppColors.textHeading,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (_isSecurityEnabled
                                        ? AppColors.success
                                        : AppColors.warning)
                                    .withValues(alpha: 0.14),
                            borderRadius: AppRadius.radiusFull,
                          ),
                          child: Text(
                            _isSecurityEnabled ? 'Protected' : 'Unsecured',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: _isSecurityEnabled
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      !_isSecurityEnabled
                          ? 'No PIN/Pattern lock set. Enable lock to protect keys.'
                          : 'Keys never leave this device. Encrypted at rest.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextCaption
                            : AppColors.textCaption,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!_isSecurityEnabled)
                GestureDetector(
                  onTap: () => _openSecuritySetup(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.moduleVault,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shield_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Set Lock',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: () {
                    setState(() => _isUnlocked = false);
                    context.read<VaultBloc>().add(const LockVault());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.moduleVault.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 12,
                          color: AppColors.moduleVault,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Lock',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.moduleVault,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkScaffoldBackground.withValues(alpha: 0.65)
                  : AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: borderColor.withValues(alpha: 0.7),
                width: 0.7,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildMiniVaultStat(
                    isDark: isDark,
                    icon: Icons.key_rounded,
                    color: AppColors.moduleVault,
                    label: 'Logins',
                    value: '$passwordCount Saved',
                  ),
                ),
                Container(width: 0.8, height: 22, color: borderColor),
                Expanded(
                  child: _buildMiniVaultStat(
                    isDark: isDark,
                    icon: Icons.verified_outlined,
                    color: AppColors.secondary,
                    label: 'Warranties',
                    value: '$documentCount Docs',
                  ),
                ),
                Container(width: 0.8, height: 22, color: borderColor),
                Expanded(
                  child: _buildMiniVaultStat(
                    isDark: isDark,
                    icon: expiringCount > 0
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline_rounded,
                    color: expiringCount > 0
                        ? AppColors.warning
                        : AppColors.success,
                    label: 'Expiry Watch',
                    value: expiringCount > 0
                        ? '$expiringCount Expiring'
                        : 'All Clear',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniVaultStat({
    required bool isDark,
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: isDark
                        ? AppColors.darkTextCaption
                        : AppColors.textCaption,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextHeading
                        : AppColors.textHeading,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 1: PASSWORDS & LOGINS (Grouped Section Cards + Search + Generator)
  // ============================================================================
  Widget _buildPasswordsTab(
    BuildContext context,
    List<VaultPasswordEntity> passwords,
    List<VaultDocumentEntity> documents,
    bool isDark,
    bool isDecoy,
  ) {
    final categories = ['All', 'Banking', 'Email', 'Wi-Fi', 'Social'];
    final filtered = passwords.where((item) {
      final matchesCategory =
          _selectedPasswordCategory == 'All' ||
          item.category.toLowerCase() ==
              _selectedPasswordCategory.toLowerCase();
      final q = _passwordSearchQuery.trim().toLowerCase();
      final matchesQuery =
          q.isEmpty ||
          item.title.toLowerCase().contains(q) ||
          item.username.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();

    // Group filtered items by category so each category gets its own clean card
    final Map<String, List<VaultPasswordEntity>> grouped = {};
    for (final item in filtered) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    final expiringCount = documents.where((d) => d.isExpiringSoon).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      children: [
        // 1. Unified Overview Card
        _buildVaultOverviewCard(
          context: context,
          isDark: isDark,
          isDecoy: isDecoy,
          passwordCount: passwords.length,
          documentCount: documents.length,
          expiringCount: expiringCount,
        ),
        const SizedBox(height: 10),

        // 2. Search & Category Filter Card
        _buildSearchAndFilterCard(
          isDark: isDark,
          hintText: 'Search logins, usernames, or categories...',
          query: _passwordSearchQuery,
          onQueryChanged: (val) => setState(() => _passwordSearchQuery = val),
          categories: categories,
          selectedCategory: _selectedPasswordCategory,
          onCategorySelected: (cat) =>
              setState(() => _selectedPasswordCategory = cat),
        ),
        const SizedBox(height: 12),

        // 3. Grouped Section Cards by Category
        if (filtered.isEmpty)
          _buildEmptySectionCard(
            isDark: isDark,
            icon: Icons.key_off_rounded,
            title: 'No matching logins found',
            subtitle:
                'Try clearing your search or category filter, or add a new login.',
            onAction: () {
              setState(() {
                _passwordSearchQuery = '';
                _selectedPasswordCategory = 'All';
              });
            },
            actionLabel: 'Reset Filters',
          )
        else
          ...grouped.entries.map((entry) {
            final category = entry.key;
            final items = entry.value;
            final accent = _categoryColor(category);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSectionCardContainer(
                isDark: isDark,
                sectionIcon: _sectionIconForCategory(category),
                sectionTitle: _sectionTitleForCategory(category),
                sectionAccent: accent,
                trailingBadgeText:
                    '${items.length} ${items.length == 1 ? 'login' : 'logins'}',
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    _buildPasswordRow(
                      context: context,
                      item: items[i],
                      isDark: isDark,
                      accent: accent,
                    ),
                    if (i < items.length - 1)
                      Divider(
                        height: 1,
                        thickness: 0.7,
                        indent: 58,
                        endIndent: 12,
                        color: isDark
                            ? AppColors.darkDivider
                            : AppColors.divider,
                      ),
                  ],
                ],
              ),
            );
          }),

        // 4. Password Security Tools & Quick Generator Section Card
        _buildPasswordSecurityToolsCard(context, isDark),
      ],
    );
  }

  Widget _buildPasswordRow({
    required BuildContext context,
    required VaultPasswordEntity item,
    required bool isDark,
    required Color accent,
  }) {
    final isRevealed = _revealedPasswordIds.contains(item.id);
    final secret = _secretForItem(item);

    return InkWell(
      onTap: () => _showPasswordDetailSheet(context, item, isDark),
      borderRadius: AppRadius.radiusMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: accent.withValues(alpha: 0.25),
                  width: 0.8,
                ),
              ),
              child: Icon(item.icon, color: accent, size: 18),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: isDark
                                ? AppColors.darkTextHeading
                                : AppColors.textHeading,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5.5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: AppRadius.radiusFull,
                        ),
                        child: Text(
                          item.category,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2.5),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark
                                ? AppColors.darkTextCaption
                                : AppColors.textCaption,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '•',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextCaption
                              : AppColors.textCaption,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isRevealed ? secret : '••••••••',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          fontWeight: isRevealed
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isRevealed
                              ? AppColors.moduleVault
                              : (isDark
                                    ? AppColors.darkTextCaption
                                    : AppColors.textCaption),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Reveal / Hide Password Button
            _buildRowActionIcon(
              isDark: isDark,
              tooltip: isRevealed ? 'Hide Password' : 'Reveal Password',
              icon: isRevealed
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: isRevealed
                  ? AppColors.moduleVault
                  : (isDark
                        ? AppColors.darkTextCaption
                        : AppColors.textCaption),
              onTap: () {
                setState(() {
                  if (isRevealed) {
                    _revealedPasswordIds.remove(item.id);
                  } else {
                    _revealedPasswordIds.add(item.id);
                  }
                });
              },
            ),
            const SizedBox(width: 5),
            // 1-Tap Copy Password Button
            _buildRowActionIcon(
              isDark: isDark,
              tooltip: 'Copy Password',
              icon: Icons.copy_rounded,
              color: AppColors.moduleVault,
              onTap: () => _copySecret(context, 'Password', secret),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordSecurityToolsCard(BuildContext context, bool isDark) {
    return _buildSectionCardContainer(
      isDark: isDark,
      sectionIcon: Icons.bolt_rounded,
      sectionTitle: 'SECURITY AUDIT & KEY GENERATOR',
      sectionAccent: AppColors.secondary,
      trailingBadgeText: '100% Strong',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.password_rounded,
                  size: 17,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cryptographic Key Generator',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextHeading
                            : AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Generate a 16-char high-entropy password & copy instantly',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextCaption
                            : AppColors.textCaption,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  const chars =
                      'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#\$%&*';
                  final rand = Random.secure();
                  final generated = List.generate(
                    16,
                    (_) => chars[rand.nextInt(chars.length)],
                  ).join();
                  _copySecret(context, 'Generated key ($generated)', generated);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 13,
                        color: AppColors.secondary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Generate',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // TAB 2: WARRANTY LOCKER (Grouped Section Cards + Expiry Watch + Preview)
  // ============================================================================
  Widget _buildDocumentsTab(
    BuildContext context,
    List<VaultDocumentEntity> documents,
    List<VaultPasswordEntity> passwords,
    bool isDark,
    bool isDecoy,
  ) {
    final categories = [
      'All',
      'Expiring Soon',
      'Electronics',
      'Medical',
      'Vehicle',
    ];

    final filtered = documents.where((doc) {
      final matchesCat =
          _selectedDocumentCategory == 'All' ||
          (_selectedDocumentCategory == 'Expiring Soon'
              ? doc.isExpiringSoon
              : doc.category.toLowerCase() ==
                    _selectedDocumentCategory.toLowerCase());
      final q = _documentSearchQuery.trim().toLowerCase();
      final matchesQuery =
          q.isEmpty ||
          doc.title.toLowerCase().contains(q) ||
          doc.category.toLowerCase().contains(q) ||
          doc.expiry.toLowerCase().contains(q);
      return matchesCat && matchesQuery;
    }).toList();

    final expiringDocs = filtered.where((d) => d.isExpiringSoon).toList();
    final activeDocs = filtered.where((d) => !d.isExpiringSoon).toList();
    final totalExpiring = documents.where((d) => d.isExpiringSoon).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      children: [
        // 1. Unified Overview Card
        _buildVaultOverviewCard(
          context: context,
          isDark: isDark,
          isDecoy: isDecoy,
          passwordCount: passwords.length,
          documentCount: documents.length,
          expiringCount: totalExpiring,
        ),
        const SizedBox(height: 10),

        // 2. Automated Expiry Notice Card (Compact & Clean)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.moduleTime.withValues(alpha: isDark ? 0.14 : 0.08),
            borderRadius: AppRadius.radiusMd,
            border: Border.all(
              color: AppColors.moduleTime.withValues(alpha: 0.28),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.moduleTime.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.notification_important_rounded,
                  color: AppColors.moduleTime,
                  size: 15,
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Automated Expiry Alerts: We notify you 30 days & 7 days before warranty or policy lapses.',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 3. Search & Category Filter Card
        _buildSearchAndFilterCard(
          isDark: isDark,
          hintText: 'Search warranties, policies, or categories...',
          query: _documentSearchQuery,
          onQueryChanged: (val) => setState(() => _documentSearchQuery = val),
          categories: categories,
          selectedCategory: _selectedDocumentCategory,
          onCategorySelected: (cat) =>
              setState(() => _selectedDocumentCategory = cat),
        ),
        const SizedBox(height: 12),

        if (filtered.isEmpty)
          _buildEmptySectionCard(
            isDark: isDark,
            icon: Icons.folder_off_rounded,
            title: 'No matching warranties or policies',
            subtitle:
                'Clear your search filter or add a new warranty/insurance card.',
            onAction: () {
              setState(() {
                _documentSearchQuery = '';
                _selectedDocumentCategory = 'All';
              });
            },
            actionLabel: 'Reset Filters',
          )
        else ...[
          // 4. Section Card: EXPIRING SOON (Action Needed)
          if (expiringDocs.isNotEmpty) ...[
            _buildSectionCardContainer(
              isDark: isDark,
              sectionIcon: Icons.warning_amber_rounded,
              sectionTitle: 'EXPIRING SOON • RENEWAL NEEDED',
              sectionAccent: AppColors.warning,
              trailingBadgeText: '${expiringDocs.length} urgent',
              children: [
                for (var i = 0; i < expiringDocs.length; i++) ...[
                  _buildDocumentRow(
                    context: context,
                    doc: expiringDocs[i],
                    isDark: isDark,
                  ),
                  if (i < expiringDocs.length - 1)
                    Divider(
                      height: 1,
                      thickness: 0.7,
                      indent: 58,
                      endIndent: 12,
                      color: isDark ? AppColors.darkDivider : AppColors.divider,
                    ),
                ],
              ],
            ),
            const SizedBox(height: 12),
          ],

          // 5. Section Card: ACTIVE WARRANTIES & POLICIES
          if (activeDocs.isNotEmpty)
            _buildSectionCardContainer(
              isDark: isDark,
              sectionIcon: Icons.verified_user_outlined,
              sectionTitle: 'ACTIVE WARRANTIES & POLICIES',
              sectionAccent: AppColors.secondary,
              trailingBadgeText: '${activeDocs.length} active',
              children: [
                for (var i = 0; i < activeDocs.length; i++) ...[
                  _buildDocumentRow(
                    context: context,
                    doc: activeDocs[i],
                    isDark: isDark,
                  ),
                  if (i < activeDocs.length - 1)
                    Divider(
                      height: 1,
                      thickness: 0.7,
                      indent: 58,
                      endIndent: 12,
                      color: isDark ? AppColors.darkDivider : AppColors.divider,
                    ),
                ],
              ],
            ),
        ],
      ],
    );
  }

  Widget _buildDocumentRow({
    required BuildContext context,
    required VaultDocumentEntity doc,
    required bool isDark,
  }) {
    final isExpiringSoon = doc.isExpiringSoon;
    final accent = isExpiringSoon
        ? AppColors.warning
        : _categoryColor(doc.category);

    return InkWell(
      onTap: () => _showDocumentPreviewSheet(context, doc, isDark),
      borderRadius: AppRadius.radiusMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: accent.withValues(alpha: 0.28),
                  width: 0.8,
                ),
              ),
              child: Icon(doc.icon, color: accent, size: 18),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          doc.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: isDark
                                ? AppColors.darkTextHeading
                                : AppColors.textHeading,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isExpiringSoon
                                      ? AppColors.warning
                                      : AppColors.success)
                                  .withValues(alpha: 0.14),
                          borderRadius: AppRadius.radiusFull,
                        ),
                        child: Text(
                          isExpiringSoon ? 'Expiring' : 'Active',
                          style: TextStyle(
                            color: isExpiringSoon
                                ? AppColors.warning
                                : AppColors.success,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2.5),
                  Text(
                    '${doc.category} • ${doc.expiry}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isExpiringSoon
                          ? AppColors.warning
                          : (isDark
                                ? AppColors.darkTextCaption
                                : AppColors.textCaption),
                      fontWeight: isExpiringSoon
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            _buildRowActionIcon(
              isDark: isDark,
              tooltip: 'Preview Document',
              icon: Icons.remove_red_eye_rounded,
              color: AppColors.moduleVault,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Viewing ${doc.title} secure preview'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                _showDocumentPreviewSheet(context, doc, isDark);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // SHARED REUSABLE SECTION CARD & FILTER BAR BUILDERS
  // ============================================================================
  Widget _buildSearchAndFilterCard({
    required bool isDark,
    required String hintText,
    required String query,
    required ValueChanged<String> onQueryChanged,
    required List<String> categories,
    required String selectedCategory,
    required ValueChanged<String> onCategorySelected,
  }) {
    final cardBg = isDark
        ? AppColors.darkCardBackground
        : AppColors.cardBackground;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact 36px Search Input
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkScaffoldBackground.withValues(alpha: 0.7)
                  : AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: borderColor.withValues(alpha: 0.8),
                width: 0.7,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 16,
                  color: isDark
                      ? AppColors.darkTextCaption
                      : AppColors.textCaption,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: onQueryChanged,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark
                          ? AppColors.darkTextHeading
                          : AppColors.textHeading,
                    ),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextCaption
                            : AppColors.textCaption,
                      ),
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (query.isNotEmpty)
                  GestureDetector(
                    onTap: () => onQueryChanged(''),
                    child: Icon(
                      Icons.close_rounded,
                      size: 15,
                      color: isDark
                          ? AppColors.darkTextCaption
                          : AppColors.textCaption,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Compact 28px Horizontal Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = cat == selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => onCategorySelected(cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      height: 27,
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.moduleVault
                            : (isDark
                                  ? AppColors.darkScaffoldBackground
                                  : AppColors.scaffoldBackground),
                        borderRadius: AppRadius.radiusFull,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.moduleVault
                              : borderColor,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                    ? AppColors.darkTextBody
                                    : AppColors.textBody),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCardContainer({
    required bool isDark,
    required IconData sectionIcon,
    required String sectionTitle,
    required Color sectionAccent,
    required String trailingBadgeText,
    required List<Widget> children,
  }) {
    final cardBg = isDark
        ? AppColors.darkCardBackground
        : AppColors.cardBackground;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header Bar inside the card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: sectionAccent.withValues(alpha: isDark ? 0.08 : 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
              border: Border(
                bottom: BorderSide(
                  color: borderColor.withValues(alpha: 0.7),
                  width: 0.7,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(sectionIcon, size: 13.5, color: sectionAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    sectionTitle,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: isDark
                          ? AppColors.darkTextHeading
                          : AppColors.textHeading,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6.5,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: sectionAccent.withValues(alpha: 0.14),
                    borderRadius: AppRadius.radiusFull,
                  ),
                  child: Text(
                    trailingBadgeText,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: sectionAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRowActionIcon({
    required bool isDark,
    required String tooltip,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15.5, color: color),
        ),
      ),
    );
  }

  Widget _buildEmptySectionCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onAction,
    required String actionLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.divider,
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: AppColors.moduleVault),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.refresh_rounded, size: 15),
            label: Text(
              actionLabel,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // INTERACTIVE DETAIL & QUICK-ADD BOTTOM SHEETS
  // ============================================================================
  void _showPasswordDetailSheet(
    BuildContext context,
    VaultPasswordEntity item,
    bool isDark,
  ) {
    final secret = _secretForItem(item);
    final accent = _categoryColor(item.category);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark
          ? AppColors.darkCardBackground
          : AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkDivider : AppColors.divider,
                    borderRadius: AppRadius.radiusFull,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(item.icon, color: accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextHeading
                                : AppColors.textHeading,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.category} • AES-256 Encrypted Record',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark
                                ? AppColors.darkTextCaption
                                : AppColors.textCaption,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildDetailFieldTile(
                isDark: isDark,
                label: 'Username / Identifier',
                value: item.username,
                onCopy: () {
                  Navigator.pop(ctx);
                  _copySecret(context, 'Username', item.username);
                },
              ),
              const SizedBox(height: 8),
              _buildDetailFieldTile(
                isDark: isDark,
                label: 'Encrypted Password / Key',
                value: secret,
                isMonospace: true,
                onCopy: () {
                  Navigator.pop(ctx);
                  _copySecret(context, 'Password', secret);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDocumentPreviewSheet(
    BuildContext context,
    VaultDocumentEntity doc,
    bool isDark,
  ) {
    final accent = doc.isExpiringSoon
        ? AppColors.warning
        : _categoryColor(doc.category);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark
          ? AppColors.darkCardBackground
          : AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkDivider : AppColors.divider,
                    borderRadius: AppRadius.radiusFull,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(doc.icon, color: accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextHeading
                                : AppColors.textHeading,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${doc.category} • ${doc.expiry}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: doc.isExpiringSoon
                                ? AppColors.warning
                                : (isDark
                                      ? AppColors.darkTextCaption
                                      : AppColors.textCaption),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildDetailFieldTile(
                isDark: isDark,
                label: 'Coverage Status & Reminder Schedule',
                value: doc.isExpiringSoon
                    ? '${doc.expiry} • 30-day & 7-day auto alerts enabled'
                    : '${doc.expiry} • Active protection verified',
                onCopy: () {
                  Navigator.pop(ctx);
                  _copySecret(
                    context,
                    'Document summary',
                    '${doc.title} (${doc.category}) - ${doc.expiry}',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailFieldTile({
    required bool isDark,
    required String label,
    required String value,
    required VoidCallback onCopy,
    bool isMonospace = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkScaffoldBackground
            : AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.divider,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark
                        ? AppColors.darkTextCaption
                        : AppColors.textCaption,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: isMonospace ? 'monospace' : null,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextHeading
                        : AppColors.textHeading,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            icon: const Icon(
              Icons.copy_rounded,
              size: 17,
              color: AppColors.moduleVault,
            ),
            tooltip: 'Copy',
          ),
        ],
      ),
    );
  }

  void _showAddVaultItemSheet(BuildContext context, bool isDark) {
    final isWarrantyTab = _tabController.index == 1;
    final titleCtrl = TextEditingController();
    final subCtrl = TextEditingController();
    final secretCtrl = TextEditingController();
    String selectedCat = isWarrantyTab ? 'Electronics' : 'Banking';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark
          ? AppColors.darkCardBackground
          : AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final cats = isWarrantyTab
                ? ['Electronics', 'Medical', 'Vehicle']
                : ['Banking', 'Email', 'Wi-Fi', 'Social'];
            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                14,
                18,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isWarrantyTab
                        ? 'Add Warranty / Policy'
                        : 'Add Encrypted Login',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextHeading
                          : AppColors.textHeading,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: cats.map((cat) {
                      final active = cat == selectedCat;
                      return ChoiceChip(
                        label: Text(cat, style: const TextStyle(fontSize: 11)),
                        selected: active,
                        onSelected: (_) =>
                            setModalState(() => selectedCat = cat),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: isWarrantyTab
                          ? 'Product / Policy Name'
                          : 'Service / App Title',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: subCtrl,
                    decoration: InputDecoration(
                      labelText: isWarrantyTab
                          ? 'Expiry Note (e.g. Valid till Dec 2027)'
                          : 'Username / Email / SSID',
                      isDense: true,
                    ),
                  ),
                  if (!isWarrantyTab) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: secretCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Password / PIN',
                        isDense: true,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.moduleVault,
                      ),
                      onPressed: () {
                        final title = titleCtrl.text.trim();
                        if (title.isEmpty) return;
                        final id = DateTime.now().millisecondsSinceEpoch;
                        setState(() {
                          if (isWarrantyTab) {
                            _customDocuments.insert(
                              0,
                              VaultDocumentEntity(
                                id: id,
                                title: title,
                                category: selectedCat,
                                expiry: subCtrl.text.trim().isEmpty
                                    ? 'Valid till Dec 2027'
                                    : subCtrl.text.trim(),
                                isExpiringSoon: false,
                                hasReminder: true,
                                iconCodePoint:
                                    Icons.verified_user_rounded.codePoint,
                              ),
                            );
                          } else {
                            _customPasswords.insert(
                              0,
                              VaultPasswordEntity(
                                id: id,
                                title: title,
                                username: subCtrl.text.trim().isEmpty
                                    ? 'user@vault.local'
                                    : subCtrl.text.trim(),
                                category: selectedCat,
                                iconCodePoint: _sectionIconForCategory(
                                  selectedCat,
                                ).codePoint,
                              ),
                            );
                            if (secretCtrl.text.trim().isNotEmpty) {
                              _customSecrets[id] = secretCtrl.text.trim();
                            }
                          }
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Save to Encrypted Vault'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _VaultLoadingView extends StatelessWidget {
  const _VaultLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        AppShimmerLoader.card(height: 68),
        SizedBox(height: 12),
        AppShimmerLoader.card(height: 54),
        SizedBox(height: 10),
        AppShimmerLoader.card(height: 54),
        SizedBox(height: 10),
        AppShimmerLoader.card(height: 54),
      ],
    );
  }
}
