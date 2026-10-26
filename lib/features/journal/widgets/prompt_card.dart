import 'package:flutter/material.dart';
import '../models/journal_prompt.dart';

/// Card presenting an inspiring daily journaling prompt.
class PromptCard extends StatelessWidget {
  final JournalPrompt prompt;
  final String language;
  final VoidCallback onUsePrompt;
  final VoidCallback onNextPrompt;

  const PromptCard({
    super.key,
    required this.prompt,
    required this.language,
    required this.onUsePrompt,
    required this.onNextPrompt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTl = language == 'tl';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
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
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 20,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                isTl ? 'Mungkahing Tanong' : 'Daily Prompt',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                tooltip: isTl ? 'Ibang tanong' : 'Try another prompt',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onNextPrompt,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            prompt.localizedText(language),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onUsePrompt,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text(isTl ? 'Sagutin' : 'Answer Prompt'),
            ),
          ),
        ],
      ),
    );
  }
}
