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
              firstChild: _HorizontalDayStrip(
                selectedDate: mood.selectedDate,
                mood: mood,
                theme: theme,
              ),
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
  const _HorizontalDayStrip({
    required this.selectedDate,
    required this.mood,
    required this.theme,
  });

  final DateTime selectedDate;
  final MoodProvider mood;
  final ThemeData theme;

  @override
  State<_HorizontalDayStrip> createState() => _HorizontalDayStripState();
}

class _HorizontalDayStripState extends State<_HorizontalDayStrip> {
  late ScrollController _scroll;
  DateTime? _lastSelectedDate;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();
    _lastSelectedDate = widget.selectedDate;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(covariant _HorizontalDayStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate ||
        _lastSelectedDate != widget.selectedDate) {
      _lastSelectedDate = widget.selectedDate;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToSelected() {
    if (!_scroll.hasClients) return;
    final days = _buildDays();
    final selected = widget.mood.selectedDate;
    final index = days.indexWhere((d) =>
        d.year == selected.year &&
        d.month == selected.month &&
        d.day == selected.day);
    if (index < 0) return;

    const totalItemWidth = 66.0;
    const listPadding = 8.0;
    final viewportWidth = _scroll.position.viewportDimension;
    final targetOffset = (index * totalItemWidth) +
        listPadding -
        (viewportWidth / 2) +
        (totalItemWidth / 2);

    _scroll.animateTo(
      targetOffset.clamp(0.0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  List<DateTime> _buildDays() {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final selectedNorm = DateTime(widget.mood.selectedDate.year,
        widget.mood.selectedDate.month, widget.mood.selectedDate.day);

    final earliest = selectedNorm
            .isBefore(todayNorm.subtract(const Duration(days: 60)))
        ? selectedNorm.subtract(const Duration(days: 7))
        : todayNorm.subtract(const Duration(days: 60));

    final latest =
        selectedNorm.isAfter(todayNorm.add(const Duration(days: 14)))
            ? selectedNorm.add(const Duration(days: 7))
            : todayNorm.add(const Duration(days: 14));

    final totalDays = latest.difference(earliest).inDays + 1;
    return List.generate(totalDays, (i) => earliest.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final days = _buildDays();

    return SizedBox(
      height: 96,
      child: ListView.builder(
        controller: _scroll,
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: days.length,
        itemBuilder: (ctx, i) {
          final day = days[i];
          final isToday = day == todayNorm;
          final isSelected = day.year == widget.mood.selectedDate.year &&
              day.month == widget.mood.selectedDate.month &&
              day.day == widget.mood.selectedDate.day;
          final isFuture = day.isAfter(todayNorm);
          final entry = widget.mood.entryForDay(day);

          Color bgColor;
          Border? border;
          List<BoxShadow>? shadows;
          Color weekdayColor;
          Color dayColor;

          if (isSelected) {
            bgColor = widget.theme.colorScheme.primary;
            weekdayColor =
                widget.theme.colorScheme.onPrimary.withValues(alpha: 0.9);
            dayColor = widget.theme.colorScheme.onPrimary;
            shadows = [
              BoxShadow(
                color:
                    widget.theme.colorScheme.primary.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ];
          } else if (isToday) {
            bgColor = widget.theme.colorScheme.primaryContainer
                .withValues(alpha: 0.5);
            border = Border.all(
              color: widget.theme.colorScheme.primary,
              width: 1.5,
            );
            weekdayColor = widget.theme.colorScheme.primary;
            dayColor = widget.theme.colorScheme.primary;
          } else if (isFuture) {
            bgColor = widget.theme.colorScheme.surfaceContainerLowest;
            border = Border.all(
              color: widget.theme.colorScheme.outlineVariant
                  .withValues(alpha: 0.2),
              width: 1,
            );
            weekdayColor = widget.theme.colorScheme.onSurfaceVariant
                .withValues(alpha: 0.65);
            dayColor = widget.theme.colorScheme.onSurface
                .withValues(alpha: 0.65);
          } else {
            bgColor = widget.theme.colorScheme.surfaceContainerLow;
            border = Border.all(
              color: widget.theme.colorScheme.outlineVariant
                  .withValues(alpha: 0.35),
              width: 1,
            );
            weekdayColor = widget.theme.colorScheme.onSurfaceVariant;
            dayColor = widget.theme.colorScheme.onSurface;
          }

          return Semantics(
            button: true,
            selected: isSelected,
            label:
                '${DateFormat('EEEE, MMMM d').format(day)}${entry != null ? ', Mood: ${entry.mood.label}' : ''}',
            child: Container(
              width: 58,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(18),
                border: border,
                boxShadow: shadows,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => widget.mood.selectDate(day),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('EEE').format(day).toUpperCase(),
                          style: widget.theme.textTheme.labelSmall?.copyWith(
                            color: weekdayColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.4,
                          ),
                        ),
                        Text(
                          '${day.day}',
                          style: widget.theme.textTheme.titleMedium?.copyWith(
                            color: dayColor,
                            fontWeight: isSelected || isToday
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 17,
                          ),
                        ),
                        SizedBox(
                          height: 20,
                          child: Center(
                            child: entry != null
                                ? Image.asset(
                                    entry.mood.assetPath,
                                    width: 20,
                                    height: 20,
                                    errorBuilder: (_, _, _) => Text(
                                      entry.mood.emoji,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1,
                                      ),
                                    ),
                                  )
                                : isToday
                                    ? Container(
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected
                                              ? widget.theme.colorScheme
                                                  .onPrimary
                                                  .withValues(alpha: 0.7)
                                              : widget.theme.colorScheme
                                                  .primary,
                                        ),
                                      )
                                    : const SizedBox(height: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
