import 'package:flutter/material.dart';
import '../models/journal_prompt.dart';

/// Card presenting a daily reflection prompt with visual hierarchy and progressive disclosure.
class PromptCard extends StatelessWidget {
  final JournalPrompt prompt;
  final String language;
  final VoidCallback onUsePrompt;
  final VoidCallback onNextPrompt;
  final bool isCompleted;
  final VoidCallback? onViewEntry;

  const PromptCard({
    super.key,
    required this.prompt,
    required this.language,
    required this.onUsePrompt,
    required this.onNextPrompt,
    this.isCompleted = false,
    this.onViewEntry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTl = language == 'tl';

    // Progressive disclosure: Compact card when prompt has already been answered today
    if (isCompleted) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.secondary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 18,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            Text(
              isTl ? 'Pagninilay: Nasagutan na ngayong araw' : 'Daily Reflection • Completed today',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.secondary,
              ),
            ),
            const Spacer(),
            if (onViewEntry != null)
              TextButton(
                onPressed: onViewEntry,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isTl ? 'Tingnan' : 'View',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_rounded, size: 14),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    // Default prominent reflection prompt card
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Supporting Header Row
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 16,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                isTl ? 'Arawang Pagninilay' : 'Daily Reflection',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const Spacer(),
              Semantics(
                label: isTl ? 'Ibang tanong' : 'Try another prompt',
                button: true,
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  tooltip: isTl ? 'Ibang tanong' : 'Try another prompt',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onNextPrompt,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Primary Question (The strongest visual text on the card)
          Text(
            prompt.localizedText(language),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.3,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),

          // Action row
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onUsePrompt,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isTl ? 'Sagutin' : 'Answer',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
