import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../features/auth/services/auth_provider.dart';
import '../../../features/profile/screens/profile_screen.dart';
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
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profile & Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
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
    final isToday = mood.selectedDate.year == today.year &&
        mood.selectedDate.month == today.month &&
        mood.selectedDate.day == today.day;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        isToday
            ? 'Today, ${DateFormat('d MMMM yyyy').format(today)}'
            : DateFormat('EEEE, d MMMM yyyy').format(mood.selectedDate),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
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

    if (entry == null) {
      final isFuture = mood.isFutureDate;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            isFuture
                ? 'You can log your mood when this day arrives.'
                : 'No mood logged yet.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final entryMood = entry.mood;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 0,
        color: entryMood.color.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: entryMood.color.withValues(alpha: 0.4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
                  child: Icon(Icons.sentiment_neutral,
                      color: entryMood.color, size: 32),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your mood',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                    Text(entryMood.label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                    if (entry.note != null && entry.note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(entry.note!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FilledButton.icon(
        onPressed: isFuture
            ? null
            : () => showLogMoodSheet(context,
                preselected: mood.selectedEntry?.mood),
        icon: const Icon(Icons.add_reaction_outlined),
        label: Text(
          mood.selectedEntry == null ? 'Log Your Mood' : 'Update Mood',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              color: theme.colorScheme.tertiary.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.favorite_border_rounded,
                color: theme.colorScheme.tertiary, size: 22),
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
