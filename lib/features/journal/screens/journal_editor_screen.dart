import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../lessons/providers/lesson_provider.dart';
import '../../mood/models/mood_type.dart';
import '../../mood/state/mood_provider.dart';
import '../models/journal_entry.dart';
import '../models/journal_prompt.dart';
import '../providers/journal_provider.dart';
import '../services/journal_prompt_service.dart';
import '../services/journal_service.dart';
import '../services/speech_service.dart';
import '../widgets/journal_mood_selector.dart';
import '../widgets/prompt_selector.dart';
import '../widgets/tag_selector.dart';
import '../widgets/voice_input_button.dart';

class JournalEditorScreen extends StatefulWidget {
  final JournalEntry? existingEntry;
  final DateTime? initialDate;
  final MoodType? initialMood;
  final JournalPrompt? initialPrompt;
  final bool startWithVoice;

  const JournalEditorScreen({
    super.key,
    this.existingEntry,
    this.initialDate,
    this.initialMood,
    this.initialPrompt,
    this.startWithVoice = false,
  });

  @override
  State<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends State<JournalEditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final SpeechService _speechService = SpeechService();

  late DateTime _selectedDate;
  MoodType? _selectedMood;
  JournalPrompt? _selectedPrompt;
  List<String> _selectedTags = [];

  bool _isVoiceUsed = false;
  bool _isTypingUsed = false;
  Timer? _draftDebounce;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _selectedDate = widget.existingEntry?.date ??
        widget.initialDate ??
        DateTime.now();

    _selectedMood = widget.existingEntry?.mood ?? widget.initialMood;
    _selectedTags = widget.existingEntry != null
        ? List.from(widget.existingEntry!.tags)
        : [];

    if (widget.existingEntry != null) {
      _titleController.text = widget.existingEntry!.title ?? '';
      _contentController.text = widget.existingEntry!.content;
    }

    _selectedPrompt = widget.initialPrompt;

    _contentController.addListener(_onContentChanged);
    _titleController.addListener(_onContentChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initEditor();
    });
  }

  Future<void> _initEditor() async {
    // Check if on this date a mood was logged in MoodTracker
    if (_selectedMood == null && widget.existingEntry == null) {
      final moodProvider = Provider.of<MoodProvider?>(context, listen: false);
      if (moodProvider != null) {
        final dateEntry = moodProvider.monthEntries.where((e) {
          return e.date.year == _selectedDate.year &&
              e.date.month == _selectedDate.month &&
              e.date.day == _selectedDate.day;
        }).toList();
        if (dateEntry.isNotEmpty) {
          setState(() {
            _selectedMood = dateEntry.first.mood;
          });
        }
      }
    }

    // Check for unfinished draft (only if creating a new entry)
    if (widget.existingEntry == null) {
      final journalProvider =
          Provider.of<JournalProvider?>(context, listen: false);
      final draft = journalProvider?.savedDraft;
      if (draft != null && !draft.isEmpty && mounted) {
        _promptRestoreDraft(draft);
      }
    }

    // Initialize speech service
    await _speechService.initialize();

    // If user tapped "Speak" on the previous screen, the microphone option is ready and highlighted,
    // but per requirement #3: "Do not automatically start recording without an explicit tap."
    if (widget.startWithVoice && mounted) {
      setState(() {
        _isVoiceUsed = true;
      });
    }
  }

  void _promptRestoreDraft(JournalDraft draft) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Continue Unfinished Entry?'),
        content: const Text(
          'You have a saved draft from an earlier session. Would you like to continue editing it or discard it?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<JournalProvider>().discardDraft();
              Navigator.of(ctx).pop();
            },
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _titleController.text = draft.title;
                _contentController.text = draft.content;
                if (draft.moodId != null) {
                  try {
                    _selectedMood =
                        MoodType.values.firstWhere((m) => m.name == draft.moodId);
                  } catch (_) {}
                }
                if (draft.promptId != null) {
                  _selectedPrompt =
                      JournalPromptService().getPromptById(draft.promptId!);
                }
                _selectedTags = List.from(draft.tags);
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _onContentChanged() {
    _isTypingUsed = true;
    // Debounce draft autosave by 1.5 seconds
    _draftDebounce?.cancel();
    _draftDebounce = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted || widget.existingEntry != null) return;
      final provider = Provider.of<JournalProvider?>(context, listen: false);
      if (provider != null) {
        final draft = JournalDraft(
          title: _titleController.text,
          content: _contentController.text,
          moodId: _selectedMood?.name,
          promptId: _selectedPrompt?.id,
          tags: _selectedTags,
          updatedAt: DateTime.now(),
        );
        provider.saveDraft(draft);
      }
    });
  }

  void _toggleSpeech() {
    if (_speechService.isListening) {
      _speechService.stopListening();
    } else {
      _isVoiceUsed = true;
      final existingText = _contentController.text;
      final lessonProvider = Provider.of<LessonProvider?>(context, listen: false);
      final currentLang = lessonProvider?.currentLanguage ?? 'en';
      final langCode = currentLang == 'tl' ? 'fil' : 'en';

      _speechService.startListening(
        languageCode: langCode,
        onResult: (spokenWords) {
          if (!mounted) return;
          final separator = existingText.isEmpty || existingText.endsWith(' ')
              ? ''
              : ' ';
          _contentController.text = '$existingText$separator$spokenWords';
          _contentController.selection = TextSelection.fromPosition(
            TextPosition(offset: _contentController.text.length),
          );
        },
      );
    }
  }

  String _computeInputMethod() {
    if (_isVoiceUsed && _isTypingUsed) return 'mixed';
    if (_isVoiceUsed) return 'voice';
    return widget.existingEntry?.inputMethod ?? 'typed';
  }

  Future<void> _saveEntry() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write or speak a thought before saving.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    _draftDebounce?.cancel();

    if (_speechService.isListening) {
      await _speechService.stopListening();
    }
    if (!mounted) return;

    final provider = context.read<JournalProvider>();
    final title = _titleController.text.trim();
    final now = DateTime.now();

    final entry = JournalEntry(
      id: widget.existingEntry?.id ??
          'entry_${now.millisecondsSinceEpoch}',
      userId: widget.existingEntry?.userId ?? 'local_user',
      date: _selectedDate,
      title: title.isEmpty ? null : title,
      content: content,
      moodId: _selectedMood?.name,
      tags: _selectedTags,
      createdAt: widget.existingEntry?.createdAt ?? now,
      updatedAt: now,
      isFavorite: widget.existingEntry?.isFavorite ?? false,
      promptId: _selectedPrompt?.id,
      inputMethod: _computeInputMethod(),
    );

    final success = await provider.saveEntry(entry);
    if (!mounted) return;

    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Journal entry saved.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(entry);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("We couldn't save your entry. Please try again."),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _draftDebounce?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _speechService.cancelListening();
    _speechService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingEntry != null;
    final lessonProvider = Provider.of<LessonProvider?>(context);
    final currentLang = lessonProvider?.currentLanguage ?? 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Entry' : 'New Journal Entry',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.tonal(
              onPressed: _isSaving ? null : _saveEntry,
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date picker button
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Mood Selector Section
            Text(
              'How are you feeling?',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            JournalMoodSelector(
              selectedMood: _selectedMood,
              onMoodSelected: (m) => setState(() => _selectedMood = m),
            ),
            const SizedBox(height: 16),

            // Prompt Section
            if (_selectedPrompt != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer
                      .withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 20,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedPrompt!.localizedText(currentLang),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      tooltip: 'Remove prompt',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _selectedPrompt = null),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ] else ...[
              OutlinedButton.icon(
                onPressed: () async {
                  final prompt = await PromptSelectorSheet.show(
                    context,
                    language: currentLang,
                    currentMoodId: _selectedMood?.name,
                  );
                  if (prompt != null) {
                    setState(() => _selectedPrompt = prompt);
                  }
                },
                icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                label: const Text('Add a Reflection Prompt'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Optional Title Field
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Title (optional)',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),

            // Content Text Field (Large touch area)
            TextField(
              controller: _contentController,
              minLines: 8,
              maxLines: null,
              decoration: InputDecoration(
                hintText: "Write anything that's on your mind...",
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 18),

            // Voice input button section
            Center(
              child: AnimatedBuilder(
                animation: _speechService,
                builder: (context, _) {
                  return VoiceInputButton(
                    speechService: _speechService,
                    onPressed: _toggleSpeech,
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Tags selector
            Text(
              'Tags',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Consumer<JournalProvider>(
              builder: (context, journalProvider, _) {
                return TagSelector(
                  availableTags: journalProvider.availableTags,
                  selectedTags: _selectedTags,
                  onTagsChanged: (tags) => setState(() => _selectedTags = tags),
                  onAddCustomTag: (tag) => journalProvider.addCustomTag(tag),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
