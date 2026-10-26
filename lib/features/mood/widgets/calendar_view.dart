import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/mood_type.dart';
import '../state/mood_provider.dart';
import 'mood_statistics.dart';

enum _CalendarTab { calendar, summary }

/// Unified date controller and calendar card.
/// Displays month navigation with an expandable header that reveals either
/// the full monthly calendar grid or monthly mood statistics, while offering
/// a horizontal day selector in its compact/default state.
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
            // Top Month navigation & tap-to-expand header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    tooltip: 'Previous month',
                    onPressed: () => mood.goToPreviousMonth(),
                  ),
                  Expanded(
                    child: Center(
                      child: InkWell(
                        key: const Key('month_header_expander'),
                        onTap: () => setState(() => _expanded = !_expanded),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DateFormat('MMMM yyyy').format(
                                  DateTime(
                                      mood.displayedYear, mood.displayedMonth),
                                ),
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _expanded
                                    ? Icons.arrow_drop_up
                                    : Icons.arrow_drop_down,
                                color: theme.colorScheme.primary,
                              ),
                              if (totalCheckIns > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    totalCheckIns == 1
                                        ? '1 check-in'
                                        : '$totalCheckIns check-ins',
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      color: theme
                                          .colorScheme.onSecondaryContainer,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    tooltip: 'Next month',
                    onPressed: () => mood.goToNextMonth(),
                  ),
                ],
              ),
            ),
            // Body: switches smoothly between horizontal strip and expanded month view
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: _HorizontalDayStrip(mood: mood, theme: theme),
              secondChild: Column(
                children: [
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
                            icon: Icon(Icons.calendar_today_outlined, size: 16),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Horizontal Day Strip (Compact View) ──────────────────────────────────────

class _HorizontalDayStrip extends StatefulWidget {
  const _HorizontalDayStrip({required this.mood, required this.theme});

  final MoodProvider mood;
  final ThemeData theme;

  @override
  State<_HorizontalDayStrip> createState() => _HorizontalDayStripState();
}

class _HorizontalDayStripState extends State<_HorizontalDayStrip> {
  late ScrollController _scroll;
  static const int _range = 30; // days before today

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(covariant _HorizontalDayStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood.selectedDate != widget.mood.selectedDate) {
      _scrollToSelected();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToSelected() {
    if (!_scroll.hasClients) return;
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final selected = DateTime(widget.mood.selectedDate.year,
        widget.mood.selectedDate.month, widget.mood.selectedDate.day);
    final daysDiff = selected.difference(todayNorm).inDays;
    final index = _range + daysDiff;
    const itemWidth = 68.0;
    final offset = (index * itemWidth) -
        (MediaQuery.of(context).size.width / 2) +
        itemWidth / 2;
    _scroll.animateTo(
      offset.clamp(0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  List<DateTime> _buildDays() {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: _range));
    return List.generate(
      _range + 15,
      (i) => start.add(Duration(days: i)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final days = _buildDays();

    return SizedBox(
      height: 84,
      child: ListView.builder(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        itemCount: days.length,
        itemBuilder: (ctx, i) {
          final day = days[i];
          final isToday = day == todayNorm;
          final isSelected = day.year == widget.mood.selectedDate.year &&
              day.month == widget.mood.selectedDate.month &&
              day.day == widget.mood.selectedDate.day;
          final isFuture = day.isAfter(todayNorm);
          final entry = widget.mood.entryForDay(day);

          return GestureDetector(
            onTap: () => widget.mood.selectDate(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? widget.theme.colorScheme.primary
                    : isToday
                        ? widget.theme.colorScheme.primaryContainer
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: isToday && !isSelected
                    ? Border.all(
                        color: widget.theme.colorScheme.primary,
                        width: 1.5,
                      )
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(day).toUpperCase(),
                    style: widget.theme.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? widget.theme.colorScheme.onPrimary
                          : isFuture
                              ? widget.theme.colorScheme.onSurface
                                  .withValues(alpha: 0.3)
                              : widget.theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.day}',
                    style: widget.theme.textTheme.titleSmall?.copyWith(
                      color: isSelected
                          ? widget.theme.colorScheme.onPrimary
                          : isFuture
                              ? widget.theme.colorScheme.onSurface
                                  .withValues(alpha: 0.3)
                              : null,
                      fontWeight:
                          isSelected || isToday ? FontWeight.bold : null,
                    ),
                  ),
                  if (entry != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Image.asset(
                        entry.mood.assetPath,
                        width: 18,
                        height: 18,
                        errorBuilder: (_, e, s) => Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? widget.theme.colorScheme.onPrimary
                                : entry.mood.color,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Full Month Grid View ─────────────────────────────────────────────────────

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
