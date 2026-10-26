import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/services/auth_provider.dart';
import '../../../features/profile/screens/profile_screen.dart';
import '../../journal/screens/journal_editor_screen.dart';
import '../models/mood_type.dart';
import '../state/mood_provider.dart';
import '../widgets/calendar_view.dart';
import '../widgets/log_mood_bottom_sheet.dart';
import '../widgets/suggested_lesson_card.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MoodProvider>().init();
    });
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final mood = context.watch<MoodProvider>();
    final theme = Theme.of(context);
    final displayName = auth.currentUser?.displayName ?? 'there';
    final name = displayName.split(' ').first;
    final greeting = _greeting();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$greeting, $name',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profile & Settings',
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: RefreshIndicator(
        onRefresh: () => mood.init(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _DateHeader()),
            const SliverToBoxAdapter(child: CalendarView()),
            SliverToBoxAdapter(child: _SelectedDayCard()),
            SliverToBoxAdapter(child: _LogButton()),
            const SliverToBoxAdapter(child: SuggestedLessonCard()),
            if (mood.showSupportMessage)
              const SliverToBoxAdapter(child: _SupportBanner()),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mood = context.watch<MoodProvider>();
    final theme = Theme.of(context);
    final today = DateTime.now();
    final isToday =
        mood.selectedDate.year == today.year &&
        mood.selectedDate.month == today.month &&
        mood.selectedDate.day == today.day;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              DateFormat('EEEE, MMMM d').format(mood.selectedDate),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!isToday) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => mood.selectDate(today),
              icon: const Icon(Icons.today_rounded, size: 16),
              label: const Text('Today'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectedDayCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mood = context.watch<MoodProvider>();
    final theme = Theme.of(context);
    final entry = mood.selectedEntry;
    final today = DateTime.now();
    final isToday =
        mood.selectedDate.year == today.year &&
        mood.selectedDate.month == today.month &&
        mood.selectedDate.day == today.day;

    // Case 1: No mood logged yet for selected date
    if (entry == null) {
      final isFuture = mood.isFutureDate;
      if (isFuture) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'You can log your mood when this day arrives.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      // Warm, inviting prompt to check in
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.spa_rounded,
                size: 26,
                color: theme.colorScheme.primary.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 8),
              Text(
                isToday
                    ? 'How are you feeling today?'
                    : 'How were you feeling?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Take a gentle moment to check in with yourself.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Case 2: Mood logged (Today's Mood Hero Card)
    final entryMood = entry.mood;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 0,
        color: entryMood.color.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: entryMood.color.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(
                    entryMood.assetPath,
                    width: 52,
                    height: 52,
                    errorBuilder: (_, e, s) => Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: entryMood.color.withValues(alpha: 0.3),
                      ),
                      child: Icon(
                        Icons.sentiment_neutral,
                        color: entryMood.color,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isToday
                              ? "Today's mood"
                              : DateFormat('MMMM d').format(mood.selectedDate),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          entryMood.label,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: entryMood.color,
                          ),
                        ),
                        if (entry.note != null && entry.note!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            entry.note!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: entryMood.color.withValues(alpha: 0.2)),
              const SizedBox(height: 8),
              // Actions row: Update Mood (secondary button) + Add Journal Entry (tertiary link)
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () =>
                          showLogMoodSheet(context, preselected: entryMood),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Update Mood'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => JournalEditorScreen(
                              initialDate: mood.selectedDate,
                              initialMood: entryMood,
                            ),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.edit_note_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      label: const Text('Add Journal Entry'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: theme.colorScheme.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mood = context.watch<MoodProvider>();
    final isFuture = mood.isFutureDate;
    if (isFuture) return const SizedBox.shrink();

    // When mood is already logged, the update button is already cleanly integrated inside _SelectedDayCard
    if (mood.selectedEntry != null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: FilledButton.icon(
        onPressed: () =>
            showLogMoodSheet(context, preselected: mood.selectedEntry?.mood),
        icon: const Icon(Icons.add_reaction_outlined),
        label: const Text(
          'Log Your Mood',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _SupportBanner extends StatelessWidget {
  const _SupportBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              color: theme.colorScheme.tertiary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "It looks like you've been having a difficult few days. "
                'Consider reaching out to someone you trust or a healthcare '
                'professional if you need support.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
