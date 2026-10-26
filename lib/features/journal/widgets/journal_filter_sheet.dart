import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../mood/models/mood_type.dart';
import '../providers/journal_provider.dart';

/// Modal bottom sheet allowing mothers to filter their journal timeline by type
/// (Favorites, Mood, and Tags). Date browsing is handled separately via the Calendar.
class JournalFilterSheet extends StatelessWidget {
  final JournalProvider provider;

  const JournalFilterSheet({super.key, required this.provider});

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

    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Filter Journal',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Favorites filter switch
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Favorites Only',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Show only starred journal entries',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.favoriteStar.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: AppColors.favoriteStar,
                      size: 22,
                    ),
                  ),
                  value: provider.onlyFavorites,
                  onChanged: (val) => provider.setFilterFavorites(val),
                ),
                const Divider(height: 24),

                // Mood Filter Section
                Text(
                  'By Mood',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        showCheckmark: false,
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
                            showCheckmark: false,
                            tooltip: mood.label,
                            label: Image.asset(
                              mood.assetPath,
                              width: 24,
                              height: 24,
                              errorBuilder: (context, error, stackTrace) =>
                                  Text(
                                    mood.emoji,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                            ),
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
                const Divider(height: 28),

                // Tags Filter Section
                Text(
                  'By Tags',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (provider.availableTags.isEmpty)
                  Text(
                    'No tags available yet.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All Tags'),
                        selected: provider.filterTag == null,
                        onSelected: (sel) {
                          if (sel) provider.setFilterTag(null);
                        },
                      ),
                      ...provider.availableTags.map((tag) {
                        final isSel =
                            provider.filterTag?.toLowerCase() ==
                            tag.toLowerCase();
                        return FilterChip(
                          label: Text('#$tag'),
                          selected: isSel,
                          onSelected: (sel) {
                            provider.setFilterTag(sel ? tag : null);
                          },
                          labelStyle: TextStyle(
                            fontWeight: isSel
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        );
                      }),
                    ],
                  ),
                const SizedBox(height: 28),

                // Bottom Actions: Reset (secondary) + Apply Filters (primary)
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: () {
                          provider.clearTypeFilters();
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
