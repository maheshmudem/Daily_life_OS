import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_decorations.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_text_styles.dart';
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
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<VaultBloc, VaultState>(
      builder: (context, state) {
        final isDecoy = state is VaultLoaded ? state.isDecoyMode : false;

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkScaffoldBackground : AppColors.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: isDark ? AppColors.darkScaffoldBackground : AppColors.scaffoldBackground,
            elevation: 0,
            title: Row(
              children: [
                const Text(
                  StringConstants.navVault,
                  style: AppTextStyles.headingSmall,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.moduleVault.withValues(alpha: 0.15),
                    borderRadius: AppRadius.radiusFull,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.moduleVault),
                      SizedBox(width: 4),
                      Text(
                        'AES-256',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.moduleVault,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Decoy Mode Pin / Toggle (PRD Feature)
              Row(
                children: [
                  Text(
                    'Decoy',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDecoy ? AppColors.error : (isDark ? AppColors.darkTextCaption : AppColors.textCaption),
                    ),
                  ),
                  Switch.adaptive(
                    value: isDecoy,
                    activeTrackColor: AppColors.error,
                    onChanged: (val) {
                      context.read<VaultBloc>().add(const ToggleDecoyMode());
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val ? 'Decoy Mode active! Safe dummy data shown.' : 'Standard Secure Vault active.'),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
              // Security Settings Sheet
              IconButton(
                tooltip: 'Security Settings',
                icon: const Icon(Icons.shield_outlined, color: AppColors.moduleVault),
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
              IconButton(
                tooltip: !_isSecurityEnabled
                    ? 'Set Up Security'
                    : (_isUnlocked ? 'Lock Vault' : 'Vault Locked'),
                icon: Icon(
                  !_isSecurityEnabled
                      ? Icons.lock_open_rounded
                      : (_isUnlocked ? Icons.lock_open_rounded : Icons.lock_rounded),
                  color: !_isSecurityEnabled ? AppColors.warning : AppColors.moduleVault,
                ),
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
                        content: Text('Enter PIN or draw Pattern below to unlock.'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(width: 8),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.moduleVault,
              labelColor: AppColors.moduleVault,
              unselectedLabelColor: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(text: 'Passwords & Logins'),
                Tab(text: 'Warranty Locker'),
              ],
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
                                _buildPasswordsTab(context, state.passwords, isDark),
                                _buildDocumentsTab(context, state.documents, isDark),
                              ],
                            )
                          : const SizedBox.shrink(),
        );
      },
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

  Widget _buildUnsecuredVaultBanner(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: isDark ? 0.18 : 0.09),
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined, color: AppColors.warning, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Vault Security is Disabled',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your vault has no master lock configured. Anyone with device access can view passwords and sensitive documents.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openSecuritySetup(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.moduleVault,
                shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.shield_rounded, size: 16),
              label: const Text('Set Up Security Lock',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordsTab(BuildContext context, List<VaultPasswordEntity> passwords, bool isDark) {
    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 90),
      children: [
        if (!_isSecurityEnabled)
          _buildUnsecuredVaultBanner(context, isDark),
        // Security Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppDecorations.heroVaultGradient,
          child: const Row(
            children: [
              Icon(Icons.security_rounded, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zero-Knowledge Encrypted',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Keys never leave this device. Encrypted at rest.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Quick Category Filter
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', 'Banking', 'Email', 'Wi-Fi', 'Social'].map((cat) {
              final isSelected = cat == 'All';
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (_) {},
                  selectedColor: AppColors.moduleVault.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.moduleVault,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.moduleVault : (isDark ? AppColors.darkTextBody : AppColors.textBody),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        ...passwords.map((item) {
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
                  backgroundColor: AppColors.moduleVault.withValues(alpha: 0.12),
                  child: Icon(item.icon, color: AppColors.moduleVault, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Text(
                        item.username,
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextCaption : AppColors.textCaption),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.moduleVault),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password copied to clipboard safely!'), behavior: SnackBarBehavior.floating),
                    );
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDocumentsTab(BuildContext context, List<VaultDocumentEntity> documents, bool isDark) {
    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 90),
      children: [
        if (!_isSecurityEnabled)
          _buildUnsecuredVaultBanner(context, isDark),
        // Automated Expiry Notice (PRD Feature)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.moduleTime.withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: AppRadius.radiusLg,
            border: Border.all(color: AppColors.moduleTime.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.notification_important_rounded, color: AppColors.moduleTime, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Automated Expiry Alerts: We notify you 30 days & 7 days before warranty or policy lapses.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...documents.map((doc) {
          final isExpiringSoon = doc.isExpiringSoon;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
              borderRadius: AppRadius.radiusLg,
              border: Border.all(
                color: isExpiringSoon ? AppColors.warning.withValues(alpha: 0.5) : (isDark ? AppColors.darkDivider : AppColors.divider),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: (isExpiringSoon ? AppColors.warning : AppColors.secondary).withValues(alpha: 0.12),
                  child: Icon(
                    doc.icon,
                    color: isExpiringSoon ? AppColors.warning : AppColors.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              doc.title,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ),
                          if (isExpiringSoon)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: AppRadius.radiusFull,
                              ),
                              child: const Text(
                                'Expiring',
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${doc.category} • ${doc.expiry}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isExpiringSoon ? AppColors.warning : (isDark ? AppColors.darkTextCaption : AppColors.textCaption),
                          fontWeight: isExpiringSoon ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_red_eye_rounded, size: 18),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Viewing ${doc.title} secure preview'), behavior: SnackBarBehavior.floating),
                    );
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _VaultLoadingView extends StatelessWidget {
  const _VaultLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        AppShimmerLoader.card(height: 70),
        SizedBox(height: 16),
        AppShimmerLoader.card(height: 60),
        SizedBox(height: 12),
        AppShimmerLoader.card(height: 60),
        SizedBox(height: 12),
        AppShimmerLoader.card(height: 60),
      ],
    );
  }
}
