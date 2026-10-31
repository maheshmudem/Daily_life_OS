import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../domain/entities/security_config_entity.dart';
import '../../domain/repositories/security_repository.dart';
import 'pattern_lock_grid_widget.dart';
import 'security_setup_wizard.dart';

class SecuritySettingsSheet extends StatefulWidget {
  final SecurityRepository securityRepository;
  final VoidCallback onLockNow;

  const SecuritySettingsSheet({
    super.key,
    required this.securityRepository,
    required this.onLockNow,
  });

  static Future<void> show(
    BuildContext context, {
    required SecurityRepository securityRepository,
    required VoidCallback onLockNow,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SecuritySettingsSheet(
        securityRepository: securityRepository,
        onLockNow: onLockNow,
      ),
    );
  }

  @override
  State<SecuritySettingsSheet> createState() => _SecuritySettingsSheetState();
}

class _SecuritySettingsSheetState extends State<SecuritySettingsSheet> {
  SecurityConfigEntity? _config;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final cfg = await widget.securityRepository.getConfig();
    if (mounted) {
      setState(() {
        _config = cfg;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCardBackground : Colors.white;

    return Container(
      decoration: BoxDecoration(color: cardBg, borderRadius: AppRadius.topXxl),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
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
              const SizedBox(height: 16),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.moduleVault.withValues(alpha: 0.15),
                          borderRadius: AppRadius.radiusSm,
                        ),
                        child: const Icon(
                          Icons.security_rounded,
                          size: 20,
                          color: AppColors.moduleVault,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Security & Vault Lock',
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextHeading
                              : AppColors.textHeading,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_config != null && !_config!.isSecurityEnabled) ...[
                // ── UNPROTECTED VAULT STATE ────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(
                      alpha: isDark ? 0.15 : 0.08,
                    ),
                    borderRadius: AppRadius.radiusLg,
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.lock_open_rounded,
                        size: 40,
                        color: AppColors.warning,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Vault Security is Disabled',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextHeading
                              : AppColors.textHeading,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Anyone using this phone can view your saved passwords, bank logins, and sensitive documents. Set up a PIN or Pattern to protect your data.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? AppColors.darkTextCaption
                              : AppColors.textCaption,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            SecuritySetupWizard.show(
                              context,
                              securityRepository: widget.securityRepository,
                              onCompleted: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Vault security enabled successfully!',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.moduleVault,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.radiusMd,
                            ),
                          ),
                          icon: const Icon(Icons.shield_rounded, size: 18),
                          label: const Text(
                            'Set Up Security Now',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_config != null && _config!.isSecurityEnabled) ...[
                // ── SECURITY ENABLED STATE ─────────────────────────────────
                // Lock Vault Now Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onLockNow();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.moduleVault,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.radiusMd,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.lock_rounded, size: 18),
                    label: const Text(
                      'Lock Vault Immediately',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Enable Security Toggle (Requires authentication to disable!)
                _buildSwitchTile(
                  icon: Icons.shield_rounded,
                  title: 'Vault Security Lock',
                  subtitle: 'Requires PIN or Pattern to unlock',
                  value: _config!.isSecurityEnabled,
                  isDark: isDark,
                  onChanged: (val) {
                    if (!val) {
                      _confirmCurrentCredential(
                        title: 'Disable Vault Security?',
                        subtitle:
                            'Confirm your current PIN/Pattern to turn off security protection.',
                        onVerified: () async {
                          await widget.securityRepository.setSecurityEnabled(
                            false,
                          );
                          _loadConfig();
                        },
                      );
                    }
                  },
                ),
                const Divider(),

                // Biometrics Switch
                _buildSwitchTile(
                  icon: Icons.fingerprint_rounded,
                  title: 'Biometric Unlock (Fingerprint / Face)',
                  subtitle: 'Unlock instantly with hardware biometric sensor',
                  value: _config!.isBiometricEnabled,
                  isDark: isDark,
                  onChanged: (val) async {
                    await widget.securityRepository.setBiometricsEnabled(val);
                    _loadConfig();
                  },
                ),
                const Divider(),

                // Preferred Lock Mode (PIN vs Pattern)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.tune_rounded,
                    color: AppColors.moduleVault,
                  ),
                  title: Text(
                    'Default Unlock Method',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextHeading
                          : AppColors.textHeading,
                    ),
                  ),
                  subtitle: Text(
                    _config!.activeMode == SecurityLockMode.pin
                        ? '4-Digit PIN Code'
                        : '3x3 Pattern Lock',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextCaption
                          : AppColors.textCaption,
                    ),
                  ),
                  trailing: DropdownButton<SecurityLockMode>(
                    value: _config!.activeMode,
                    dropdownColor: isDark
                        ? AppColors.darkCardBackground
                        : Colors.white,
                    underline: const SizedBox.shrink(),
                    items: [
                      if (_config!.hasPin)
                        const DropdownMenuItem(
                          value: SecurityLockMode.pin,
                          child: Text('PIN Code'),
                        ),
                      if (_config!.hasPattern)
                        const DropdownMenuItem(
                          value: SecurityLockMode.pattern,
                          child: Text('Pattern'),
                        ),
                    ],
                    onChanged: (mode) async {
                      if (mode != null) {
                        await widget.securityRepository.setLockMode(mode);
                        _loadConfig();
                      }
                    },
                  ),
                ),
                const Divider(),

                // Change Master PIN
                _buildActionTile(
                  icon: Icons.pin_rounded,
                  title: _config!.hasPin
                      ? 'Change Master PIN'
                      : 'Set Up Master PIN',
                  subtitle: _config!.hasPin
                      ? 'Update your 4-digit numeric passcode'
                      : 'Add a numeric PIN unlock method',
                  isDark: isDark,
                  onTap: () {
                    if (_config!.hasPin) {
                      _confirmCurrentCredential(
                        title: 'Verify Current Access',
                        subtitle:
                            'Confirm your current PIN/Pattern before setting a new PIN.',
                        onVerified: () => _showChangePinDialog(isDecoy: false),
                      );
                    } else {
                      _showChangePinDialog(isDecoy: false);
                    }
                  },
                ),

                // Set Decoy / Panic PIN
                _buildActionTile(
                  icon: Icons.warning_amber_rounded,
                  iconColor: AppColors.error,
                  title: _config!.hasDecoyPin
                      ? 'Change Decoy PIN'
                      : 'Set Decoy / Panic PIN',
                  subtitle:
                      'Emergency PIN that displays a safe decoy screen under duress',
                  isDark: isDark,
                  onTap: () {
                    _confirmCurrentCredential(
                      title: 'Verify Current Access',
                      subtitle:
                          'Confirm your credentials to configure the Decoy PIN.',
                      onVerified: () => _showChangePinDialog(isDecoy: true),
                    );
                  },
                ),
                const Divider(),

                // Set Master Pattern
                _buildActionTile(
                  icon: Icons.pattern_rounded,
                  title: _config!.hasPattern
                      ? 'Change Master Pattern'
                      : 'Set Up Master Pattern',
                  subtitle: _config!.hasPattern
                      ? 'Draw a new 3x3 gesture unlock pattern'
                      : 'Add a gesture pattern unlock method',
                  isDark: isDark,
                  onTap: () {
                    if (_config!.hasPattern || _config!.hasPin) {
                      _confirmCurrentCredential(
                        title: 'Verify Current Access',
                        subtitle:
                            'Confirm your current credentials before setting a new pattern.',
                        onVerified: () =>
                            _showChangePatternDialog(isDecoy: false),
                      );
                    } else {
                      _showChangePatternDialog(isDecoy: false);
                    }
                  },
                ),

                // Set Decoy Pattern
                _buildActionTile(
                  icon: Icons.shield_moon_rounded,
                  iconColor: AppColors.error,
                  title: _config!.hasDecoyPattern
                      ? 'Change Decoy Pattern'
                      : 'Set Decoy Pattern',
                  subtitle:
                      'Emergency gesture pattern that opens a decoy vault',
                  isDark: isDark,
                  onTap: () {
                    _confirmCurrentCredential(
                      title: 'Verify Current Access',
                      subtitle:
                          'Confirm your credentials before setting the Decoy Pattern.',
                      onVerified: () => _showChangePatternDialog(isDecoy: true),
                    );
                  },
                ),
                const Divider(),

                // Reset / Clear Security
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                  title: const Text(
                    'Remove All Security',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                  subtitle: Text(
                    'Delete all stored PINs and patterns from hardware storage',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextCaption
                          : AppColors.textCaption,
                    ),
                  ),
                  onTap: () {
                    _confirmCurrentCredential(
                      title: 'Confirm Security Removal',
                      subtitle:
                          'Enter your credentials to wipe all security locks from the vault.',
                      onVerified: () async {
                        await widget.securityRepository.clearAllSecurity();
                        _loadConfig();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'All security locks removed. Vault is now unlocked.',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon, color: AppColors.moduleVault),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
        ),
      ),
      value: value,
      activeTrackColor: AppColors.moduleVault,
      onChanged: onChanged,
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    Color color = AppColors.moduleVault,
    Color? iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor ?? color),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }

  // ── Vulnerability Mitigation: Require verification before changes ──────────
  void _confirmCurrentCredential({
    required String title,
    required String subtitle,
    required VoidCallback onVerified,
  }) {
    final controller = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (dlgContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subtitle, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter 4-digit PIN',
                  counterText: '',
                  errorText: error,
                  border: const OutlineInputBorder(
                    borderRadius: AppRadius.radiusMd,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final pin = controller.text.trim();
                final isValid = await widget.securityRepository.verifyPin(pin);
                if (isValid) {
                  if (dlgContext.mounted) Navigator.pop(dlgContext);
                  onVerified();
                } else {
                  setDialogState(
                    () => error = 'Incorrect PIN. Verification failed.',
                  );
                }
              },
              child: const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePinDialog({required bool isDecoy}) {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (dlgContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isDecoy ? 'Set Decoy / Panic PIN' : 'Set Master PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isDecoy
                    ? 'Enter a 4-digit emergency PIN. When entered at the lock screen, it displays an empty decoy vault.'
                    : 'Enter and confirm a 4-digit numeric PIN.',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: isDecoy ? 'Decoy PIN' : 'New PIN',
                  hintText: '4 digits',
                  border: const OutlineInputBorder(
                    borderRadius: AppRadius.radiusMd,
                  ),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm PIN',
                  hintText: 'Re-enter 4 digits',
                  errorText: error,
                  border: const OutlineInputBorder(
                    borderRadius: AppRadius.radiusMd,
                  ),
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final pin = pinController.text.trim();
                final confirm = confirmController.text.trim();
                if (pin.length != 4) {
                  setDialogState(() => error = 'PIN must be exactly 4 digits.');
                  return;
                }
                if (pin != confirm) {
                  setDialogState(() => error = 'PINs do not match.');
                  return;
                }

                final messenger = ScaffoldMessenger.of(context);
                if (isDecoy) {
                  await widget.securityRepository.setDecoyPin(pin);
                } else {
                  await widget.securityRepository.setPin(pin: pin);
                }

                if (dlgContext.mounted) Navigator.pop(dlgContext);
                _loadConfig();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      isDecoy ? 'Decoy PIN updated!' : 'Master PIN saved!',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Save PIN'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePatternDialog({required bool isDecoy}) {
    List<int>? recordedPattern;

    showDialog(
      context: context,
      builder: (dlgContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isDecoy ? 'Draw Decoy Pattern' : 'Draw Master Pattern'),
          content: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isDecoy
                      ? 'Connect at least 4 dots for your Decoy Pattern.'
                      : 'Connect at least 4 dots to set your new unlock gesture.',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                PatternLockGridWidget(
                  size: 240,
                  onPatternComplete: (pattern) {
                    setDialogState(() {
                      recordedPattern = pattern;
                    });
                  },
                ),
                if (recordedPattern != null)
                  Text(
                    'Recorded ${recordedPattern!.length} dots',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.moduleVault,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed:
                  (recordedPattern != null && recordedPattern!.length >= 4)
                  ? () async {
                      final messenger = ScaffoldMessenger.of(context);
                      if (isDecoy) {
                        await widget.securityRepository.setDecoyPattern(
                          recordedPattern!,
                        );
                      } else {
                        await widget.securityRepository.setPattern(
                          pattern: recordedPattern!,
                        );
                      }
                      if (dlgContext.mounted) Navigator.pop(dlgContext);
                      _loadConfig();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            isDecoy
                                ? 'Decoy Pattern saved!'
                                : 'Master Pattern saved!',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  : null,
              child: const Text('Save Pattern'),
            ),
          ],
        ),
      ),
    );
  }
}
