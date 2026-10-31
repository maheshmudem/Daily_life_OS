import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme/app_colors.dart';

class PatternLockGridWidget extends StatefulWidget {
  final int dimension;
  final double size;
  final bool hasError;
  final String? errorMessage;
  final ValueChanged<List<int>> onPatternComplete;
  final VoidCallback? onPatternStart;

  const PatternLockGridWidget({
    super.key,
    this.dimension = 3,
    this.size = 250.0,
    this.hasError = false,
    this.errorMessage,
    required this.onPatternComplete,
    this.onPatternStart,
  });

  @override
  State<PatternLockGridWidget> createState() => _PatternLockGridWidgetState();
}

class _PatternLockGridWidgetState extends State<PatternLockGridWidget> {
  final List<int> _selectedNodes = [];
  Offset? _currentTouchPosition;

  void _handlePanStart(DragStartDetails details, BoxConstraints constraints) {
    widget.onPatternStart?.call();
    setState(() {
      _selectedNodes.clear();
      _currentTouchPosition = details.localPosition;
    });
    _checkNodeHit(details.localPosition, constraints);
  }

  void _handlePanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    setState(() {
      _currentTouchPosition = details.localPosition;
    });
    _checkNodeHit(details.localPosition, constraints);
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_selectedNodes.isNotEmpty) {
      final pattern = List<int>.from(_selectedNodes);
      widget.onPatternComplete(pattern);
    }
    setState(() {
      _currentTouchPosition = null;
    });
  }

  void _checkNodeHit(Offset position, BoxConstraints constraints) {
    final size = widget.size;
    final step = size / (widget.dimension + 1);
    final hitRadius = step * 0.45;

    for (int row = 0; row < widget.dimension; row++) {
      for (int col = 0; col < widget.dimension; col++) {
        final nodeIndex = row * widget.dimension + col;
        final center = Offset((col + 1) * step, (row + 1) * step);

        if ((position - center).distance <= hitRadius) {
          if (!_selectedNodes.contains(nodeIndex)) {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedNodes.add(nodeIndex);
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.errorMessage != null && widget.errorMessage!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              widget.errorMessage!,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          )
        else
          const SizedBox(height: 16),

        Center(
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: GestureDetector(
              onPanStart: (d) => _handlePanStart(
                d,
                BoxConstraints.tightFor(
                  width: widget.size,
                  height: widget.size,
                ),
              ),
              onPanUpdate: (d) => _handlePanUpdate(
                d,
                BoxConstraints.tightFor(
                  width: widget.size,
                  height: widget.size,
                ),
              ),
              onPanEnd: _handlePanEnd,
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _PatternPainter(
                  dimension: widget.dimension,
                  selectedNodes: _selectedNodes,
                  currentPosition: _currentTouchPosition,
                  hasError: widget.hasError,
                  isDark: isDark,
                  accentColor: AppColors.moduleVault,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PatternPainter extends CustomPainter {
  final int dimension;
  final List<int> selectedNodes;
  final Offset? currentPosition;
  final bool hasError;
  final bool isDark;
  final Color accentColor;

  _PatternPainter({
    required this.dimension,
    required this.selectedNodes,
    required this.currentPosition,
    required this.hasError,
    required this.isDark,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / (dimension + 1);
    final activeColor = hasError ? AppColors.error : accentColor;

    final linePaint = Paint()
      ..color = activeColor.withValues(alpha: 0.8)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final haloPaint = Paint()
      ..color = activeColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()..style = PaintingStyle.fill;

    // 1. Draw connecting lines between nodes
    if (selectedNodes.length > 1) {
      final path = Path();
      for (int i = 0; i < selectedNodes.length; i++) {
        final node = selectedNodes[i];
        final col = node % dimension;
        final row = node ~/ dimension;
        final point = Offset((col + 1) * step, (row + 1) * step);

        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, linePaint);
    }

    // 2. Draw line from last node to finger
    if (selectedNodes.isNotEmpty && currentPosition != null) {
      final lastNode = selectedNodes.last;
      final col = lastNode % dimension;
      final row = lastNode ~/ dimension;
      final start = Offset((col + 1) * step, (row + 1) * step);
      canvas.drawLine(start, currentPosition!, linePaint);
    }

    // 3. Draw dots
    for (int row = 0; row < dimension; row++) {
      for (int col = 0; col < dimension; col++) {
        final nodeIndex = row * dimension + col;
        final center = Offset((col + 1) * step, (row + 1) * step);
        final isSelected = selectedNodes.contains(nodeIndex);

        if (isSelected) {
          // Glow Halo
          canvas.drawCircle(center, step * 0.35, haloPaint);

          // Outer Ring
          final ringPaint = Paint()
            ..color = activeColor
            ..strokeWidth = 2.5
            ..style = PaintingStyle.stroke;
          canvas.drawCircle(center, step * 0.28, ringPaint);

          // Inner Solid Dot
          dotPaint.color = activeColor;
          canvas.drawCircle(center, 7.0, dotPaint);
        } else {
          // Unselected dot
          dotPaint.color = isDark
              ? AppColors.darkDivider
              : AppColors.surfaceMuted;
          canvas.drawCircle(center, 6.0, dotPaint);

          // Inner subtle point
          final innerDotPaint = Paint()
            ..color = isDark ? AppColors.darkTextCaption : AppColors.textCaption
            ..style = PaintingStyle.fill;
          canvas.drawCircle(center, 2.5, innerDotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) {
    return oldDelegate.selectedNodes.length != selectedNodes.length ||
        oldDelegate.currentPosition != currentPosition ||
        oldDelegate.hasError != hasError;
  }
}
