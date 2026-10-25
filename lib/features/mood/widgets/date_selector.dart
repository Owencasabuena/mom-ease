import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/mood_type.dart';
import '../state/mood_provider.dart';

class DateSelector extends StatefulWidget {
  const DateSelector({super.key});

  @override
  State<DateSelector> createState() => _DateSelectorState();
}

class _DateSelectorState extends State<DateSelector> {
  late ScrollController _scroll;
  static const int _range = 30; // days before today to show

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToToday() {
    const itemWidth = 64.0;
    final offset = (_range * itemWidth) - (MediaQuery.of(context).size.width / 2) + itemWidth / 2;
    if (_scroll.hasClients) {
      _scroll.animateTo(
        offset.clamp(0, _scroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  List<DateTime> _buildDays() {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day).subtract(Duration(days: _range));
    return List.generate(
      _range + 15, // show 15 future days (greyed out)
      (i) => start.add(Duration(days: i)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mood = context.watch<MoodProvider>();
    final theme = Theme.of(context);
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final days = _buildDays();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month / year header with arrows
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => mood.goToPreviousMonth(),
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(
                    DateTime(mood.displayedYear, mood.displayedMonth),
                  ),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => mood.goToNextMonth(),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 88,
          child: ListView.builder(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: days.length,
            itemBuilder: (ctx, i) {
              final day = days[i];
              final isToday = day == todayNorm;
              final isSelected = day.year == mood.selectedDate.year &&
                  day.month == mood.selectedDate.month &&
                  day.day == mood.selectedDate.day;
              final isFuture = day.isAfter(todayNorm);
              final entry = mood.entryForDay(day);

              return GestureDetector(
                onTap: () => mood.selectDate(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : isToday
                            ? theme.colorScheme.primaryContainer
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: isToday && !isSelected
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
                        DateFormat('EEE').format(day).toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : isFuture
                                  ? theme.colorScheme.onSurface
                                      .withValues(alpha: 0.3)
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${day.day}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : isFuture
                                  ? theme.colorScheme.onSurface
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
                                    ? theme.colorScheme.onPrimary
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
        ),
      ],
    );
  }
}
