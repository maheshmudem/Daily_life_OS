import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/theme_context.dart';
import '../constants/string_constants.dart';

class NetworkAwareWidget extends StatelessWidget {
  final Widget child;
  final bool isConnected;

  const NetworkAwareWidget({
    super.key,
    required this.child,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!isConnected)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.lg,
            ),
            color: AppColors.warning,
            child: Row(
              children: [
                const Icon(
                  Icons.wifi_off,
                  color: AppColors.textWhite,
                  size: 16,
                ),
                AppSpacing.gapW8,
                Expanded(
                  child: Text(
                    StringConstants.networkError,
                    style: context.text.bodySmall?.copyWith(
                      color: AppColors.textWhite,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(child: child),
      ],
    );
  }
}
