import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../mood/models/mood_type.dart';
import '../providers/journal_provider.dart';

/// Modal bottom sheet allowing mothers to filter their journal timeline.
class JournalFilterSheet extends StatelessWidget {
  final JournalProvider provider;

  const JournalFilterSheet({
    super.key,
    required this.provider,
  });

  static Future<void> show(BuildContext context, JournalProvider provider) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => JournalFilterSheet(provider: provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Filter Journal Entries',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (provider.hasActiveFilters)
                  TextButton(
                    onPressed: () {
                      provider.clearFilters();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Reset All'),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Favorites filter switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Favorites Only'),
              secondary: const Icon(Icons.star_rounded, color: Colors.amber),
              value: provider.onlyFavorites,
              onChanged: (val) => provider.setFilterFavorites(val),
            ),
            const Divider(),

            // Mood Filter
            Text(
              'By Mood',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Moods'),
                    selected: provider.filterMoodId == null,
                    onSelected: (sel) {
                      if (sel) provider.setFilterMood(null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ...MoodType.values.map((mood) {
                    final isSel = provider.filterMoodId == mood.name;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Image.asset(
                          mood.assetPath,
                          width: 18,
                          height: 18,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.sentiment_neutral,
                            size: 16,
                            color: mood.color,
                          ),
                        ),
                        label: Text(mood.label),
                        selected: isSel,
                        onSelected: (sel) {
                          provider.setFilterMood(sel ? mood.name : null);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Date Filter
            Text(
              'By Date',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: provider.filterDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        provider.setFilterDate(picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: Text(
                      provider.filterDate != null
                          ? DateFormat('MMMM d, yyyy')
                              .format(provider.filterDate!)
                          : 'Select a date',
                    ),
                  ),
                ),
                if (provider.filterDate != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Clear date filter',
                    onPressed: () => provider.setFilterDate(null),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // Apply button
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Apply Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
