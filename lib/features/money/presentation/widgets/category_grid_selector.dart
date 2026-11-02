import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../domain/entities/money_category.dart';

/// Animated category selector supporting both compact horizontal strip
/// and expanded 4-column squircle grid with zero overflow.
class CategoryGridSelector extends StatelessWidget {
  final List<MoneyCategory> categories;
  final String selectedKey;
  final ValueChanged<MoneyCategory> onSelect;
  final bool isGrid;

  const CategoryGridSelector({
    super.key,
    required this.categories,
    required this.selectedKey,
    required this.onSelect,
    this.isGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isGrid) {
      // Sleek horizontal scrollable category pills
      return SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isSelected = cat.key == selectedKey;
            return _CategoryPill(
              category: cat,
              isSelected: isSelected,
              isDark: isDark,
              onTap: () => onSelect(cat),
            );
          },
        ),
      );
    }

    // Expanded 4-column squircle grid with explicit height to prevent any overflow
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 76,
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

class _CategoryPill extends StatefulWidget {
  final MoneyCategory category;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.category,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_CategoryPill> createState() => _CategoryPillState();
}

class _CategoryPillState extends State<_CategoryPill> {
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
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? color
                : color.withValues(alpha: isDark ? 0.16 : 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? color
                  : (isDark ? AppColors.darkDivider : AppColors.divider),
              width: selected ? 1.5 : 0.8,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.category.icon,
                size: 16,
                color: selected ? Colors.white : color,
              ),
              const SizedBox(width: 7),
              Text(
                widget.category.shortLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : (isDark ? Colors.white : AppColors.textHeading),
                ),
              ),
            ],
          ),
        ),
      ),
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
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: isDark ? 0.20 : 0.10)
                : (isDark
                      ? AppColors.darkCardBackground
                      : AppColors.cardBackground),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? color
                  : (isDark ? AppColors.darkDivider : AppColors.divider),
              width: selected ? 1.8 : 1.0,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? color
                      : color.withValues(alpha: isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.category.icon,
                  size: 18,
                  color: selected ? Colors.white : color,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  widget.category.shortLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? (isDark ? Colors.white : color)
                        : (isDark
                              ? AppColors.darkTextBody
                              : AppColors.textHeading),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
