import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mom_ease/features/lessons/data/lesson_repository.dart';
import 'package:mom_ease/features/lessons/models/lesson.dart';
import 'package:mom_ease/features/lessons/providers/lesson_provider.dart';
import 'package:mom_ease/features/lessons/screens/lesson_detail_screen.dart';
import 'package:mom_ease/features/lessons/services/lesson_recommendation_service.dart';
import 'package:mom_ease/features/lessons/services/lesson_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLessonRepository implements LessonRepository {
  @override
  Future<List<Lesson>> getAllLessons() async => [];
  @override
  Future<Lesson?> getLessonById(String id) async => null;
  @override
  Future<List<Lesson>> getLessonsByCategory(String category) async => [];
  @override
  Future<List<Lesson>> getLessonsByMood(String moodTag) async => [];
  @override
  Future<List<Lesson>> searchLessons(
    String query, {
    String lang = 'en',
  }) async => [];
}

void main() {
  group('Lesson Model & Localization Tests', () {
    const rawLessonJson = '''
    {
      "id": "lesson_001",
      "title": {
        "en": "5 Important Postpartum Self-Care Tips",
        "tl": "5 Mahalagang Paraan ng Pangangalaga sa Sarili Pagkatapos Manganak"
      },
      "shortDescription": {
        "en": "Simple ways to care for yourself during postpartum recovery.",
        "tl": "Mga simpleng paraan upang alagaan ang sarili habang nagpapagaling."
      },
      "content": {
        "en": "Rest whenever possible.\\n\\nAccept help.",
        "tl": "Magpahinga kung maaari.\\n\\nTanggapin ang tulong."
      },
      "keyTakeaways": {
        "en": ["Rest often", "Accept help"],
        "tl": ["Magpahinga madalas", "Tanggapin ang tulong"]
      },
      "category": "self-care",
      "tags": ["self-care", "recovery", "wellness"],
      "moodTags": ["happy", "neutral", "sad"],
      "readingTimeMinutes": 5,
      "videoUrl": "https://youtu.be/djFkXYwRnjs",
      "thumbnailUrl": null,
      "sourceName": "YouTube",
      "isMedicalTopic": false
    }
    ''';

    test('Lesson correctly parses from map / JSON', () {
      final lesson = Lesson.fromMap(
        jsonDecode(rawLessonJson) as Map<String, dynamic>,
      );

      expect(lesson.id, equals('lesson_001'));
      expect(lesson.category, equals('self-care'));
      expect(lesson.readingTimeMinutes, equals(5));
      expect(lesson.hasVideo, isTrue);
      expect(lesson.isMedicalTopic, isFalse);
      expect(lesson.moodTags, contains('sad'));
      expect(lesson.tags, contains('recovery'));
    });

    test('Bilingual getters return correct language and fallback to en', () {
      final lesson = Lesson.fromMap(
        jsonDecode(rawLessonJson) as Map<String, dynamic>,
      );

      expect(
        lesson.localizedTitle('en'),
        equals('5 Important Postpartum Self-Care Tips'),
      );
      expect(
        lesson.localizedTitle('tl'),
        equals(
          '5 Mahalagang Paraan ng Pangangalaga sa Sarili Pagkatapos Manganak',
        ),
      );
      // Fallback for unknown language
      expect(
        lesson.localizedTitle('fr'),
        equals('5 Important Postpartum Self-Care Tips'),
      );

      expect(lesson.localizedTakeaways('tl'), contains('Magpahinga madalas'));
      expect(lesson.localizedTakeaways('en'), contains('Rest often'));
    });
  });

  group('LessonRecommendationService Tests', () {
    final service = LessonRecommendationService();

    final testLessons = [
      const Lesson(
        id: 'lesson_001',
        title: {'en': 'Self-Care Tips'},
        shortDescription: {'en': 'Description'},
        content: {'en': 'Content'},
        keyTakeaways: {
          'en': ['Takeaway'],
        },
        category: 'self-care',
        tags: ['self-care'],
        moodTags: ['happy', 'neutral'],
        readingTimeMinutes: 5,
      ),
      const Lesson(
        id: 'lesson_006',
        title: {'en': 'Understanding Postpartum Depression'},
        shortDescription: {'en': 'Description'},
        content: {'en': 'Content'},
        keyTakeaways: {
          'en': ['Takeaway'],
        },
        category: 'mental-health',
        tags: ['mental-health'],
        moodTags: ['sad', 'verySad'],
        readingTimeMinutes: 6,
        isMedicalTopic: true,
      ),
    ];

    test('Recommends sad-tagged lesson for sad mood', () {
      final rec = service.getRecommendation(
        allLessons: testLessons,
        moodId: 'sad',
      );
      expect(rec.id, equals('lesson_006'));
    });

    test('Recommends happy-tagged lesson for happy mood', () {
      final rec = service.getRecommendation(
        allLessons: testLessons,
        moodId: 'happy',
      );
      expect(rec.id, equals('lesson_001'));
    });

    test('Falls back gracefully if moodId is null or unknown', () {
      final rec = service.getRecommendation(
        allLessons: testLessons,
        moodId: null,
      );
      expect(rec, isNotNull);
    });

    test('Recommendation subheadings are gentle and non-diagnostic', () {
      final en = service.getRecommendationSubheading('sad', 'en');
      final tl = service.getRecommendationSubheading('sad', 'tl');

      expect(en, contains('You may find this helpful'));
      expect(en, isNot(contains('depression')));
      expect(tl, contains('Maaaring makatulong'));
    });
  });

  group('LessonDetailScreen Rich Content Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets(
      'Renders headings as actual headers and bold numbers without raw symbols',
      (WidgetTester tester) async {
        const lesson = Lesson(
          id: 'lesson_test',
          title: {'en': 'Sample Lesson'},
          shortDescription: {'en': 'Short description'},
          content: {
            'en':
                'Why Self-Care Matters\n\n'
                'Self-care is not selfish. When you feel rested, you feel better.\n\n'
                '1. Rest when you can. Sleep when your baby sleeps.\n\n'
                '2. Stay nourished. Eat balanced meals.',
          },
          keyTakeaways: {
            'en': ['Takeaway 1'],
          },
          category: 'self-care',
          tags: ['self-care'],
          moodTags: ['neutral'],
          readingTimeMinutes: 4,
        );

        final lessonProvider = LessonProvider(
          LessonService(_FakeLessonRepository(), 'test_user'),
        );

        await tester.pumpWidget(
          ChangeNotifierProvider<LessonProvider>.value(
            value: lessonProvider,
            child: const MaterialApp(home: LessonDetailScreen(lesson: lesson)),
          ),
        );
        await tester.pumpAndSettle();

        // Heading should be rendered cleanly as text
        expect(find.text('Why Self-Care Matters'), findsOneWidget);

        // Raw hashtags or asterisks should never appear anywhere
        expect(find.textContaining('##'), findsNothing);
        expect(find.textContaining('**'), findsNothing);

        // Numbered bold lead-ins should be present inside RichText
        final richTexts = find.byType(RichText);
        expect(richTexts, findsWidgets);

        // Verify "1. Rest when you can." is rendered bold
        bool foundBoldNumber1 = false;
        bool foundBoldNumber2 = false;

        for (final element in richTexts.evaluate()) {
          final widget = element.widget as RichText;
          widget.text.visitChildren((span) {
            if (span is TextSpan && span.text != null) {
              if (span.text!.contains('1. Rest when you can.') &&
                  span.style?.fontWeight == FontWeight.bold) {
                foundBoldNumber1 = true;
              }
              if (span.text!.contains('2. Stay nourished.') &&
                  span.style?.fontWeight == FontWeight.bold) {
                foundBoldNumber2 = true;
              }
            }
            return true;
          });
        }

        expect(foundBoldNumber1, isTrue);
        expect(foundBoldNumber2, isTrue);
      },
    );
  });
}
