import 'package:flutter/material.dart';
import '../../mood/models/mood_type.dart';

/// Horizontal mood selector allowing mothers to optionally tag a journal entry with a mood.
class JournalMoodSelector extends StatelessWidget {
  final MoodType? selectedMood;
  final ValueChanged<MoodType?> onMoodSelected;

  const JournalMoodSelector({
    super.key,
    required this.selectedMood,
    required this.onMoodSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 76,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "No Mood" chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onMoodSelected(null),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 64,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: selectedMood == null
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selectedMood == null
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.block_rounded,
                      size: 22,
                      color: selectedMood == null
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'None',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: selectedMood == null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 5 Mood types
          ...MoodType.values.map((mood) {
            final isSelected = selectedMood == mood;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => onMoodSelected(mood),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 64,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? mood.color.withValues(alpha: 0.18)
                        : theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? mood.color
                          : theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.4),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        mood.assetPath,
                        width: 24,
                        height: 24,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.sentiment_satisfied_rounded,
                          size: 24,
                          color: mood.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mood.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? mood.color
                              : theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
