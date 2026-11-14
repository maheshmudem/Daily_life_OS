import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/theme_context.dart';

/// A reusable text widget that prevents awkward single-line truncation
/// ("half text") by showing up to [collapsedMaxLines] lines and providing
/// a smooth, animated "Show more / Show less" toggle when the text is long.
class ExpandableTextWidget extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int collapsedMaxLines;
  final int characterThreshold;
  final Color? toggleColor;
  final String expandLabel;
  final String collapseLabel;
  final TextAlign? textAlign;

  const ExpandableTextWidget({
    super.key,
    required this.text,
    this.style,
    this.collapsedMaxLines = 2,
    this.characterThreshold = 65,
    this.toggleColor,
    this.expandLabel = 'Show more',
    this.collapseLabel = 'Show less',
    this.textAlign,
  });

  @override
  State<ExpandableTextWidget> createState() => _ExpandableTextWidgetState();
}

class _ExpandableTextWidgetState extends State<ExpandableTextWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.text.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveStyle =
            widget.style ?? DefaultTextStyle.of(context).style;
        final bool exceedsLines;
        if (constraints.maxWidth.isFinite && constraints.maxWidth > 0) {
          final painter = TextPainter(
            text: TextSpan(text: widget.text, style: effectiveStyle),
            maxLines: widget.collapsedMaxLines,
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(maxWidth: constraints.maxWidth);
          exceedsLines = painter.didExceedMaxLines;
        } else {
          final newlineCount = '\n'.allMatches(widget.text).length;
          exceedsLines =
              widget.text.length > widget.characterThreshold ||
              newlineCount >= widget.collapsedMaxLines;
        }

        final accentColor = widget.toggleColor ?? AppColors.primary;

        return AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.text,
                textAlign: widget.textAlign,
                maxLines: _isExpanded ? null : widget.collapsedMaxLines,
                overflow: _isExpanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: effectiveStyle,
              ),
              if (exceedsLines)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isExpanded
                                ? widget.collapseLabel
                                : widget.expandLabel,
                            style: context.text.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 14,
                            color: accentColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
