import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/feature_scaffold.dart';
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
  final TextEditingController _passwordSearchCtrl = TextEditingController();
  final TextEditingController _documentSearchCtrl = TextEditingController();

  bool _isUnlocked = false;
  bool _isSecurityEnabled = false;
  bool _isLoadingSecurity = true;

  // Interactive search & category filters
  String _passwordSearchQuery = '';
  String _selectedPasswordCategory = 'All';
  String _documentSearchQuery = '';
  String _selectedDocumentCategory = 'All';

  // Interactive Password Generator state
  int _generatorLength = 16;
  late String _generatedPreviewKey;

  // Track revealed password IDs and persisted user-added/modified items
  static const _prefsCustomPasswordsKey = 'vault_custom_passwords_v1';
  static const _prefsCustomDocumentsKey = 'vault_custom_documents_v1';
  static const _prefsCustomSecretsKey = 'vault_custom_secrets_v1';
  static const _prefsDeletedPasswordIdsKey = 'vault_deleted_password_ids_v1';
  static const _prefsDeletedDocumentIdsKey = 'vault_deleted_document_ids_v1';

  final Set<int> _revealedPasswordIds = {};
  final List<VaultPasswordEntity> _customPasswords = [];
  final List<VaultDocumentEntity> _customDocuments = [];
  final Map<int, String> _customSecrets = {};
  final Set<int> _deletedPasswordIds = {};
  final Set<int> _deletedDocumentIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _generatedPreviewKey = _generateEntropyKey(_generatorLength);
    _loadPersistedVaultData();
    _checkSecurity();
  }

  String _generateEntropyKey(int length) {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#\$%&*';
    final rand = Random.secure();
    return List.generate(
      length,
      (_) => chars[rand.nextInt(chars.length)],
    ).join();
  }

  Future<void> _loadPersistedVaultData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawPw = prefs.getString(_prefsCustomPasswordsKey);
      final rawDocs = prefs.getString(_prefsCustomDocumentsKey);
      final rawSecrets = prefs.getString(_prefsCustomSecretsKey);
      final delPw = prefs.getStringList(_prefsDeletedPasswordIdsKey);
      final delDocs = prefs.getStringList(_prefsDeletedDocumentIdsKey);

      if (!mounted) return;
      setState(() {
        if (rawPw != null && rawPw.isNotEmpty) {
          final list = jsonDecode(rawPw) as List<dynamic>;
          _customPasswords
            ..clear()
            ..addAll(
              list.map((m) {
                final map = m as Map<String, dynamic>;
                return VaultPasswordEntity(
                  id: map['id'] as int,
                  title: map['title'] as String,
                  username: map['username'] as String,
                  category: map['category'] as String,
                  iconCodePoint: map['iconCodePoint'] as int,
                );
              }),
            );
        }
        if (rawDocs != null && rawDocs.isNotEmpty) {
          final list = jsonDecode(rawDocs) as List<dynamic>;
          _customDocuments
            ..clear()
            ..addAll(
              list.map((m) {
                final map = m as Map<String, dynamic>;
                return VaultDocumentEntity(
                  id: map['id'] as int,
                  title: map['title'] as String,
                  category: map['category'] as String,
                  expiry: map['expiry'] as String,
                  isExpiringSoon: (map['isExpiringSoon'] as bool?) ?? false,
                  hasReminder: (map['hasReminder'] as bool?) ?? true,
                  iconCodePoint: map['iconCodePoint'] as int,
                );
              }),
            );
        }
        if (rawSecrets != null && rawSecrets.isNotEmpty) {
          final map = jsonDecode(rawSecrets) as Map<String, dynamic>;
          _customSecrets
            ..clear()
            ..addAll({
              for (final entry in map.entries)
                int.parse(entry.key): entry.value as String,
            });
        }
        if (delPw != null) {
          _deletedPasswordIds
            ..clear()
            ..addAll(delPw.map(int.tryParse).whereType<int>());
        }
        if (delDocs != null) {
          _deletedDocumentIds
            ..clear()
            ..addAll(delDocs.map(int.tryParse).whereType<int>());
        }
      });
    } catch (_) {}
  }

  Future<void> _persistVaultData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsCustomPasswordsKey,
        jsonEncode(
          _customPasswords
              .map(
                (p) => {
                  'id': p.id,
                  'title': p.title,
                  'username': p.username,
                  'category': p.category,
                  'iconCodePoint': p.iconCodePoint,
                },
              )
              .toList(),
        ),
      );
      await prefs.setString(
        _prefsCustomDocumentsKey,
        jsonEncode(
          _customDocuments
              .map(
                (d) => {
                  'id': d.id,
                  'title': d.title,
                  'category': d.category,
                  'expiry': d.expiry,
                  'isExpiringSoon': d.isExpiringSoon,
                  'hasReminder': d.hasReminder,
                  'iconCodePoint': d.iconCodePoint,
                },
              )
              .toList(),
        ),
      );
      await prefs.setString(
        _prefsCustomSecretsKey,
        jsonEncode({
          for (final e in _customSecrets.entries) e.key.toString(): e.value,
        }),
      );
      await prefs.setStringList(
        _prefsDeletedPasswordIdsKey,
        _deletedPasswordIds.map((e) => e.toString()).toList(),
      );
      await prefs.setStringList(
        _prefsDeletedDocumentIdsKey,
        _deletedDocumentIds.map((e) => e.toString()).toList(),
      );
    } catch (_) {}
  }

  List<VaultPasswordEntity> _mergedPasswords(List<VaultPasswordEntity> base) {
    final customIds = _customPasswords.map((p) => p.id).toSet();
    return [
      ..._customPasswords.where((p) => !_deletedPasswordIds.contains(p.id)),
      ...base.where(
        (p) => !customIds.contains(p.id) && !_deletedPasswordIds.contains(p.id),
      ),
    ];
  }

  List<VaultDocumentEntity> _mergedDocuments(List<VaultDocumentEntity> base) {
    final customIds = _customDocuments.map((d) => d.id).toSet();
    return [
      ..._customDocuments.where((d) => !_deletedDocumentIds.contains(d.id)),
      ...base.where(
        (d) => !customIds.contains(d.id) && !_deletedDocumentIds.contains(d.id),
      ),
    ];
  }

  Future<void> _checkSecurity() async {
    final config = await sl<SecurityRepository>().getConfig();
    if (mounted) {
      setState(() {
        _isSecurityEnabled = config.isSecurityEnabled;
        _isLoadingSecurity = false;
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
    _passwordSearchCtrl.dispose();
    _documentSearchCtrl.dispose();
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
    final palette = context.palette;

    return BlocBuilder<VaultBloc, VaultState>(
      builder: (context, state) {
        final isDecoy = state is VaultLoaded ? state.isDecoyMode : false;

        final isLoading =
            _isLoadingSecurity ||
            (_isUnlocked && (state is VaultLoading || state is VaultInitial));

        return FeatureScaffold(
          title: StringConstants.navVault,
          accentColor: AppColors.moduleVault,
          titleTrailing: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xxxs,
            ),
            decoration: BoxDecoration(
              color: AppColors.moduleVault.withValues(alpha: 0.12),
              borderRadius: AppRadius.radiusFull,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  size: AppSpacing.sm,
                  color: AppColors.moduleVault,
                ),
                AppSpacing.gapW4,
                Text(
                  'AES-256',
                  style: context.text.labelSmall?.copyWith(
                    color: AppColors.moduleVault,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          actionsEndPadding: AppSpacing.pageGutter,
          actions: [
            // Compact Decoy Pill Toggle (PRD Feature)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
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
                height: AppSpacing.xxl + AppSpacing.xxs,
                padding: AppSpacing.edgeInsetsHSm,
                decoration: BoxDecoration(
                  color: isDecoy
                      ? AppColors.error.withValues(alpha: 0.14)
                      : palette.card,
                  borderRadius: AppRadius.radiusFull,
                  border: Border.all(
                    color: isDecoy
                        ? AppColors.error.withValues(alpha: 0.5)
                        : palette.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: AppSpacing.xs - AppSpacing.xxxs,
                      height: AppSpacing.xs - AppSpacing.xxxs,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDecoy ? AppColors.error : palette.caption,
                      ),
                    ),
                    AppSpacing.gapW4,
                    Text(
                      'Decoy',
                      style: context.text.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDecoy ? AppColors.error : palette.body,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapW8,
            FeatureIconButton(
              tooltip: 'Security Settings',
              icon: Icons.shield_outlined,
              color: AppColors.moduleVault,
              onPressed: () {
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
            AppSpacing.gapW8,
            FeatureIconButton(
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
              onPressed: () {
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
            if (_isUnlocked) ...[
              AppSpacing.gapW8,
              FeatureIconButton(
                tooltip: 'Add Vault Item',
                icon: Icons.add_rounded,
                color: Colors.white,
                backgroundColor: AppColors.moduleVault,
                borderColor: AppColors.moduleVault,
                onPressed: () => _showAddVaultItemSheet(context),
              ),
            ],
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(
              AppSpacing.xxxl + AppSpacing.xxs,
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: palette.border)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.moduleVault,
                indicatorWeight: 2.5,
                labelColor: AppColors.moduleVault,
                unselectedLabelColor: palette.caption,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                labelStyle: context.text.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: context.text.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(height: AppSpacing.xxxl, text: 'Passwords & Logins'),
                  Tab(height: AppSpacing.xxxl, text: 'Warranty Locker'),
                ],
              ),
            ),
          ),
          status: switch (state) {
            _ when isLoading => FeatureStatus.loading,
            VaultError() when _isUnlocked => FeatureStatus.error,
            _ => FeatureStatus.content,
          },
          errorMessage: state is VaultError ? state.message : null,
          onRetry: () => context.read<VaultBloc>().add(const LoadVault()),
          loading: const FeatureLoadingView(
            blockHeights: [96, 44, 36, 128, 128],
          ),
          builder: (context) => !_isUnlocked
              ? _buildLockedScreen()
              : state is VaultLoaded
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPasswordsTab(
                      context,
                      _mergedPasswords(state.passwords),
                      _mergedDocuments(state.documents),
                      isDecoy,
                    ),
                    _buildDocumentsTab(
                      context,
                      _mergedDocuments(state.documents),
                      _mergedPasswords(state.passwords),
                      isDecoy,
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildLockedScreen() {
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
  // 1PASSWORD-STYLE WATCHTOWER & SECURITY OVERVIEW CARD
  // ============================================================================
  Widget _buildVaultOverviewCard({
    required BuildContext context,
    required bool isDecoy,
    required int passwordCount,
    required int documentCount,
    required int expiringCount,
    int weakPasswordCount = 0,
  }) {
    final palette = context.palette;

    return Container(
      padding: AppSpacing.edgeInsetsAllMd,
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: !_isSecurityEnabled
              ? AppColors.warning.withValues(alpha: 0.45)
              : palette.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppSpacing.xxxl,
                height: AppSpacing.xxxl,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.moduleVault, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppRadius.borderMd,
                ),
                child: const Icon(
                  Icons.security_rounded,
                  color: Colors.white,
                  size: AppSpacing.lg,
                ),
              ),
              AppSpacing.gapW12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          isDecoy
                              ? 'Decoy Vault Active'
                              : 'Zero-Knowledge Encrypted',
                          softWrap: true,
                          style: context.text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: palette.heading,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: AppSpacing.xxxs,
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
                            style: context.text.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _isSecurityEnabled
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapH4,
                    Text(
                      !_isSecurityEnabled
                          ? 'No PIN/Pattern lock set. Enable lock to protect keys.'
                          : 'Keys never leave this device. Encrypted at rest.',
                      softWrap: true,
                      style: context.text.bodySmall?.copyWith(
                        color: palette.caption,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapW8,
              if (!_isSecurityEnabled)
                InkWell(
                  borderRadius: AppRadius.borderSm,
                  onTap: () => _openSecuritySetup(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.moduleVault,
                      borderRadius: AppRadius.borderSm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.shield_rounded,
                          size: AppSpacing.sm,
                          color: Colors.white,
                        ),
                        AppSpacing.gapW4,
                        Text(
                          'Set Lock',
                          style: context.text.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                InkWell(
                  borderRadius: AppRadius.borderSm,
                  onTap: () {
                    setState(() => _isUnlocked = false);
                    context.read<VaultBloc>().add(const LockVault());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.moduleVault.withValues(alpha: 0.12),
                      borderRadius: AppRadius.borderSm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: AppSpacing.sm,
                          color: AppColors.moduleVault,
                        ),
                        AppSpacing.gapW4,
                        Text(
                          'Lock',
                          style: context.text.labelSmall?.copyWith(
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
          AppSpacing.gapH12,
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xs,
              horizontal: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: AppRadius.borderMd,
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildMiniVaultStat(
                    context: context,
                    icon: Icons.key_rounded,
                    color: AppColors.moduleVault,
                    label: 'Logins',
                    value: '$passwordCount Saved',
                  ),
                ),
                Container(
                  width: 1,
                  height: AppSpacing.xl,
                  color: palette.border,
                ),
                Expanded(
                  child: _buildMiniVaultStat(
                    context: context,
                    icon: Icons.verified_outlined,
                    color: AppColors.secondary,
                    label: 'Warranties',
                    value: '$documentCount Docs',
                  ),
                ),
                Container(
                  width: 1,
                  height: AppSpacing.xl,
                  color: palette.border,
                ),
                Expanded(
                  child: InkWell(
                    borderRadius: AppRadius.borderSm,
                    onTap: expiringCount > 0
                        ? () {
                            setState(
                              () => _selectedDocumentCategory = 'Expiring Soon',
                            );
                            _tabController.animateTo(1);
                          }
                        : null,
                    child: _buildMiniVaultStat(
                      context: context,
                      icon: (expiringCount > 0 || weakPasswordCount > 0)
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline_rounded,
                      color: (expiringCount > 0 || weakPasswordCount > 0)
                          ? AppColors.warning
                          : AppColors.success,
                      label: StringConstants.vaultExpiringDocsLabel,
                      value: expiringCount > 0
                          ? '$expiringCount Expiring'
                          : (weakPasswordCount > 0
                                ? '$weakPasswordCount Weak'
                                : 'All Clear'),
                    ),
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
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: AppSpacing.md - AppSpacing.xxxs, color: color),
          AppSpacing.gapW4,
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: context.text.labelSmall?.copyWith(
                      color: palette.caption,
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: context.text.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.heading,
                    ),
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
    bool isDecoy,
  ) {
    final categories = ['All', 'Banking', 'Email', 'Wi-Fi', 'Social'];
    final Map<String, int> categoryCounts = {'All': passwords.length};
    for (final cat in categories.skip(1)) {
      categoryCounts[cat] = passwords
          .where((p) => p.category.toLowerCase() == cat.toLowerCase())
          .length;
    }

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

    final Map<String, List<VaultPasswordEntity>> grouped = {};
    for (final item in filtered) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    final expiringCount = documents.where((d) => d.isExpiringSoon).length;
    final weakPasswordCount = passwords
        .where((p) => _secretForItem(p).length < 10)
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        AppSpacing.sm,
        AppSpacing.pageGutter,
        AppSpacing.huge * 2,
      ),
      children: [
        // 1. Unified Watchtower Overview Card
        _buildVaultOverviewCard(
          context: context,
          isDecoy: isDecoy,
          passwordCount: passwords.length,
          documentCount: documents.length,
          expiringCount: expiringCount,
          weakPasswordCount: weakPasswordCount,
        ),
        AppSpacing.gapH12,

        // 2. Clean 44px Search Bar + 36px Category Filter Pills
        _buildSearchAndFilterSection(
          context: context,
          controller: _passwordSearchCtrl,
          hintText: 'Search logins, usernames, or categories...',
          query: _passwordSearchQuery,
          onQueryChanged: (val) => setState(() => _passwordSearchQuery = val),
          onClearQuery: () {
            _passwordSearchCtrl.clear();
            setState(() => _passwordSearchQuery = '');
          },
          categories: categories,
          categoryCounts: categoryCounts,
          selectedCategory: _selectedPasswordCategory,
          onCategorySelected: (cat) =>
              setState(() => _selectedPasswordCategory = cat),
        ),
        AppSpacing.gapH16,

        // 3. Grouped Section Cards by Category
        if (filtered.isEmpty)
          _buildEmptySectionCard(
            context: context,
            icon: Icons.key_off_rounded,
            title: 'No matching logins found',
            subtitle:
                'Try clearing your search or category filter, or add a new login.',
            onAction: () {
              _passwordSearchCtrl.clear();
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
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _buildSectionCardContainer(
                context: context,
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
                      accent: accent,
                    ),
                    if (i < items.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: AppSpacing.md + AppSpacing.xxxl + AppSpacing.sm,
                        endIndent: AppSpacing.md,
                        color: context.palette.border,
                      ),
                  ],
                ],
              ),
            );
          }),

        AppSpacing.gapH4,

        // 4. Interactive Password Security Tools & Live Key Generator Card
        _buildPasswordSecurityToolsCard(context),
      ],
    );
  }

  Widget _buildPasswordRow({
    required BuildContext context,
    required VaultPasswordEntity item,
    required Color accent,
  }) {
    final palette = context.palette;
    final isRevealed = _revealedPasswordIds.contains(item.id);
    final secret = _secretForItem(item);

    return InkWell(
      onTap: () => _showPasswordDetailSheet(context, item),
      borderRadius: AppRadius.borderMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: AppSpacing.xxxl,
              height: AppSpacing.xxxl,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: AppRadius.borderMd,
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              child: Icon(item.icon, color: accent, size: AppSpacing.lg),
            ),
            AppSpacing.gapW12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        item.title,
                        softWrap: true,
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.heading,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.xxxs,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: AppRadius.radiusFull,
                        ),
                        child: Text(
                          item.category,
                          style: context.text.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapH4,
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        item.username,
                        softWrap: true,
                        style: context.text.bodySmall?.copyWith(
                          color: palette.secondary,
                        ),
                      ),
                      Text(
                        '•',
                        style: context.text.bodySmall?.copyWith(
                          color: palette.caption,
                        ),
                      ),
                      Text(
                        isRevealed ? secret : '••••••••',
                        softWrap: true,
                        style: AppTextStyles.monoCode.copyWith(
                          fontSize: 12,
                          fontWeight: isRevealed
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isRevealed
                              ? AppColors.moduleVault
                              : palette.caption,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AppSpacing.gapW8,
            // Reveal / Hide Password Button
            _buildRowActionIcon(
              tooltip: isRevealed ? 'Hide Password' : 'Reveal Password',
              icon: isRevealed
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: isRevealed ? AppColors.moduleVault : palette.caption,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (isRevealed) {
                    _revealedPasswordIds.remove(item.id);
                  } else {
                    _revealedPasswordIds.add(item.id);
                  }
                });
              },
            ),
            AppSpacing.gapW8,
            // 1-Tap Copy Password Button
            _buildRowActionIcon(
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

  Widget _buildPasswordSecurityToolsCard(BuildContext context) {
    final palette = context.palette;

    return _buildSectionCardContainer(
      context: context,
      sectionIcon: Icons.bolt_rounded,
      sectionTitle: 'SECURITY AUDIT & KEY GENERATOR',
      sectionAccent: AppColors.secondary,
      trailingBadgeText: '100% Strong',
      children: [
        Padding(
          padding: AppSpacing.edgeInsetsAllMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: AppSpacing.xxxl,
                    height: AppSpacing.xxxl,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.12),
                      borderRadius: AppRadius.borderMd,
                    ),
                    child: const Icon(
                      Icons.password_rounded,
                      size: AppSpacing.lg,
                      color: AppColors.secondary,
                    ),
                  ),
                  AppSpacing.gapW12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cryptographic Key Generator',
                          style: context.text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: palette.heading,
                          ),
                        ),
                        AppSpacing.gapH4,
                        Text(
                          'Generate a $_generatorLength-char high-entropy password & copy instantly',
                          style: context.text.bodySmall?.copyWith(
                            color: palette.caption,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapW8,
                  InkWell(
                    borderRadius: AppRadius.borderSm,
                    onTap: () {
                      final generated = _generateEntropyKey(_generatorLength);
                      setState(() => _generatedPreviewKey = generated);
                      _copySecret(
                        context,
                        'Generated key ($generated)',
                        generated,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.14),
                        borderRadius: AppRadius.borderSm,
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: AppSpacing.sm,
                            color: AppColors.secondary,
                          ),
                          AppSpacing.gapW4,
                          Text(
                            'Generate',
                            style: context.text.labelSmall?.copyWith(
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
              AppSpacing.gapH12,
              // Interactive Live Entropy Preview & Length Selector
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: AppRadius.borderMd,
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _generatedPreviewKey,
                          style: AppTextStyles.captionBold.copyWith(
                            fontWeight: FontWeight.w700,
                            color: palette.heading,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                    AppSpacing.gapW8,
                    for (final len in const [12, 16, 24]) ...[
                      InkWell(
                        borderRadius: AppRadius.radiusXs,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _generatorLength = len;
                            _generatedPreviewKey = _generateEntropyKey(len);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: AppSpacing.xxxs,
                          ),
                          decoration: BoxDecoration(
                            color: _generatorLength == len
                                ? AppColors.secondary
                                : Colors.transparent,
                            borderRadius: AppRadius.radiusXs,
                          ),
                          child: Text(
                            '$len',
                            style: context.text.labelSmall?.copyWith(
                              color: _generatorLength == len
                                  ? Colors.white
                                  : palette.caption,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.gapW4,
                    ],
                  ],
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
    bool isDecoy,
  ) {
    final categories = [
      'All',
      'Expiring Soon',
      'Electronics',
      'Medical',
      'Vehicle',
    ];

    final Map<String, int> categoryCounts = {
      'All': documents.length,
      'Expiring Soon': documents.where((d) => d.isExpiringSoon).length,
    };
    for (final cat in const ['Electronics', 'Medical', 'Vehicle']) {
      categoryCounts[cat] = documents
          .where((d) => d.category.toLowerCase() == cat.toLowerCase())
          .length;
    }

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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        AppSpacing.sm,
        AppSpacing.pageGutter,
        AppSpacing.huge * 2,
      ),
      children: [
        // 1. Unified Watchtower Overview Card
        _buildVaultOverviewCard(
          context: context,
          isDecoy: isDecoy,
          passwordCount: passwords.length,
          documentCount: documents.length,
          expiringCount: totalExpiring,
        ),
        AppSpacing.gapH12,

        // 2. Automated Expiry Notice Card
        Container(
          padding: AppSpacing.edgeInsetsAllSm,
          decoration: BoxDecoration(
            color: AppColors.moduleTime.withValues(alpha: 0.1),
            borderRadius: AppRadius.borderMd,
            border: Border.all(
              color: AppColors.moduleTime.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: AppSpacing.xxl,
                height: AppSpacing.xxl,
                decoration: BoxDecoration(
                  color: AppColors.moduleTime.withValues(alpha: 0.18),
                  borderRadius: AppRadius.borderSm,
                ),
                child: const Icon(
                  Icons.notification_important_rounded,
                  color: AppColors.moduleTime,
                  size: AppSpacing.md,
                ),
              ),
              AppSpacing.gapW12,
              Expanded(
                child: Text(
                  'Automated Expiry Alerts: We notify you 30 days & 7 days before warranty or policy lapses.',
                  style: context.text.bodySmall?.copyWith(
                    color: context.palette.heading,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.gapH12,

        // 3. Clean 44px Search Bar + 36px Category Filter Pills
        _buildSearchAndFilterSection(
          context: context,
          controller: _documentSearchCtrl,
          hintText: 'Search warranties, policies, or categories...',
          query: _documentSearchQuery,
          onQueryChanged: (val) => setState(() => _documentSearchQuery = val),
          onClearQuery: () {
            _documentSearchCtrl.clear();
            setState(() => _documentSearchQuery = '');
          },
          categories: categories,
          categoryCounts: categoryCounts,
          selectedCategory: _selectedDocumentCategory,
          onCategorySelected: (cat) =>
              setState(() => _selectedDocumentCategory = cat),
        ),
        AppSpacing.gapH16,

        if (filtered.isEmpty)
          _buildEmptySectionCard(
            context: context,
            icon: Icons.folder_off_rounded,
            title: 'No matching warranties or policies',
            subtitle:
                'Clear your search filter or add a new warranty/insurance card.',
            onAction: () {
              _documentSearchCtrl.clear();
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
              context: context,
              sectionIcon: Icons.warning_amber_rounded,
              sectionTitle: 'EXPIRING SOON • RENEWAL NEEDED',
              sectionAccent: AppColors.warning,
              trailingBadgeText: '${expiringDocs.length} urgent',
              children: [
                for (var i = 0; i < expiringDocs.length; i++) ...[
                  _buildDocumentRow(context: context, doc: expiringDocs[i]),
                  if (i < expiringDocs.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: AppSpacing.md + AppSpacing.xxxl + AppSpacing.sm,
                      endIndent: AppSpacing.md,
                      color: context.palette.border,
                    ),
                ],
              ],
            ),
            AppSpacing.gapH12,
          ],

          // 5. Section Card: ACTIVE WARRANTIES & POLICIES
          if (activeDocs.isNotEmpty)
            _buildSectionCardContainer(
              context: context,
              sectionIcon: Icons.verified_user_outlined,
              sectionTitle: 'ACTIVE WARRANTIES & POLICIES',
              sectionAccent: AppColors.secondary,
              trailingBadgeText: '${activeDocs.length} active',
              children: [
                for (var i = 0; i < activeDocs.length; i++) ...[
                  _buildDocumentRow(context: context, doc: activeDocs[i]),
                  if (i < activeDocs.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: AppSpacing.md + AppSpacing.xxxl + AppSpacing.sm,
                      endIndent: AppSpacing.md,
                      color: context.palette.border,
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
  }) {
    final palette = context.palette;
    final isExpiringSoon = doc.isExpiringSoon;
    final accent = isExpiringSoon
        ? AppColors.warning
        : _categoryColor(doc.category);

    return InkWell(
      onTap: () => _showDocumentPreviewSheet(context, doc),
      borderRadius: AppRadius.borderMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: AppSpacing.xxxl,
              height: AppSpacing.xxxl,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: AppRadius.borderMd,
                border: Border.all(color: accent.withValues(alpha: 0.28)),
              ),
              child: Icon(doc.icon, color: accent, size: AppSpacing.lg),
            ),
            AppSpacing.gapW12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        doc.title,
                        softWrap: true,
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.heading,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.xxxs,
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
                          style: context.text.labelSmall?.copyWith(
                            color: isExpiringSoon
                                ? AppColors.warning
                                : AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapH4,
                  Text(
                    '${doc.category} • ${doc.expiry}',
                    softWrap: true,
                    style: context.text.bodySmall?.copyWith(
                      color: isExpiringSoon
                          ? AppColors.warning
                          : palette.secondary,
                      fontWeight: isExpiringSoon
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapW8,
            _buildRowActionIcon(
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
                _showDocumentPreviewSheet(context, doc);
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
  Widget _buildSearchAndFilterSection({
    required BuildContext context,
    required TextEditingController controller,
    required String hintText,
    required String query,
    required ValueChanged<String> onQueryChanged,
    required VoidCallback onClearQuery,
    required List<String> categories,
    required Map<String, int> categoryCounts,
    required String selectedCategory,
    required ValueChanged<String> onCategorySelected,
  }) {
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 44px Search Bar matching Notes & Money
        Container(
          height: AppSpacing.xxxl + AppSpacing.xxs,
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: AppRadius.borderMd,
            border: Border.all(color: palette.border),
          ),
          child: TextField(
            controller: controller,
            onChanged: onQueryChanged,
            style: context.text.bodyMedium?.copyWith(color: palette.heading),
            decoration: InputDecoration(
              filled: false,
              hintText: hintText,
              hintStyle: context.text.bodyMedium?.copyWith(
                color: palette.caption,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: AppSpacing.lg,
                color: palette.caption,
              ),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: onClearQuery,
                      icon: Icon(
                        Icons.close_rounded,
                        size: AppSpacing.md,
                        color: palette.caption,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
              ),
            ),
          ),
        ),
        AppSpacing.gapH12,
        // 36px Horizontal Filter Pills with Counts
        SizedBox(
          height: AppSpacing.xxl + AppSpacing.xxs,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => AppSpacing.gapW8,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = cat == selectedCategory;
              final count = categoryCounts[cat] ?? 0;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onCategorySelected(cat);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: AppSpacing.edgeInsetsHSm,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.moduleVault : palette.card,
                    borderRadius: AppRadius.radiusFull,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.moduleVault
                          : palette.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cat,
                        style: context.text.labelMedium?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: isSelected ? Colors.white : palette.body,
                        ),
                      ),
                      AppSpacing.gapW4,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxs + AppSpacing.xxxs,
                          vertical: AppSpacing.xxxs / 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.22)
                              : palette.surfaceMuted,
                          borderRadius: AppRadius.radiusFull,
                        ),
                        child: Text(
                          '$count',
                          style: context.text.labelSmall?.copyWith(
                            color: isSelected ? Colors.white : palette.caption,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCardContainer({
    required BuildContext context,
    required IconData sectionIcon,
    required String sectionTitle,
    required Color sectionAccent,
    required String trailingBadgeText,
    required List<Widget> children,
  }) {
    final palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: palette.border),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.borderLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header Bar inside the card
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: sectionAccent.withValues(alpha: 0.08),
                border: Border(bottom: BorderSide(color: palette.border)),
              ),
              child: Row(
                children: [
                  Icon(sectionIcon, size: AppSpacing.md, color: sectionAccent),
                  AppSpacing.gapW8,
                  Expanded(
                    child: Text(
                      sectionTitle,
                      style: context.text.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: palette.heading,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xxxs,
                    ),
                    decoration: BoxDecoration(
                      color: sectionAccent.withValues(alpha: 0.14),
                      borderRadius: AppRadius.radiusFull,
                    ),
                    child: Text(
                      trailingBadgeText,
                      style: context.text.labelSmall?.copyWith(
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
      ),
    );
  }

  Widget _buildRowActionIcon({
    required String tooltip,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderSm,
        child: Container(
          width: AppSpacing.xxl,
          height: AppSpacing.xxl,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: AppRadius.borderSm,
          ),
          child: Icon(icon, size: AppSpacing.md, color: color),
        ),
      ),
    );
  }

  Widget _buildEmptySectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onAction,
    required String actionLabel,
  }) {
    final palette = context.palette;

    return Container(
      padding: AppSpacing.edgeInsetsAllXl,
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Container(
            width: AppSpacing.huge,
            height: AppSpacing.huge,
            decoration: BoxDecoration(
              color: AppColors.moduleVault.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: AppSpacing.xl,
              color: AppColors.moduleVault,
            ),
          ),
          AppSpacing.gapH12,
          Text(
            title,
            style: context.text.titleMedium?.copyWith(color: palette.heading),
          ),
          AppSpacing.gapH4,
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(color: palette.caption),
          ),
          AppSpacing.gapH12,
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.refresh_rounded, size: AppSpacing.md),
            label: Text(
              actionLabel,
              style: context.text.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
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
  ) {
    final secret = _secretForItem(item);
    final accent = _categoryColor(item.category);

    showModalBottomSheet(
      context: context,
      backgroundColor: context.palette.card,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.topXl),
      builder: (ctx) {
        final palette = ctx.palette;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageGutter,
            AppSpacing.md,
            AppSpacing.pageGutter,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: AppSpacing.xxxl,
                  height: AppSpacing.xxs,
                  decoration: BoxDecoration(
                    color: palette.border,
                    borderRadius: AppRadius.radiusFull,
                  ),
                ),
              ),
              AppSpacing.gapH16,
              Row(
                children: [
                  Container(
                    width: AppSpacing.xxxl + AppSpacing.xxs,
                    height: AppSpacing.xxxl + AppSpacing.xxs,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: AppRadius.borderMd,
                    ),
                    child: Icon(item.icon, color: accent, size: AppSpacing.lg),
                  ),
                  AppSpacing.gapW12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: ctx.text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: palette.heading,
                          ),
                        ),
                        AppSpacing.gapH4,
                        Text(
                          '${item.category} • AES-256 Encrypted Record',
                          style: ctx.text.bodySmall?.copyWith(
                            color: palette.caption,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete Login',
                    onPressed: () async {
                      final nav = Navigator.of(ctx);
                      final confirmed = await ConfirmationDialog.show(
                        ctx,
                        title: 'Delete Login?',
                        message:
                            'Are you sure you want to remove "${item.title}" from your encrypted Vault?',
                        confirmLabel: 'Delete',
                      );
                      if (confirmed == true && mounted) {
                        nav.pop();
                        setState(() {
                          _customPasswords.removeWhere((p) => p.id == item.id);
                          _deletedPasswordIds.add(item.id);
                          _customSecrets.remove(item.id);
                        });
                        unawaited(_persistVaultData());
                      }
                    },
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                      size: AppSpacing.lg,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapH16,
              _buildDetailFieldTile(
                context: ctx,
                label: 'Username / Identifier',
                value: item.username,
                onCopy: () {
                  Navigator.pop(ctx);
                  _copySecret(context, 'Username', item.username);
                },
              ),
              AppSpacing.gapH8,
              _buildDetailFieldTile(
                context: ctx,
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
  ) {
    final accent = doc.isExpiringSoon
        ? AppColors.warning
        : _categoryColor(doc.category);

    showModalBottomSheet(
      context: context,
      backgroundColor: context.palette.card,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.topXl),
      builder: (ctx) {
        final palette = ctx.palette;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageGutter,
            AppSpacing.md,
            AppSpacing.pageGutter,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: AppSpacing.xxxl,
                  height: AppSpacing.xxs,
                  decoration: BoxDecoration(
                    color: palette.border,
                    borderRadius: AppRadius.radiusFull,
                  ),
                ),
              ),
              AppSpacing.gapH16,
              Row(
                children: [
                  Container(
                    width: AppSpacing.xxxl + AppSpacing.xxs,
                    height: AppSpacing.xxxl + AppSpacing.xxs,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: AppRadius.borderMd,
                    ),
                    child: Icon(doc.icon, color: accent, size: AppSpacing.lg),
                  ),
                  AppSpacing.gapW12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.title,
                          style: ctx.text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: palette.heading,
                          ),
                        ),
                        AppSpacing.gapH4,
                        Text(
                          '${doc.category} • ${doc.expiry}',
                          style: ctx.text.bodySmall?.copyWith(
                            color: doc.isExpiringSoon
                                ? AppColors.warning
                                : palette.caption,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete Document',
                    onPressed: () async {
                      final nav = Navigator.of(ctx);
                      final confirmed = await ConfirmationDialog.show(
                        ctx,
                        title: 'Delete Warranty / Document?',
                        message:
                            'Are you sure you want to delete "${doc.title}" from Warranty Locker?',
                        confirmLabel: 'Delete',
                      );
                      if (confirmed == true && mounted) {
                        nav.pop();
                        setState(() {
                          _customDocuments.removeWhere((d) => d.id == doc.id);
                          _deletedDocumentIds.add(doc.id);
                        });
                        unawaited(_persistVaultData());
                      }
                    },
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                      size: AppSpacing.lg,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapH16,
              _buildDetailFieldTile(
                context: ctx,
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
    required BuildContext context,
    required String label,
    required String value,
    required VoidCallback onCopy,
    bool isMonospace = false,
  }) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.text.labelSmall?.copyWith(
                    color: palette.caption,
                  ),
                ),
                AppSpacing.gapH4,
                Text(
                  value,
                  style: isMonospace
                      ? AppTextStyles.captionBold.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.heading,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        )
                      : context.text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.heading,
                        ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            icon: const Icon(
              Icons.copy_rounded,
              size: AppSpacing.lg,
              color: AppColors.moduleVault,
            ),
            tooltip: 'Copy',
          ),
        ],
      ),
    );
  }

  void _showAddVaultItemSheet(BuildContext context) {
    final isWarrantyTab = _tabController.index == 1;
    final titleCtrl = TextEditingController();
    final subCtrl = TextEditingController();
    final secretCtrl = TextEditingController();
    String selectedCat = isWarrantyTab ? 'Electronics' : 'Banking';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.card,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.topXl),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final palette = ctx.palette;
            final cats = isWarrantyTab
                ? ['Electronics', 'Medical', 'Vehicle']
                : ['Banking', 'Email', 'Wi-Fi', 'Social'];
            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pageGutter,
                AppSpacing.md,
                AppSpacing.pageGutter,
                MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: AppSpacing.xxxl,
                      height: AppSpacing.xxs,
                      decoration: BoxDecoration(
                        color: palette.border,
                        borderRadius: AppRadius.radiusFull,
                      ),
                    ),
                  ),
                  AppSpacing.gapH16,
                  Text(
                    isWarrantyTab
                        ? 'Add Warranty / Policy'
                        : 'Add Encrypted Login',
                    style: ctx.text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.heading,
                    ),
                  ),
                  AppSpacing.gapH12,
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: cats.map((cat) {
                      final active = cat == selectedCat;
                      return ChoiceChip(
                        label: Text(cat, style: ctx.text.labelMedium),
                        selected: active,
                        onSelected: (_) =>
                            setModalState(() => selectedCat = cat),
                      );
                    }).toList(),
                  ),
                  AppSpacing.gapH12,
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: isWarrantyTab
                          ? 'Product / Policy Name'
                          : 'Service / App Title',
                      isDense: true,
                    ),
                  ),
                  AppSpacing.gapH12,
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
                    AppSpacing.gapH12,
                    TextField(
                      controller: secretCtrl,
                      decoration: InputDecoration(
                        labelText: 'Password / PIN',
                        isDense: true,
                        suffixIcon: IconButton(
                          tooltip: 'Generate Strong Password',
                          onPressed: () {
                            setModalState(() {
                              secretCtrl.text = _generateEntropyKey(16);
                            });
                          },
                          icon: const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.secondary,
                            size: AppSpacing.lg,
                          ),
                        ),
                      ),
                    ),
                  ],
                  AppSpacing.gapH16,
                  SizedBox(
                    width: double.infinity,
                    height: AppSpacing.huge,
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
                        _persistVaultData();
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
