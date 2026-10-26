import 'dart:convert';

/// Represents a single lesson in the MomEase learning catalogue.
///
/// All text content is bilingual (English + Tagalog) and stored locally
/// so everything works offline. The optional [videoUrl] is treated as a
/// supplementary online resource – the written lesson is the primary
/// educational content.
class Lesson {
  final String id;
  final Map<String, String> title;
  final Map<String, String> shortDescription;
  final Map<String, String> content;
  final Map<String, List<String>> keyTakeaways;
  final String category;
  final List<String> tags;
  final List<String> moodTags;
  final int readingTimeMinutes;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? sourceName;
  final bool isMedicalTopic;

  /// Optional future field – list of academic / medical sources.
  final List<LessonSource>? sources;

  const Lesson({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.content,
    required this.keyTakeaways,
    required this.category,
    required this.tags,
    required this.moodTags,
    required this.readingTimeMinutes,
    this.videoUrl,
    this.thumbnailUrl,
    this.sourceName,
    this.isMedicalTopic = false,
    this.sources,
  });

  /// Convenience getters for the currently selected language, with fallback.
  String localizedTitle(String lang) => title[lang] ?? title['en'] ?? '';

  String localizedDescription(String lang) =>
      shortDescription[lang] ?? shortDescription['en'] ?? '';

  String localizedContent(String lang) => content[lang] ?? content['en'] ?? '';

  List<String> localizedTakeaways(String lang) =>
      keyTakeaways[lang] ?? keyTakeaways['en'] ?? [];

  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;

  /// Human-readable category label.
  String get categoryLabel {
    switch (category) {
      case 'self-care':
        return 'Self-Care';
      case 'recovery':
        return 'Recovery';
      case 'mental-health':
        return 'Mental Health';
      case 'physical-health':
        return 'Physical Health';
      case 'mother-and-baby':
        return 'Mother & Baby';
      default:
        return category[0].toUpperCase() + category.substring(1);
    }
  }

  // ── JSON parsing ──────────────────────────────────────────────────────────

  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map['id'] as String,
      title: _castStringMap(map['title']),
      shortDescription: _castStringMap(map['shortDescription']),
      content: _castStringMap(map['content']),
      keyTakeaways: _castStringListMap(map['keyTakeaways']),
      category: map['category'] as String,
      tags: List<String>.from(map['tags'] ?? []),
      moodTags: List<String>.from(map['moodTags'] ?? []),
      readingTimeMinutes: (map['readingTimeMinutes'] as num?)?.toInt() ?? 5,
      videoUrl: map['videoUrl'] as String?,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      sourceName: map['sourceName'] as String?,
      isMedicalTopic: map['isMedicalTopic'] as bool? ?? false,
      sources: map['sources'] != null
          ? (map['sources'] as List)
                .map((s) => LessonSource.fromMap(s as Map<String, dynamic>))
                .toList()
          : null,
    );
  }

  factory Lesson.fromJson(String json) =>
      Lesson.fromMap(jsonDecode(json) as Map<String, dynamic>);

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'shortDescription': shortDescription,
    'content': content,
    'keyTakeaways': keyTakeaways,
    'category': category,
    'tags': tags,
    'moodTags': moodTags,
    'readingTimeMinutes': readingTimeMinutes,
    'videoUrl': videoUrl,
    'thumbnailUrl': thumbnailUrl,
    'sourceName': sourceName,
    'isMedicalTopic': isMedicalTopic,
    'sources': sources?.map((s) => s.toMap()).toList(),
  };

  String toJson() => jsonEncode(toMap());

  // ── Private helpers ───────────────────────────────────────────────────────

  static Map<String, String> _castStringMap(dynamic raw) {
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return {};
  }

  static Map<String, List<String>> _castStringListMap(dynamic raw) {
    if (raw is Map) {
      return raw.map(
        (k, v) => MapEntry(
          k.toString(),
          (v as List).map((e) => e.toString()).toList(),
        ),
      );
    }
    return {};
  }
}

/// Future-proof source reference for academic / medical citations.
class LessonSource {
  final String? title;
  final String? organization;
  final String? url;

  const LessonSource({this.title, this.organization, this.url});

  factory LessonSource.fromMap(Map<String, dynamic> map) => LessonSource(
    title: map['title'] as String?,
    organization: map['organization'] as String?,
    url: map['url'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'title': title,
    'organization': organization,
    'url': url,
  };
}
