import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mood_type.dart';
import '../state/mood_provider.dart';

class MoodStatistics extends StatelessWidget {
  const MoodStatistics({super.key, this.asCard = true});

  final bool asCard;

  @override
  Widget build(BuildContext context) {
    final mood = context.watch<MoodProvider>();
    final theme = Theme.of(context);
    final counts = mood.monthlyCounts;
    final total = mood.totalCheckInsThisMonth;

    if (total == 0) {
      if (!asCard) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Center(
            child: Text(
              'No mood check-ins yet this month.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          elevation: 0,
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No mood check-ins yet this month.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (asCard) ...[
          Text(
            'Monthly Summary',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Half-donut chart
        ClipRect(
          child: SizedBox(
            height: 140,
            child: _HalfDonutChart(
              counts: counts,
              total: total,
              trackColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend rows
        ...MoodType.values.map((m) {
          final count = counts[m] ?? 0;
          final pct = total > 0 ? count / total : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: m.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(m.label, style: theme.textTheme.bodySmall),
                ),
                Text(
                  '$count',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(m.color),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '$total check-in${total == 1 ? '' : 's'} this month',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );

    if (!asCard) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: content,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(padding: const EdgeInsets.all(20), child: content),
      ),
    );
  }
}

class _HalfDonutChart extends StatelessWidget {
  const _HalfDonutChart({
    required this.counts,
    required this.total,
    required this.trackColor,
  });

  final Map<MoodType, int> counts;
  final int total;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const strokeWidth = 20.0;
        final height = constraints.maxHeight;
        final width = constraints.maxWidth;
        final centerDy = height - strokeWidth / 2 - 4;
        final maxRadius = math.min(
          width / 2 - strokeWidth / 2 - 8,
          centerDy - strokeWidth / 2 - 6,
        );
        final radius = maxRadius > 0 ? maxRadius : 0.0;
        final innerTop = centerDy - radius + strokeWidth / 2;
        final archCenterY = (innerTop + centerDy) / 2;

        return Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(width, height),
              painter: _HalfDonutPainter(
                counts: counts,
                total: total,
                trackColor: trackColor,
              ),
            ),
            Positioned(
              top: archCenterY - 18,
              child: Text(
                '$total',
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HalfDonutPainter extends CustomPainter {
  _HalfDonutPainter({
    required this.counts,
    required this.total,
    required this.trackColor,
  });

  final Map<MoodType, int> counts;
  final int total;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 20.0;
    final center = Offset(size.width / 2, size.height - strokeWidth / 2 - 4);
    final maxRadius = math.min(
      size.width / 2 - strokeWidth / 2 - 8,
      center.dy - strokeWidth / 2 - 6,
    );
    final radius = maxRadius > 0 ? maxRadius : 0.0;
    if (radius <= 0) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final arcRect = Rect.fromCircle(center: center, radius: radius);

    if (total == 0) {
      paint.color = trackColor;
      canvas.drawArc(arcRect, math.pi, math.pi, false, paint);
      return;
    }

    // Draw from π to 2π (left to right, top half circle)
    double startAngle = math.pi;
    for (final mood in MoodType.values.reversed) {
      final count = counts[mood] ?? 0;
      if (count == 0) continue;
      final sweep = math.pi * (count / total);
      paint.color = mood.color;
      canvas.drawArc(arcRect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }

    // Background track (if arc does not reach 2π)
    if (startAngle < math.pi * 2 - 0.01) {
      paint.color = trackColor;
      canvas.drawArc(
        arcRect,
        startAngle,
        math.pi * 2 - startAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HalfDonutPainter old) =>
      old.counts != counts ||
      old.total != total ||
      old.trackColor != trackColor;
}
