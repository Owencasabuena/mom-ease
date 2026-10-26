import 'package:flutter/material.dart';

import '../models/journal_prompt.dart';

/// Card presenting a daily reflection prompt with visual hierarchy and progressive disclosure.
class PromptCard extends StatelessWidget {
  final JournalPrompt prompt;
  final String language;
  final VoidCallback onUsePrompt;
  final VoidCallback? onNextPrompt;
  final bool isCompleted;
  final VoidCallback? onViewEntry;

  const PromptCard({
    super.key,
    required this.prompt,
    required this.language,
    required this.onUsePrompt,
    this.onNextPrompt,
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.secondary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 16,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isTl
                    ? 'Pagninilay: Nasagutan na ngayong araw'
                    : 'Daily Reflection • Completed today',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.secondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onViewEntry != null) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: onViewEntry,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isTl ? 'Tingnan' : 'View',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: theme.colorScheme.secondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Default compact reflection prompt card
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onUsePrompt,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 14,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isTl ? 'Arawang Pagninilay' : 'Daily Reflection',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                        color: theme.colorScheme.secondary,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    if (onNextPrompt != null) ...[
                      Semantics(
                        label: isTl ? 'Ibang tanong' : 'Try another prompt',
                        button: true,
                        child: IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          tooltip: isTl ? 'Ibang tanong' : 'Try another prompt',
                          padding: const EdgeInsets.all(2),
                          constraints: const BoxConstraints(),
                          onPressed: onNextPrompt,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isTl ? 'Sagutin' : 'Answer',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  prompt.localizedText(language),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
