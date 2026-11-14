import 'package:flutter/material.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_radius.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/theme_context.dart';

/// A reusable chip input widget that allows users to add/remove string items.
///
/// Used by Profile (medicalHistory, surgicalHistory, currentMedications, knownAllergies)
/// and Family Members (medicalConditions, allergies).
class ChipInputWidget extends StatefulWidget {
  /// The label displayed above the chip area.
  final String label;

  /// Current list of chip values.
  final List<String> values;

  /// Called when the list of values changes.
  final ValueChanged<List<String>> onChanged;

  /// Hint text for the input field.
  final String hintText;

  /// Maximum number of chips allowed. Null means unlimited.
  final int? maxItems;

  /// Maximum length of each chip text.
  final int maxLength;

  /// Whether the widget is enabled for editing.
  final bool enabled;

  const ChipInputWidget({
    super.key,
    required this.label,
    required this.values,
    required this.onChanged,
    this.hintText = 'Type and press Add',
    this.maxItems,
    this.maxLength = 200,
    this.enabled = true,
  });

  @override
  State<ChipInputWidget> createState() => _ChipInputWidgetState();
}

class _ChipInputWidgetState extends State<ChipInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addItem() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (text.length > widget.maxLength) return;
    if (widget.maxItems != null && widget.values.length >= widget.maxItems!) {
      return;
    }
    // Avoid duplicates (case-insensitive)
    if (widget.values.any((v) => v.toLowerCase() == text.toLowerCase())) {
      _controller.clear();
      return;
    }

    final updated = List<String>.from(widget.values)..add(text);
    widget.onChanged(updated);
    _controller.clear();
    _focusNode.requestFocus();
  }

  void _removeItem(int index) {
    final updated = List<String>.from(widget.values)..removeAt(index);
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(
          widget.label,
          style: text.labelMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: p.caption,
          ),
        ),
        AppSpacing.gapH8,
        // Chips area
        if (widget.values.isNotEmpty)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: 6,
            children: List.generate(widget.values.length, (index) {
              return Chip(
                label: AppText(
                  widget.values[index],
                  style: text.bodySmall?.copyWith(
                    fontSize: 13,
                    color: p.heading,
                  ),
                ),
                deleteIcon: widget.enabled
                    ? const Icon(Icons.close, size: 16)
                    : null,
                onDeleted: widget.enabled ? () => _removeItem(index) : null,
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.radiusXl,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }),
          ),
        // Input field with inline Add button
        if (widget.enabled)
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLength: widget.maxLength,
            style: text.bodyMedium?.copyWith(color: p.heading),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: text.bodyMedium?.copyWith(color: p.caption),
              counterText: '',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: AppRadius.radiusSm,
                borderSide: BorderSide(color: p.border, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusSm,
                borderSide: BorderSide(color: p.border, width: 1),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: AppRadius.radiusSm,
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
              suffixIcon: GestureDetector(
                onTap: _addItem,
                child: Container(
                  margin: const EdgeInsets.all(AppSpacing.xs),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: AppRadius.radiusXs,
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: AppText(
                      'Add',
                      style: text.labelMedium?.copyWith(
                        color: AppColors.textWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            onSubmitted: (_) => _addItem(),
          ),
      ],
    );
  }
}
