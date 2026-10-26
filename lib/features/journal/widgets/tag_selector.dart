import 'package:flutter/material.dart';

/// Tag selector allowing mothers to pick built-in postpartum tags or add custom tags.
class TagSelector extends StatelessWidget {
  final List<String> availableTags;
  final List<String> selectedTags;
  final ValueChanged<List<String>> onTagsChanged;
  final ValueChanged<String> onAddCustomTag;

  const TagSelector({
    super.key,
    required this.availableTags,
    required this.selectedTags,
    required this.onTagsChanged,
    required this.onAddCustomTag,
  });

  void _showAddTagDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Tag'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Doctor visit, First smile',
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                onAddCustomTag(text);
                if (!selectedTags.contains(text)) {
                  onTagsChanged([...selectedTags, text]);
                }
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        ...availableTags.map((tag) {
          final isSelected = selectedTags.contains(tag);
          return FilterChip(
            label: Text('#$tag'),
            selected: isSelected,
            onSelected: (selected) {
              final updated = List<String>.from(selectedTags);
              if (selected) {
                updated.add(tag);
              } else {
                updated.remove(tag);
              }
              onTagsChanged(updated);
            },
            backgroundColor: theme.colorScheme.surfaceContainerLow,
            selectedColor: theme.colorScheme.primaryContainer,
            labelStyle: theme.textTheme.labelMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          );
        }),
        ActionChip(
          avatar: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Custom Tag'),
          onPressed: () => _showAddTagDialog(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }
}
