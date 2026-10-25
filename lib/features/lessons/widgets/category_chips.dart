import 'package:flutter/material.dart';

class CategoryItem {
  final String id;
  final String labelEn;
  final String labelTl;
  final IconData? icon;

  const CategoryItem({
    required this.id,
    required this.labelEn,
    required this.labelTl,
    this.icon,
  });

  String label(String lang) => lang == 'tl' ? labelTl : labelEn;
}

const List<CategoryItem> kLessonCategories = [
  CategoryItem(
    id: 'all',
    labelEn: 'All',
    labelTl: 'Lahat',
    icon: Icons.grid_view_rounded,
  ),
  CategoryItem(
    id: 'saved',
    labelEn: 'Saved',
    labelTl: 'Nai-save',
    icon: Icons.bookmark_rounded,
  ),
  CategoryItem(
    id: 'self-care',
    labelEn: 'Self-Care',
    labelTl: 'Pangangalaga',
    icon: Icons.spa_rounded,
  ),
  CategoryItem(
    id: 'recovery',
    labelEn: 'Recovery',
    labelTl: 'Pagpapagaling',
    icon: Icons.healing_rounded,
  ),
  CategoryItem(
    id: 'mental-health',
    labelEn: 'Mental Health',
    labelTl: 'Kalusugan ng Pag-iisip',
    icon: Icons.favorite_border_rounded,
  ),
  CategoryItem(
    id: 'physical-health',
    labelEn: 'Physical Health',
    labelTl: 'Kalusugan ng Katawan',
    icon: Icons.directions_walk_rounded,
  ),
  CategoryItem(
    id: 'mother-and-baby',
    labelEn: 'Mother & Baby',
    labelTl: 'Nanay at Sanggol',
    icon: Icons.child_care_rounded,
  ),
];

class CategoryChips extends StatelessWidget {
  final String selectedCategory;
  final String currentLanguage;
  final ValueChanged<String> onSelected;

  const CategoryChips({
    super.key,
    required this.selectedCategory,
    required this.currentLanguage,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: kLessonCategories.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = kLessonCategories[index];
          final isSelected = selectedCategory.toLowerCase() == item.id.toLowerCase();

          return FilterChip(
            selected: isSelected,
            showCheckmark: false,
            avatar: item.icon != null
                ? Icon(
                    item.icon,
                    size: 16,
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  )
                : null,
            label: Text(item.label(currentLanguage)),
            labelStyle: theme.textTheme.labelMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
            backgroundColor: theme.colorScheme.surfaceContainerLow,
            selectedColor: theme.colorScheme.primaryContainer,
            side: BorderSide(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            onSelected: (_) => onSelected(item.id),
          );
        },
      ),
    );
  }
}
