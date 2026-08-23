import 'package:flutter/material.dart';
import 'dart:math';

/// Data class to hold the value and color for each section of the donut
class DonutChartSection {
  final double value;
  final Color color;
  final String? label;

  DonutChartSection({required this.value, required this.color, this.label});
}

/// The reusable Donut Chart Widget
class DonutChartWidget extends StatelessWidget {
  final List<DonutChartSection> sections;
  final int centerNumber;
  final String centerText;
  final double radius;
  final double strokeWidth;

  const DonutChartWidget({
    super.key,
    required this.sections,
    required this.centerNumber,
    required this.centerText,
    this.radius = 100.0,
    this.strokeWidth = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate dynamic sizes based on the radius
    final double numberFontSize = radius * 0.45;
    final double textFontSize = radius * 0.14;
    final double verticalSpacing = radius * 0.05;

    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. The Donut Ring
          SizedBox(
            width: radius * 2,
            height: radius * 2,
            child: CustomPaint(
              painter: _DonutChartPainter(
                sections: sections,
                strokeWidth: strokeWidth,
                zeroColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),

          // 2. The Center Text (Scales automatically)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerNumber.toString(),
                style: TextStyle(
                  fontSize: numberFontSize,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.0,
                ),
              ),
              SizedBox(height: verticalSpacing),
              Text(
                centerText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: textFontSize,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The CustomPainter that actually draws the arcs
class _DonutChartPainter extends CustomPainter {
  final List<DonutChartSection> sections;
  final double strokeWidth;
  final Color zeroColor;

  _DonutChartPainter({
    required this.sections,
    required this.strokeWidth,
    required this.zeroColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double total = sections.fold(0, (sum, section) => sum + section.value);

    // Calculate the drawing radius (inset by half the stroke width)
    final double drawRadius = (size.width - strokeWidth) / 2;
    final Offset centerOffset = Offset(size.width / 2, size.height / 2);

    // If total is 0 or list is empty, draw an empty grey circle placeholder
    if (total == 0 || sections.isEmpty) {
      final emptyPaint = Paint()
        ..color = zeroColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      canvas.drawCircle(centerOffset, drawRadius, emptyPaint);
      return;
    }

    // Normal drawing logic for when there is data
    double startAngle = -pi / 2;
    Rect rect = Rect.fromCircle(center: centerOffset, radius: drawRadius);

    for (var section in sections) {
      // Skip drawing logic for 0-value sections so they don't paint lines
      if (section.value == 0) continue;

      final sweepAngle = (section.value / total) * 2 * pi;

      final paint = Paint()
        ..color = section.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

      // Separator lines (optional, removes if you want a seamless donut)
      final separatorPaint = Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawArc(rect, startAngle, 0.005, false, separatorPaint);

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return true;
  }
}
