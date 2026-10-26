import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../lessons/providers/lesson_provider.dart';
import '../../mood/models/mood_type.dart';
import '../../mood/state/mood_provider.dart';
import '../models/journal_prompt.dart';
import '../providers/journal_provider.dart';
import '../services/journal_prompt_service.dart';
import '../widgets/journal_calendar_sheet.dart';
import '../widgets/journal_empty_state.dart';
import '../widgets/journal_entry_card.dart';
import '../widgets/journal_filter_sheet.dart';
import '../widgets/prompt_card.dart';
import 'journal_detail_screen.dart';
import 'journal_editor_screen.dart';

/// Main screen for MomEase private journaling.
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  String? _pinError;
  int _promptIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final journalProvider = Provider.of<JournalProvider?>(
        context,
        listen: false,
      );
      if (journalProvider == null) return;
      final moodProvider = Provider.of<MoodProvider?>(context, listen: false);
      final currentMoodId = moodProvider?.selectedEntry?.mood.name;
      journalProvider.init(currentMoodId: currentMoodId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _openEditor({JournalPrompt? prompt, DateTime? initialDate}) async {
    final moodProvider = Provider.of<MoodProvider?>(context, listen: false);
    final todayMood = moodProvider?.selectedEntry?.mood;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JournalEditorScreen(
          initialPrompt: prompt,
          initialMood: todayMood,
          initialDate: initialDate,
        ),
      ),
    );
    if (mounted) {
      final journalProvider = Provider.of<JournalProvider?>(
        context,
        listen: false,
      );
      await journalProvider?.reloadEntries();
    }
  }

  void _showCalendarSheet(BuildContext context, JournalProvider provider) {
    JournalCalendarSheet.show(context, provider);
  }

  String _computeSectionTitle(JournalProvider provider) {
    if (provider.filterDate != null) {
      return 'Entries for ${DateFormat('MMMM d').format(provider.filterDate!)}';
    }
    if (provider.searchQuery.trim().isNotEmpty) {
      return 'Search Results';
    }
    if (provider.hasActiveTypeFilters) {
      return 'Filtered Entries';
    }
    return 'Recent Entries';
  }

  Widget _buildActiveFilterChips(
    BuildContext context,
    JournalProvider provider,
  ) {
    final chips = <Widget>[];
    final theme = Theme.of(context);

    // Date filter chip
    if (provider.filterDate != null) {
      chips.add(
        InputChip(
          avatar: const Icon(Icons.calendar_today_rounded, size: 14),
          label: Text(DateFormat('MMM d').format(provider.filterDate!)),
          deleteIcon: const Icon(Icons.close_rounded, size: 16),
          onDeleted: () => provider.setFilterDate(null),
          deleteIconColor: theme.colorScheme.primary,
        ),
      );
    }

    // Mood filter chip
    if (provider.filterMoodId != null) {
      final mood = MoodType.fromId(provider.filterMoodId);
      chips.add(
        InputChip(
          avatar: mood != null
              ? Image.asset(
                  mood.assetPath,
                  width: 14,
                  height: 14,
                  errorBuilder: (_, _, _) => const Icon(Icons.mood, size: 14),
                )
              : null,
          label: Text(mood?.label ?? provider.filterMoodId!),
          deleteIcon: const Icon(Icons.close_rounded, size: 16),
          onDeleted: () => provider.setFilterMood(null),
          deleteIconColor: mood?.color,
        ),
      );
    }

    // Tag filter chip
    if (provider.filterTag != null) {
      chips.add(
        InputChip(
          avatar: const Icon(Icons.tag_rounded, size: 14),
          label: Text('#${provider.filterTag}'),
          deleteIcon: const Icon(Icons.close_rounded, size: 16),
          onDeleted: () => provider.setFilterTag(null),
        ),
      );
    }

    // Favorites filter chip
    if (provider.onlyFavorites) {
      chips.add(
        InputChip(
          avatar: const Icon(
            Icons.star_rounded,
            size: 14,
            color: AppColors.favoriteStar,
          ),
          label: const Text('Favorites'),
          deleteIcon: const Icon(Icons.close_rounded, size: 16),
          onDeleted: () => provider.setFilterFavorites(false),
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ...chips,
          if (chips.length > 1)
            TextButton(
              onPressed: () => provider.clearFilters(),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Clear all', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildLockScreen(BuildContext context, JournalProvider provider) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.6,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Journal Locked',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your 4-digit PIN to access your private journal entries.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      letterSpacing: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••',
                      errorText: _pinError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onChanged: (val) async {
                      if (val.length == 4) {
                        final success = await provider.verifyAndUnlock(val);
                        if (!success) {
                          setState(() {
                            _pinError = 'Incorrect PIN. Please try again.';
                            _pinController.clear();
                          });
                        } else {
                          setState(() {
                            _pinError = null;
                            _pinController.clear();
                          });
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () async {
                    final pin = _pinController.text.trim();
                    if (pin.length < 4) {
                      setState(() => _pinError = 'Please enter all 4 digits');
                      return;
                    }
                    final success = await provider.verifyAndUnlock(pin);
                    if (!success) {
                      setState(() {
                        _pinError = 'Incorrect PIN. Please try again.';
                        _pinController.clear();
                      });
                    } else {
                      setState(() {
                        _pinError = null;
                        _pinController.clear();
                      });
                    }
                  },
                  icon: const Icon(Icons.lock_open_rounded),
                  label: const Text('Unlock Journal'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<JournalProvider?>(context);
    if (provider == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final lessonProvider = Provider.of<LessonProvider?>(context);
    final currentLang = lessonProvider?.currentLanguage ?? 'en';

    // If Journal Lock is active, show lock screen
    if (provider.isLocked) {
      return _buildLockScreen(context, provider);
    }

    final entries = provider.filteredEntries;
    final draft = provider.savedDraft;

    // Daily prompt logic with progressive disclosure
    final allPrompts = JournalPromptService().getAllPrompts();
    final activePrompt = _promptIndex == 0
        ? (provider.featuredPrompt ?? allPrompts.first)
        : allPrompts[_promptIndex % allPrompts.length];
    final isPromptAnswered = provider.hasAnsweredPrompt(activePrompt.id);
    final answeredEntry = isPromptAnswered
        ? provider.getEntryForPrompt(activePrompt.id)
        : null;

    final sectionTitle = _computeSectionTitle(provider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => provider.reloadEntries(),
          child: CustomScrollView(
            slivers: [
              // Header & Controls Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Journal',
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'A private space for your thoughts and moments.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Optional Lock icon if lock is enabled
                          if (provider.isLockEnabled)
                            IconButton(
                              tooltip: 'Lock Journal',
                              icon: const Icon(Icons.lock_outline_rounded),
                              onPressed: () => provider.lock(),
                            ),
                          // Calendar filter button
                          Semantics(
                            label: 'Browse journal by date',
                            button: true,
                            child: IconButton(
                              tooltip: 'Browse journal by date',
                              icon: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    provider.filterDate != null
                                        ? Icons.calendar_month_rounded
                                        : Icons.calendar_month_outlined,
                                    color: provider.filterDate != null
                                        ? theme.colorScheme.primary
                                        : null,
                                  ),
                                  if (provider.filterDate != null)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              onPressed: () =>
                                  _showCalendarSheet(context, provider),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Unfinished draft banner
                      if (draft != null && !draft.isEmpty)
                        Card(
                          elevation: 0,
                          color: theme.colorScheme.errorContainer.withValues(
                            alpha: 0.3,
                          ),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: theme.colorScheme.error.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_note_rounded,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Unfinished entry',
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.error,
                                            ),
                                      ),
                                      Text(
                                        draft.content.isNotEmpty
                                            ? draft.content
                                            : draft.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => provider.discardDraft(),
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    foregroundColor: theme.colorScheme.error,
                                  ),
                                  child: const Text('Discard'),
                                ),
                                FilledButton.tonal(
                                  onPressed: () => _openEditor(),
                                  style: FilledButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    minimumSize: const Size(0, 36),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                  ),
                                  child: const Text('Continue'),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Featured Daily Reflection Card (with Progressive Disclosure)
                      PromptCard(
                        prompt: activePrompt,
                        language: currentLang,
                        isCompleted: isPromptAnswered,
                        onUsePrompt: () => _openEditor(prompt: activePrompt),
                        onViewEntry: answeredEntry != null
                            ? () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => JournalDetailScreen(
                                      entry: answeredEntry,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        onNextPrompt: () {
                          setState(() {
                            _promptIndex++;
                          });
                        },
                      ),
                      const SizedBox(height: 10),

                      // Search field + Filter button
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => provider.setSearchQuery(val),
                              decoration: InputDecoration(
                                hintText: 'Search your journal...',
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear_rounded,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          provider.setSearchQuery('');
                                        },
                                      )
                                    : null,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                filled: true,
                                fillColor:
                                    theme.colorScheme.surfaceContainerLow,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.outlineVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.outlineVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Filter Button (with active filter count badge)
                          Semantics(
                            label: 'Filter journal entries',
                            button: true,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                IconButton.filledTonal(
                                  icon: const Icon(Icons.filter_list_rounded),
                                  tooltip: 'Filter journal entries',
                                  onPressed: () => JournalFilterSheet.show(
                                    context,
                                    provider,
                                  ),
                                ),
                                if (provider.hasActiveTypeFilters)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        '${provider.activeTypeFilterCount}',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onPrimary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Removable Active Filter Chips
                      _buildActiveFilterChips(context, provider),
                      const SizedBox(height: 12),

                      // Section Title & Counter Row
                      Row(
                        children: [
                          Text(
                            sectionTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (entries.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${entries.length}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Entries List or Empty State
              if (entries.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: JournalEmptyState(
                    filterDate: provider.filterDate,
                    onClearDateFilter: () => provider.setFilterDate(null),
                    onNewEntry: () =>
                        _openEditor(initialDate: provider.filterDate),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 84),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final entry = entries[index];
                      return JournalEntryCard(
                        entry: entry,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => JournalDetailScreen(entry: entry),
                            ),
                          );
                          if (mounted) {
                            provider.reloadEntries();
                          }
                        },
                        onFavoriteToggle: () {
                          provider.toggleFavorite(entry.id);
                        },
                      );
                    }, childCount: entries.length),
                  ),
                ),
            ],
          ),
        ),
      ),
      // Primary Action: Extended FAB for creating journal entry
      floatingActionButton: entries.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openEditor(initialDate: provider.filterDate),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'New Entry',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              tooltip: 'New Entry',
            ),
    );
  }
}
