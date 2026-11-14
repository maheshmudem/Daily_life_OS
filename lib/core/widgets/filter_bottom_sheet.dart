import 'package:flutter/material.dart';
import 'package:daily_life_os/core/widgets/app_bottom_sheet.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_radius.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/theme_context.dart';

class FilterBottomSheet extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback onApply;
  final VoidCallback onClear;

  const FilterBottomSheet({
    super.key,
    this.title = 'Filters',
    required this.children,
    required this.onApply,
    required this.onClear,
  });

  static Future<void> show(
    BuildContext context, {
    String title = 'Filters',
    required List<Widget> children,
    required VoidCallback onApply,
    required VoidCallback onClear,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FilterBottomSheet(
        title: title,
        onApply: onApply,
        onClear: onClear,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.text;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            const AppSheetHandle(),
            AppSpacing.gapH16,
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  title,
                  style: text.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: p.heading,
                  ),
                ),
                TextButton(
                  onPressed: onClear,
                  child: AppText(
                    'Clear All',
                    style: text.labelLarge?.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            AppSpacing.gapH16,
            // Filter content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ),
            AppSpacing.gapH16,
            // Apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  onApply();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.radiusMd,
                  ),
                ),
                child: AppText(
                  'Apply Filters',
                  style: text.labelLarge?.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
