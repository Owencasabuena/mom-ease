import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';

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

    _selectedDate =
        widget.existingEntry?.date ?? widget.initialDate ?? DateTime.now();

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
      final journalProvider = Provider.of<JournalProvider?>(
        context,
        listen: false,
      );
      final draft = journalProvider?.savedDraft;
      if (draft != null && !draft.isEmpty && mounted) {
        _promptRestoreDraft(draft);
      }
    }

    // Initialize speech service
    await _speechService.initialize();

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
                    _selectedMood = MoodType.values.firstWhere(
                      (m) => m.name == draft.moodId,
                    );
                  } catch (_) {}
                }
                if (draft.promptId != null) {
                  _selectedPrompt = JournalPromptService().getPromptById(
                    draft.promptId!,
                  );
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
    setState(() {}); // Updates Save button state reactively

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
      final lessonProvider = Provider.of<LessonProvider?>(
        context,
        listen: false,
      );
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
    if (content.isEmpty) return;

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
      id: widget.existingEntry?.id ?? 'entry_${now.millisecondsSinceEpoch}',
      userId: widget.existingEntry?.userId ?? provider.userId,
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

  void _saveDraftNow() {
    _draftDebounce?.cancel();
    if (widget.existingEntry != null) return;
    final content = _contentController.text.trim();
    final title = _titleController.text.trim();
    if (content.isEmpty && title.isEmpty) return;

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
  }

  @override
  void dispose() {
    _draftDebounce?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _speechService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingEntry != null;
    final lessonProvider = Provider.of<LessonProvider?>(context);
    final currentLang = lessonProvider?.currentLanguage ?? 'en';
    final hasContent = _contentController.text.trim().isNotEmpty;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _saveDraftNow();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back',
            onPressed: () {
              _saveDraftNow();
              Navigator.of(context).maybePop();
            },
          ),
          title: Text(
            isEditing ? 'Edit Entry' : 'New Journal Entry',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Semantics(
                label: 'Save journal entry',
                button: true,
                child: FilledButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                          if (!hasContent) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please write your thoughts before saving.',
                                ),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          _saveEntry();
                        },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(64, 38),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
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
              // Date row
              InkWell(
                onTap: isEditing
                    ? null
                    : () async {
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
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 15,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!isEditing) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Mood Selector Section
              Text(
                'How are you feeling?',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              JournalMoodSelector(
                selectedMood: _selectedMood,
                onMoodSelected: (m) => setState(() => _selectedMood = m),
              ),
              const SizedBox(height: 16),

              // Reflection Prompt Section (Secondary action, prominent question)
              if (_selectedPrompt != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withValues(
                      alpha: 0.35,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 16,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Reflection Prompt',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () async {
                              final p = await PromptSelectorSheet.show(
                                context,
                                language: currentLang,
                                currentMoodId: _selectedMood?.name,
                              );
                              if (p != null) {
                                setState(() => _selectedPrompt = p);
                              }
                            },
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            child: const Text('Change'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            tooltip: 'Remove prompt',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () =>
                                setState(() => _selectedPrompt = null),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedPrompt!.localizedText(currentLang),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
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
                  icon: const Icon(Icons.lightbulb_outline_rounded, size: 16),
                  label: const Text('+ Add a Reflection Prompt'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
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
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.6,
                    ),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 14),

              // Large Journal Text Field with integrated microphone control
              AnimatedBuilder(
                animation: _speechService,
                builder: (context, _) {
                  final isListening = _speechService.isListening;
                  final isProcessing =
                      _speechService.status == SpeechStatus.processing;

                  return Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isListening
                            ? theme.colorScheme.error
                            : theme.colorScheme.outlineVariant.withValues(
                                alpha: 0.4,
                              ),
                        width: isListening ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _contentController,
                          minLines: 8,
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: "Write anything that's on your mind...",
                            hintStyle: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.fromLTRB(
                              16,
                              16,
                              16,
                              8,
                            ),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        // Bottom bar inside editor for mic / speech status
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                          child: Row(
                            children: [
                              if (isListening) ...[
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Listening...',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Semantics(
                                  label: 'Stop voice input',
                                  button: true,
                                  child: IconButton.filled(
                                    onPressed: _toggleSpeech,
                                    style: IconButton.styleFrom(
                                      backgroundColor: theme.colorScheme.error,
                                      foregroundColor:
                                          theme.colorScheme.onError,
                                      minimumSize: const Size(40, 40),
                                    ),
                                    icon: const Icon(
                                      Icons.stop_rounded,
                                      size: 20,
                                    ),
                                    tooltip: 'Stop voice input',
                                  ),
                                ),
                              ] else if (isProcessing) ...[
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Finishing transcription...',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const Spacer(),
                              ] else if (_speechService.status ==
                                  SpeechStatus.permissionDenied) ...[
                                Icon(
                                  Icons.mic_off_rounded,
                                  size: 16,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Microphone permission needed',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                const Spacer(),
                                Semantics(
                                  label: 'Start voice input',
                                  button: true,
                                  child: IconButton.filledTonal(
                                    onPressed: _toggleSpeech,
                                    style: IconButton.styleFrom(
                                      minimumSize: const Size(40, 40),
                                    ),
                                    icon: const Icon(
                                      Icons.mic_rounded,
                                      size: 20,
                                    ),
                                    tooltip: 'Start voice input',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
                    onTagsChanged: (tags) =>
                        setState(() => _selectedTags = tags),
                    onAddCustomTag: (tag) => journalProvider.addCustomTag(tag),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
