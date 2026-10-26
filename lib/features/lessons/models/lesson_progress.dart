import 'dart:convert';

/// Tracks local user interaction and progress for a specific lesson.
class LessonProgress {
  final String lessonId;
  final bool isCompleted;
  final bool isBookmarked;
  final DateTime? lastOpenedAt;

  const LessonProgress({
    required this.lessonId,
    this.isCompleted = false,
    this.isBookmarked = false,
    this.lastOpenedAt,
  });

  LessonProgress copyWith({
    String? lessonId,
    bool? isCompleted,
    bool? isBookmarked,
    DateTime? lastOpenedAt,
  }) {
    return LessonProgress(
      lessonId: lessonId ?? this.lessonId,
      isCompleted: isCompleted ?? this.isCompleted,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'lessonId': lessonId,
    'isCompleted': isCompleted,
    'isBookmarked': isBookmarked,
    'lastOpenedAt': lastOpenedAt?.toIso8601String(),
  };

  factory LessonProgress.fromMap(Map<String, dynamic> map) => LessonProgress(
    lessonId: map['lessonId'] as String,
    isCompleted: map['isCompleted'] as bool? ?? false,
    isBookmarked: map['isBookmarked'] as bool? ?? false,
    lastOpenedAt: map['lastOpenedAt'] != null
        ? DateTime.tryParse(map['lastOpenedAt'] as String)
        : null,
  );

  String toJson() => jsonEncode(toMap());

  factory LessonProgress.fromJson(String json) =>
      LessonProgress.fromMap(jsonDecode(json) as Map<String, dynamic>);
}
