import 'package:flutter/material.dart';

/// Pill-style language toggle for switching between English (EN) and Tagalog (TL).
class LanguageToggle extends StatelessWidget {
  final String currentLanguage;
  final ValueChanged<String> onLanguageChanged;
  final bool compact;

  const LanguageToggle({
    super.key,
    required this.currentLanguage,
    required this.onLanguageChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEn = currentLanguage == 'en';

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleOption(
            label: compact ? 'EN' : 'English',
            isSelected: isEn,
            onTap: () => onLanguageChanged('en'),
          ),
          _ToggleOption(
            label: compact ? 'TL' : 'Tagalog',
            isSelected: !isEn,
            onTap: () => onLanguageChanged('tl'),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
