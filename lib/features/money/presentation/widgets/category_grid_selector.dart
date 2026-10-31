import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../domain/entities/money_category.dart';

/// 4-column animated category grid with press-scale feedback.
class CategoryGridSelector extends StatelessWidget {
  final List<MoneyCategory> categories;
  final String selectedKey;
  final ValueChanged<MoneyCategory> onSelect;

  const CategoryGridSelector({
    super.key,
    required this.categories,
    required this.selectedKey,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, index) {
        final cat = categories[index];
        final isSelected = cat.key == selectedKey;
        return _CategoryTile(
          category: cat,
          isSelected: isSelected,
          isDark: isDark,
          onTap: () => onSelect(cat),
        );
      },
    );
  }
}

class _CategoryTile extends StatefulWidget {
  final MoneyCategory category;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.category.color;
    final selected = widget.isSelected;
    final isDark = widget.isDark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: isDark ? 0.22 : 0.14)
                : (isDark
                      ? AppColors.darkCardBackground
                      : AppColors.cardBackground),
            borderRadius: AppRadius.radiusMd,
            border: Border.all(
              color: selected
                  ? color
                  : (isDark ? AppColors.darkDivider : AppColors.divider),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.category.icon,
                size: 24,
                color: selected
                    ? color
                    : (isDark ? AppColors.darkIconColor : AppColors.iconColor),
              ),
              const SizedBox(height: 6),
              Text(
                widget.category.shortLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? color
                      : (isDark ? AppColors.darkTextBody : AppColors.textBody),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
