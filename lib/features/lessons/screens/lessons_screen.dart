import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../mood/state/mood_provider.dart';
import '../models/lesson.dart';
import '../providers/lesson_provider.dart';
import '../widgets/category_chips.dart';
import '../widgets/featured_lesson_card.dart';
import '../widgets/language_toggle.dart';
import '../widgets/lesson_card.dart';
import 'lesson_detail_screen.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final lessonProvider =
          Provider.of<LessonProvider?>(context, listen: false);
      if (lessonProvider == null) return;

      final moodProvider = Provider.of<MoodProvider?>(context, listen: false);
      final recentMood = moodProvider?.selectedEntry?.mood.name ??
          (moodProvider != null && moodProvider.monthEntries.isNotEmpty
              ? moodProvider.monthEntries.last.mood.name
              : null);
      lessonProvider.init(moodId: recentMood);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openLesson(Lesson lesson) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LessonDetailScreen(lesson: lesson),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lessonProvider = Provider.of<LessonProvider?>(context);
    if (lessonProvider == null) {
      return const Scaffold(
        body: SizedBox.shrink(),
      );
    }

    final theme = Theme.of(context);
    final lang = lessonProvider.currentLanguage;
    final isTl = lang == 'tl';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isTl ? 'Matuto at Mag-alaga' : 'Learn & Care',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: LanguageToggle(
              currentLanguage: lang,
              compact: true,
              onLanguageChanged: (newLang) {
                lessonProvider.setLanguage(newLang);
              },
            ),
          ),
        ],
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final moodProvider = context.read<MoodProvider>();
          final recentMood = moodProvider.selectedEntry?.mood.name ??
              (moodProvider.monthEntries.isNotEmpty
                  ? moodProvider.monthEntries.last.mood.name
                  : null);
          await lessonProvider.init(moodId: recentMood);
        },
        child: CustomScrollView(
          slivers: [
            // Subheading
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  isTl
                      ? 'Munting mga aralin para sa iyo at sa iyong postpartum journey.'
                      : 'Small lessons for you and your postpartum journey.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SearchBar(
                  controller: _searchController,
                  hintText: isTl ? 'Maghanap ng aralin...' : 'Search lessons...',
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.search_rounded),
                  ),
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          lessonProvider.setSearchQuery('');
                        },
                      ),
                  ],
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStatePropertyAll(
                    theme.colorScheme.surfaceContainerLow,
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  onChanged: (val) => lessonProvider.setSearchQuery(val),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Category Chips
            SliverToBoxAdapter(
              child: CategoryChips(
                selectedCategory: lessonProvider.selectedCategory,
                currentLanguage: lang,
                onSelected: (cat) => lessonProvider.setCategory(cat),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Content Loading State
            if (lessonProvider.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            // Error State
            else if (lessonProvider.errorMessage != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 48,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          lessonProvider.errorMessage!,
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => lessonProvider.init(),
                          child: Text(isTl ? 'Subukang muli' : 'Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              // Featured Recommendation (Only when in 'all' and not actively searching)
              if (lessonProvider.selectedCategory == 'all' &&
                  lessonProvider.searchQuery.isEmpty &&
                  lessonProvider.recommendedLesson != null)
                SliverToBoxAdapter(
                  child: FeaturedLessonCard(
                    lesson: lessonProvider.recommendedLesson!,
                    language: lang,
                    onTap: () => _openLesson(lessonProvider.recommendedLesson!),
                  ),
                ),

              // Continue Learning Section (if user opened a lesson and hasn't completed it)
              if (lessonProvider.selectedCategory == 'all' &&
                  lessonProvider.searchQuery.isEmpty &&
                  lessonProvider.continueLearningLesson != null &&
                  lessonProvider.continueLearningLesson?.id !=
                      lessonProvider.recommendedLesson?.id) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.play_circle_outline_rounded,
                          size: 18,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isTl
                              ? 'Ipagpatuloy ang Pag-aaral'
                              : 'Continue Learning',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: LessonCard(
                    lesson: lessonProvider.continueLearningLesson!,
                    language: lang,
                    isBookmarked: lessonProvider.bookmarkedIds
                        .contains(lessonProvider.continueLearningLesson!.id),
                    isCompleted: lessonProvider.completedIds
                        .contains(lessonProvider.continueLearningLesson!.id),
                    onTap: () =>
                        _openLesson(lessonProvider.continueLearningLesson!),
                    onToggleBookmark: () => lessonProvider.toggleBookmark(
                        lessonProvider.continueLearningLesson!.id),
                  ),
                ),
              ],

              // Section Header: "All Lessons" or Category / Results Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                  child: Text(
                    lessonProvider.searchQuery.isNotEmpty
                        ? (isTl
                            ? 'Mga Resulta ng Paghahanap'
                            : 'Search Results')
                        : lessonProvider.selectedCategory == 'saved'
                            ? (isTl
                                ? 'Mga Nai-save na Aralin'
                                : 'Saved Lessons')
                            : (isTl ? 'Lahat ng Aralin' : 'All Lessons'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),

              // Empty list state for searches or saved filter
              if (lessonProvider.filteredLessons.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            lessonProvider.selectedCategory == 'saved'
                                ? Icons.bookmark_border_rounded
                                : Icons.search_off_rounded,
                            size: 48,
                            color: theme.colorScheme.outlineVariant,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            lessonProvider.selectedCategory == 'saved'
                                ? (isTl
                                    ? 'Wala pang nai-save na aralin.\nPindutin ang bookmark icon sa anumang aralin para i-save ito.'
                                    : 'No saved lessons yet.\nTap the bookmark icon on any lesson to save it for later.')
                                : (isTl
                                    ? 'Walang nahanap na aralin para sa "${lessonProvider.searchQuery}".'
                                    : 'No lessons found for "${lessonProvider.searchQuery}".'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                // List of filtered lessons
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final lesson = lessonProvider.filteredLessons[index];
                      final isBookmarked =
                          lessonProvider.bookmarkedIds.contains(lesson.id);
                      final isCompleted =
                          lessonProvider.completedIds.contains(lesson.id);

                      return LessonCard(
                        lesson: lesson,
                        language: lang,
                        isBookmarked: isBookmarked,
                        isCompleted: isCompleted,
                        onTap: () => _openLesson(lesson),
                        onToggleBookmark: () =>
                            lessonProvider.toggleBookmark(lesson.id),
                      );
                    },
                    childCount: lessonProvider.filteredLessons.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ],
        ),
      ),
    );
  }
}
