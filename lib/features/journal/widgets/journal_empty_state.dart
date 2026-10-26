import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Supportive empty state displayed when a mother hasn't logged any entries,
/// or when a selected calendar date has no entries.
class JournalEmptyState extends StatelessWidget {
  final VoidCallback onNewEntry;
  final DateTime? filterDate;
  final VoidCallback? onClearDateFilter;

  const JournalEmptyState({
    super.key,
    required this.onNewEntry,
    this.filterDate,
    this.onClearDateFilter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final isDateFiltered = filterDate != null;
    final isFutureDate =
        isDateFiltered &&
        DateTime(
          filterDate!.year,
          filterDate!.month,
          filterDate!.day,
        ).isAfter(today);

    final String title;
    final String subtitle;

    if (isDateFiltered) {
      final dateStr = DateFormat('MMMM d').format(filterDate!);
      title = 'No journal entries for $dateStr.';
      if (isFutureDate) {
        subtitle = 'Journal entries can only be added for today or past dates.';
      } else {
        subtitle = 'Take a quiet moment to record your thoughts from this day.';
      }
    } else {
      title = 'Your journal is ready when you are.';
      subtitle = 'Write a few words or speak your thoughts.';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.5,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDateFiltered
                    ? Icons.event_note_rounded
                    : Icons.menu_book_rounded,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isDateFiltered && isFutureDate) ...[
              if (onClearDateFilter != null)
                OutlinedButton.icon(
                  onPressed: onClearDateFilter,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Show All Entries'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
            ] else ...[
              FilledButton.icon(
                onPressed: onNewEntry,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  isDateFiltered ? 'Write an Entry' : 'New Entry',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
