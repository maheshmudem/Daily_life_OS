import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textCaption,
          ),
        ),
        const SizedBox(height: 8),
        // Chips area
        if (widget.values.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: List.generate(widget.values.length, (index) {
              return Chip(
                label: Text(
                  widget.values[index],
                  style: const TextStyle(fontSize: 13),
                ),
                deleteIcon:
                    widget.enabled ? const Icon(Icons.close, size: 16) : null,
                onDeleted: widget.enabled ? () => _removeItem(index) : null,
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
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
            decoration: InputDecoration(
              hintText: widget.hintText,
              counterText: '',
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.border, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              suffixIcon: GestureDetector(
                onTap: _addItem,
                child: Container(
                  margin: const EdgeInsets.all(4),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    widthFactor: 1,
                    child: Text('Add',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
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
