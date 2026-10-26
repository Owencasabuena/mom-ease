import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lesson.dart';
import '../providers/lesson_provider.dart';
import '../widgets/key_takeaways_card.dart';
import '../widgets/language_toggle.dart';
import '../widgets/lesson_video_section.dart';

class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;

  const LessonDetailScreen({super.key, required this.lesson});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LessonProvider>().recordLessonOpened(widget.lesson.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lessonProvider = context.watch<LessonProvider>();
    final theme = Theme.of(context);
    final lesson = widget.lesson;
    final lang = lessonProvider.currentLanguage;
    final isTl = lang == 'tl';

    final isBookmarked = lessonProvider.bookmarkedIds.contains(lesson.id);
    final isCompleted = lessonProvider.completedIds.contains(lesson.id);

    final title = lesson.localizedTitle(lang);
    final content = lesson.localizedContent(lang);
    final takeaways = lesson.localizedTakeaways(lang);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lesson.categoryLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          LanguageToggle(
            currentLanguage: lang,
            compact: true,
            onLanguageChanged: (newLang) {
              context.read<LessonProvider>().setLanguage(newLang);
            },
          ),
          IconButton(
            icon: Icon(
              isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: isBookmarked ? theme.colorScheme.primary : null,
            ),
            tooltip: isBookmarked ? 'Remove bookmark' : 'Save lesson',
            onPressed: () {
              context.read<LessonProvider>().toggleBookmark(lesson.id);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category & Reading Time Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.6,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    lesson.categoryLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${lesson.readingTimeMinutes} min ${isTl ? 'basa' : 'read'}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Lesson Title
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 16),

            // Optional Video Section
            if (lesson.hasVideo) ...[
              LessonVideoSection(videoUrl: lesson.videoUrl, language: lang),
              const SizedBox(height: 20),
            ],

            // Written Content Body
            _buildFormattedContent(content, theme),
            const SizedBox(height: 24),

            // Key Takeaways
            if (takeaways.isNotEmpty) ...[
              KeyTakeawaysCard(takeaways: takeaways, language: lang),
              const SizedBox(height: 24),
            ],

            // Exercise safety warning if physical-health
            if (lesson.category == 'physical-health') ...[
              _buildExerciseWarningCard(theme, isTl),
              const SizedBox(height: 16),
            ],

            // Medical Disclaimer if applicable
            if (lesson.isMedicalTopic) ...[
              _buildMedicalDisclaimer(theme, isTl),
              const SizedBox(height: 16),
            ],

            // Source info
            if (lesson.sourceName != null && lesson.sourceName!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 20),
                child: Text(
                  '${isTl ? "Pinagmulan" : "Source"}: ${lesson.sourceName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],

            // Mark as Completed Button
            FilledButton.icon(
              onPressed: () {
                context.read<LessonProvider>().toggleCompleted(lesson.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isCompleted
                          ? (isTl
                                ? 'Inalis sa mga natapos'
                                : 'Marked as uncompleted')
                          : (isTl
                                ? 'Nai-marka bilang natapos!'
                                : 'Marked as completed!'),
                    ),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: Icon(
                isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.check_circle_outline_rounded,
              ),
              label: Text(
                isCompleted
                    ? (isTl ? 'Natapos na ✓' : 'Completed ✓')
                    : (isTl ? 'Markahan Bilang Natapos' : 'Mark as Completed'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: isCompleted
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedContent(String rawText, ThemeData theme) {
    final paragraphs = rawText.split('\n\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((block) {
        var trimmed = block.trim();
        if (trimmed.isEmpty) return const SizedBox.shrink();

        // 1. Check if block has markdown heading prefix (## or #)
        bool isExplicitHeader = false;
        if (trimmed.startsWith('## ') || trimmed.startsWith('# ')) {
          isExplicitHeader = true;
          trimmed = trimmed.replaceFirst(RegExp(r'^#+\s*'), '');
        }

        // 2. Header detection: explicit header OR short standalone line without period,
        // not starting with a number or bullet
        final isNumbered = RegExp(r'^\d+[\.:\)]').hasMatch(trimmed);
        final isBullet = trimmed.startsWith('- ') || trimmed.startsWith('• ');
        final isShortTitle =
            trimmed.length < 60 &&
            !trimmed.endsWith('.') &&
            !trimmed.contains(': ') &&
            !isNumbered &&
            !isBullet &&
            !trimmed.contains('\n');

        if (isExplicitHeader || isShortTitle) {
          return Padding(
            padding: const EdgeInsets.only(top: 22, bottom: 8),
            child: Text(
              trimmed,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                letterSpacing: -0.2,
              ),
            ),
          );
        }

        // 3. Check for numbered item e.g. "1. Rest when you can. Sleep deprivation..."
        // or "1. Rest when you can: Sleep deprivation..."
        final numberedMatch = RegExp(
          r'^(\d+[\.:\)]\s*[^.\n:]+[\.:])\s*(.*)$',
          dotAll: true,
        ).firstMatch(trimmed);
        if (numberedMatch != null) {
          final boldLead = numberedMatch.group(1)!;
          final restText = numberedMatch.group(2) ?? '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text.rich(
              TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                ),
                children: [
                  TextSpan(
                    text: '$boldLead ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  ..._parseInlineSpans(restText, theme),
                ],
              ),
            ),
          );
        }

        // 4. Check for labeled item e.g. "Physical changes: You may notice..."
        // or "- Lochia (postpartum bleeding): This is normal..."
        final labeledMatch = RegExp(
          r'^([•\-]?\s*[^:\n]+:)\s*(.*)$',
          dotAll: true,
        ).firstMatch(trimmed);
        if (labeledMatch != null && labeledMatch.group(1)!.length < 50) {
          final label = labeledMatch.group(1)!;
          final rest = labeledMatch.group(2) ?? '';
          final cleanLabel = label.startsWith('- ')
              ? '• ${label.substring(2)}'
              : label;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text.rich(
              TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                ),
                children: [
                  TextSpan(
                    text: '$cleanLabel ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  ..._parseInlineSpans(rest, theme),
                ],
              ),
            ),
          );
        }

        // 5. Regular paragraph with potential inline markdown bold (**bold**)
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text.rich(
            TextSpan(
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
              ),
              children: _parseInlineSpans(trimmed, theme),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Parses inline text for any residual `**bold**` segments, stripping asterisks.
  List<InlineSpan> _parseInlineSpans(String text, ThemeData theme) {
    if (!text.contains('**')) {
      return [TextSpan(text: text)];
    }

    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      );
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return spans;
  }

  Widget _buildMedicalDisclaimer(ThemeData theme, bool isTl) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isTl
                  ? 'Ang araling ito ay nagbibigay lamang ng pangkalahatang impormasyon at hindi kapalit ng payo mula sa isang healthcare professional.'
                  : 'This lesson provides general educational information and is not a substitute for professional medical advice.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseWarningCard(ThemeData theme, bool isTl) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.favorite_rounded,
            size: 20,
            color: theme.colorScheme.tertiary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isTl
                  ? 'Ang bawat recovery ay magkakaiba. Kung hindi ka sigurado kung angkop ang isang ehersisyo sa iyong paggaling, sumangguni sa iyong doktor o healthcare provider.'
                  : "Recovery is different for everyone. If you're unsure whether an exercise is appropriate for your recovery, consider checking with your healthcare professional.",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
