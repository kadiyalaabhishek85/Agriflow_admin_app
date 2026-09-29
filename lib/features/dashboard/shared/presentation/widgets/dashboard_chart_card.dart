import 'package:flutter/material.dart';
import 'package:agriflow_admin/core/constants/app_colors.dart';
import 'package:agriflow_admin/core/constants/app_typography.dart';

class MonthlyChartPoint {
  final String label;
  final double value;

  const MonthlyChartPoint({
    required this.label,
    required this.value,
  });
}

/// Performant, custom-painted Bezier area chart matching the approved Recharts visual style.
class DashboardChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<MonthlyChartPoint> points;
  final bool isLoading;

  const DashboardChartCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.points,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(color: AppColors.line),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                size: 20,
                color: AppColors.canopy,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleSmall().copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 8),
                Text(
                  subtitle!,
                  style: AppTypography.caption(
                    color: AppColors.textMuted,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const SizedBox(
              height: 180,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (points.isEmpty)
            SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  'No historical report data available',
                  style: AppTypography.bodySmall(color: AppColors.textMuted),
                ),
              ),
            )
          else
            SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(
                painter: _AreaChartPainter(points: points),
              ),
            ),
        ],
      ),
    );
  }
}

class _AreaChartPainter extends CustomPainter {
  final List<MonthlyChartPoint> points;

  _AreaChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final double maxVal = points
        .map((p) => p.value)
        .fold(0.0, (prev, curr) => curr > prev ? curr : prev);
    final double ceiling = maxVal <= 0 ? 10000 : maxVal * 1.25;

    const double bottomPadding = 24.0;
    const double topPadding = 12.0;
    const double leftPadding = 8.0;
    const double rightPadding = 8.0;

    final double chartHeight = size.height - bottomPadding - topPadding;
    final double chartWidth = size.width - leftPadding - rightPadding;

    // Draw horizontal dashed grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFF0F0F0)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 3; i++) {
      final y = topPadding + (chartHeight / 3) * i;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );
    }

    // Calculate Coordinates
    final List<Offset> coordinates = [];
    final double stepX = points.length > 1
        ? chartWidth / (points.length - 1)
        : chartWidth / 2;

    for (int i = 0; i < points.length; i++) {
      final x = leftPadding + (i * stepX);
      final normalizedY = points[i].value / ceiling;
      final y = topPadding + chartHeight * (1.0 - normalizedY);
      coordinates.add(Offset(x, y));
    }

    // Build Spline / Bezier Path
    final strokePath = Path();
    strokePath.moveTo(coordinates.first.dx, coordinates.first.dy);

    for (int i = 0; i < coordinates.length - 1; i++) {
      final p0 = coordinates[i];
      final p1 = coordinates[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      strokePath.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    // Area Path
    final areaPath = Path.from(strokePath);
    areaPath.lineTo(coordinates.last.dx, topPadding + chartHeight);
    areaPath.lineTo(coordinates.first.dx, topPadding + chartHeight);
    areaPath.close();

    // Fill with gradient
    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF22C55E).withValues(alpha: 0.35),
        const Color(0xFF22C55E).withValues(alpha: 0.0),
      ],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(
        Rect.fromLTWH(0, topPadding, size.width, chartHeight),
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(areaPath, fillPaint);

    // Stroke line
    final strokePaint = Paint()
      ..color = const Color(0xFF16A34A)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(strokePath, strokePaint);

    // Draw Data Point Dots & Labels
    final dotPaint = Paint()..color = const Color(0xFF16A34A);
    final dotInnerPaint = Paint()..color = Colors.white;

    for (int i = 0; i < coordinates.length; i++) {
      final c = coordinates[i];
      canvas.drawCircle(c, 4, dotPaint);
      canvas.drawCircle(c, 2, dotInnerPaint);

      // Month text
      final textSpan = TextSpan(
        text: points[i].label,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 10,
          fontWeight: FontWeight.w600,
          fontFamily: 'Manrope',
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(c.dx - (textPainter.width / 2), size.height - 18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AreaChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
