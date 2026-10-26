import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../journal/screens/journal_editor_screen.dart';
import '../models/mood_type.dart';
import '../state/mood_provider.dart';

Future<void> showLogMoodSheet(BuildContext context,
    {MoodType? preselected}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _LogMoodSheet(preselected: preselected),
  );
}

class _LogMoodSheet extends StatefulWidget {
  const _LogMoodSheet({this.preselected});
  final MoodType? preselected;

  @override
  State<_LogMoodSheet> createState() => _LogMoodSheetState();
}

class _LogMoodSheetState extends State<_LogMoodSheet> {
  MoodType? _selected;
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.preselected;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selected == null) return;
    setState(() => _saving = true);
    final provider = context.read<MoodProvider>();
    final err = await provider.saveMoodForSelectedDate(
      _selected!,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);

    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    final savedMood = _selected;
    final selectedDate = provider.selectedDate;

    navigator.pop();

    if (err == null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Mood saved.'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 2500),
          showCloseIcon: true,
          dismissDirection: DismissDirection.horizontal,
          action: SnackBarAction(
            label: 'Write',
            onPressed: () {
              messenger.hideCurrentSnackBar();
              navigator.push(
                MaterialPageRoute(
                  builder: (_) => JournalEditorScreen(
                    initialDate: selectedDate,
                    initialMood: savedMood,
                  ),
                ),
              );
            },
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'How are you feeling?',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Take a moment to check in with yourself.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // Mood options row
            Row(
              children: MoodType.values.map((m) {
                final isSelected = _selected == m;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selected = m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? m.color.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? Border.all(color: m.color, width: 2)
                            : Border.all(
                                color: Colors.transparent, width: 2),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            m.assetPath,
                            width: 42,
                            height: 42,
                            errorBuilder: (_, e, s) => Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: m.color.withValues(alpha: 0.3),
                              ),
                              child: Icon(Icons.sentiment_neutral,
                                  color: m.color, size: 26),
                            ),
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              m.label,
                              maxLines: 1,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isSelected
                                    ? m.color
                                    : theme.colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : null,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Note field
            TextField(
              controller: _noteController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Add a note (optional)...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: theme.colorScheme.outlineVariant),
                ),
                filled: true,
                fillColor:
                    theme.colorScheme.surfaceContainerLowest,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed:
                  _selected == null || _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Mood',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
