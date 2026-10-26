import 'package:flutter/material.dart';

import '../models/journal_prompt.dart';
import '../services/journal_prompt_service.dart';

/// Modal bottom sheet allowing mothers to select from categorized prompts.
class PromptSelectorSheet extends StatefulWidget {
  final String language;
  final String? currentMoodId;
  final ValueChanged<JournalPrompt> onPromptSelected;

  const PromptSelectorSheet({
    super.key,
    required this.language,
    this.currentMoodId,
    required this.onPromptSelected,
  });

  static Future<JournalPrompt?> show(
    BuildContext context, {
    required String language,
    String? currentMoodId,
  }) {
    return showModalBottomSheet<JournalPrompt>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => PromptSelectorSheet(
        language: language,
        currentMoodId: currentMoodId,
        onPromptSelected: (p) => Navigator.of(ctx).pop(p),
      ),
    );
  }

  @override
  State<PromptSelectorSheet> createState() => _PromptSelectorSheetState();
}

class _PromptSelectorSheetState extends State<PromptSelectorSheet> {
  final JournalPromptService _service = JournalPromptService();
  String _selectedCategory = 'all';

  final List<String> _categories = [
    'all',
    'reflection',
    'gratitude',
    'self-care',
    'support',
    'bonding',
  ];

  String _categoryLabel(String cat) {
    if (widget.language == 'tl') {
      switch (cat) {
        case 'all':
          return 'Lahat';
        case 'reflection':
          return 'Pagninilay';
        case 'gratitude':
          return 'Pasasalamat';
        case 'self-care':
          return 'Pangangalaga';
        case 'support':
          return 'Suporta';
        case 'bonding':
          return 'Bonding';
        default:
          return cat;
      }
    }
    switch (cat) {
      case 'all':
        return 'All';
      case 'reflection':
        return 'Reflection';
      case 'gratitude':
        return 'Gratitude';
      case 'self-care':
        return 'Self-Care';
      case 'support':
        return 'Support';
      case 'bonding':
        return 'Bonding';
      default:
        return cat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTl = widget.language == 'tl';

    final prompts = _selectedCategory == 'all'
        ? _service.getAllPrompts()
        : _service.getPromptsByCategory(_selectedCategory);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                isTl
                    ? 'Pumili ng Mungkahing Tanong'
                    : 'Choose a Journal Prompt',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Category selector
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;

                  return ChoiceChip(
                    label: Text(_categoryLabel(cat)),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedCategory = cat);
                    },
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Prompt list
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: prompts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final p = prompts[index];
                  return Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                    child: InkWell(
                      onTap: () => widget.onPromptSelected(p),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_note_rounded,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                p.localizedText(widget.language),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
