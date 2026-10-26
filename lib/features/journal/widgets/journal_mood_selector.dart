import 'package:flutter/material.dart';
import '../../mood/models/mood_type.dart';

/// Horizontal mood selector allowing mothers to optionally tag a journal entry with a mood.
/// Shows compact emoji-only icons without checkmarks or text clutter.
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
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          // "None" option
          _buildOption(
            context: context,
            isSelected: selectedMood == null,
            label: 'None',
            iconWidget: Icon(
              Icons.block_rounded,
              size: 22,
              color: selectedMood == null
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
            accentColor: theme.colorScheme.primary,
            onTap: () => onMoodSelected(null),
          ),
          const SizedBox(width: 8),

          // 5 Mood options
          ...MoodType.values.map((mood) {
            final isSelected = selectedMood == mood;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildOption(
                context: context,
                isSelected: isSelected,
                label: mood.label,
                iconWidget: Image.asset(
                  mood.assetPath,
                  width: 28,
                  height: 28,
                  errorBuilder: (context, error, stackTrace) => Text(
                    mood.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                accentColor: mood.color,
                onTap: () => onMoodSelected(isSelected ? null : mood),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required bool isSelected,
    required String label,
    required Widget iconWidget,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: isSelected,
        label: 'Mood $label',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.2)
                  : theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? accentColor
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: iconWidget,
            ),
          ),
        ),
      ),
    );
  }
}
