import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/mood_type.dart';
import '../state/mood_provider.dart';
import 'mood_statistics.dart';

enum _CalendarTab { calendar, summary }

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  bool _expanded = false;
  _CalendarTab _tab = _CalendarTab.calendar;

  @override
  Widget build(BuildContext context) {
    final mood = context.watch<MoodProvider>();
    final theme = Theme.of(context);
    final totalCheckIns = mood.totalCheckInsThisMonth;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Column(
          children: [
            // Tap to expand header
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_outlined,
                        size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('MMMM yyyy').format(
                        DateTime(mood.displayedYear, mood.displayedMonth),
                      ),
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (totalCheckIns > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$totalCheckIns logged',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<_CalendarTab>(
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    segments: const [
                      ButtonSegment(
                        value: _CalendarTab.calendar,
                        label: Text('Calendar'),
                        icon:
                            Icon(Icons.calendar_today_outlined, size: 16),
                      ),
                      ButtonSegment(
                        value: _CalendarTab.summary,
                        label: Text('Summary'),
                        icon: Icon(Icons.pie_chart_outline, size: 16),
                      ),
                    ],
                    selected: {_tab},
                    onSelectionChanged: (set) =>
                        setState(() => _tab = set.first),
                  ),
                ),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: _tab == _CalendarTab.calendar
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: _MonthGrid(mood: mood, theme: theme),
                secondChild: const MoodStatistics(asCard: false),
              ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.mood, required this.theme});

  final MoodProvider mood;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final firstDay =
        DateTime(mood.displayedYear, mood.displayedMonth, 1);
    final daysInMonth =
        DateTimeRange(
          start: firstDay,
          end: DateTime(mood.displayedYear, mood.displayedMonth + 1, 1),
        ).duration.inDays;

    // weekday 1=Mon ... 7=Sun → offset for Sun-first grid
    int startOffset = firstDay.weekday % 7; // 0=Sun,1=Mon,...

    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: Column(
        children: [
          // Day headers
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (ctx, idx) {
              if (idx < startOffset) return const SizedBox.shrink();

              final day = DateTime(
                  mood.displayedYear, mood.displayedMonth, idx - startOffset + 1);
              final isToday = day == todayNorm;
              final isSelected = day.year == mood.selectedDate.year &&
                  day.month == mood.selectedDate.month &&
                  day.day == mood.selectedDate.day;
              final isFuture = day.isAfter(todayNorm);
              final entry = mood.entryForDay(day);

              return GestureDetector(
                onTap: () => context.read<MoodProvider>().selectDate(day),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : isToday
                            ? theme.colorScheme.primaryContainer
                            : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : isFuture
                                  ? theme.colorScheme.onSurface
                                      .withValues(alpha: 0.3)
                                  : null,
                          fontWeight: isSelected || isToday
                              ? FontWeight.bold
                              : null,
                        ),
                      ),
                      if (entry != null && !isSelected)
                        Positioned(
                          bottom: 2,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: entry.mood.color,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
