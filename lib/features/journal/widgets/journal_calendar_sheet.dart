import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../mood/models/mood_type.dart';
import '../providers/journal_provider.dart';

/// Monthly calendar sheet allowing mothers to browse and filter their journal by date.
/// Shows indicators on days containing entries, with optional mood accenting.
class JournalCalendarSheet extends StatefulWidget {
  final JournalProvider provider;

  const JournalCalendarSheet({super.key, required this.provider});

  static Future<void> show(BuildContext context, JournalProvider provider) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => JournalCalendarSheet(provider: provider),
    );
  }

  @override
  State<JournalCalendarSheet> createState() => _JournalCalendarSheetState();
}

class _JournalCalendarSheetState extends State<JournalCalendarSheet> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final filter = widget.provider.filterDate;
    final now = DateTime.now();
    _currentMonth = filter != null
        ? DateTime(filter.year, filter.month, 1)
        : DateTime(now.year, now.month, 1);
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = widget.provider.filterDate != null
        ? DateTime(
            widget.provider.filterDate!.year,
            widget.provider.filterDate!.month,
            widget.provider.filterDate!.day,
          )
        : null;

    final entryMoods = widget.provider.entryDatesWithMood;

    // Calendar calculations
    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    final firstWeekday =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday %
        7; // Sunday = 0

    final totalGridCells = firstWeekday + daysInMonth;
    final rowCount = (totalGridCells / 7).ceil();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Month / Year + Navigation
            Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('MMMM yyyy').format(_currentMonth),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Previous month',
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: _prevMonth,
                ),
                IconButton(
                  tooltip: 'Next month',
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: _nextMonth,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Weekday labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.75,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),

            // Days Grid
            ...List.generate(rowCount, (rowIndex) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: List.generate(7, (colIndex) {
                    final cellIndex = rowIndex * 7 + colIndex;
                    final dayNumber = cellIndex - firstWeekday + 1;

                    if (dayNumber < 1 || dayNumber > daysInMonth) {
                      return const Expanded(child: SizedBox(height: 42));
                    }

                    final cellDate = DateTime(
                      _currentMonth.year,
                      _currentMonth.month,
                      dayNumber,
                    );
                    final isSelectedDate = selected == cellDate;
                    final isTodayDate = today == cellDate;
                    final hasEntry = entryMoods.containsKey(cellDate);
                    final mood = entryMoods[cellDate];

                    return Expanded(
                      child: Semantics(
                        button: true,
                        label:
                            '${DateFormat('MMMM d').format(cellDate)}${hasEntry ? ', has journal entry' : ''}',
                        selected: isSelectedDate,
                        child: InkWell(
                          onTap: () {
                            widget.provider.setFilterDate(cellDate);
                            Navigator.of(context).pop();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelectedDate
                                  ? theme.colorScheme.primary
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              border: isTodayDate && !isSelectedDate
                                  ? Border.all(
                                      color: theme.colorScheme.primary,
                                      width: 1.5,
                                    )
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$dayNumber',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelectedDate || isTodayDate
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelectedDate
                                        ? theme.colorScheme.onPrimary
                                        : (cellDate.isAfter(today)
                                              ? theme.colorScheme.onSurface
                                                    .withValues(alpha: 0.4)
                                              : theme.colorScheme.onSurface),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                // Dot indicator for days with entries
                                if (hasEntry)
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelectedDate
                                          ? theme.colorScheme.onPrimary
                                          : (mood?.color ??
                                                theme.colorScheme.primary),
                                    ),
                                  )
                                else
                                  const SizedBox(height: 5),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
            const SizedBox(height: 16),

            // Footer Actions
            Row(
              children: [
                if (widget.provider.filterDate != null)
                  TextButton.icon(
                    onPressed: () {
                      widget.provider.setFilterDate(null);
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.clear_all_rounded, size: 18),
                    label: const Text('Show All Entries'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    widget.provider.setFilterDate(today);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Today'),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
