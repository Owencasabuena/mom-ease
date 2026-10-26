import 'dart:convert';
import 'package:hive/hive.dart';
import '../../mood/models/mood_type.dart';

/// Hive typeId for JournalEntry.
const int kJournalEntryHiveId = 2;

/// Constants for Journal input method
class JournalInputMethod {
  static const String typed = 'typed';
  static const String voice = 'voice';
  static const String mixed = 'mixed';
}

/// Model representing a single personal journal entry.
///
/// Designed to be offline-first, private, and flexible:
/// supports multiple entries per day, optional linked mood,
/// optional prompt, tags, and input tracking (typed/voice/mixed).
class JournalEntry extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String userId;

  @HiveField(2)
  late DateTime date;

  @HiveField(3)
  String? title;

  @HiveField(4)
  late String content;

  @HiveField(5)
  String? moodId;

  @HiveField(6)
  late List<String> tags;

  @HiveField(7)
  late DateTime createdAt;

  @HiveField(8)
  late DateTime updatedAt;

  @HiveField(9)
  late bool isFavorite;

  @HiveField(10)
  String? promptId;

  @HiveField(11)
  late String inputMethod; // 'typed' | 'voice' | 'mixed'

  JournalEntry({
    required this.id,
    required this.userId,
    required this.date,
    this.title,
    required this.content,
    this.moodId,
    List<String>? tags,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.promptId,
    this.inputMethod = 'typed',
  }) {
    this.tags = tags ?? [];
  }

  /// Convenience getter for linked [MoodType] if present.
  MoodType? get mood {
    if (moodId == null) return null;
    try {
      return MoodType.values.firstWhere((m) => m.name == moodId);
    } catch (_) {
      return null;
    }
  }

  JournalEntry copyWith({
    String? title,
    String? content,
    String? moodId,
    bool clearMood = false,
    List<String>? tags,
    DateTime? updatedAt,
    bool? isFavorite,
    String? promptId,
    String? inputMethod,
    DateTime? date,
  }) {
    return JournalEntry(
      id: id,
      userId: userId,
      date: date ?? this.date,
      title: title ?? this.title,
      content: content ?? this.content,
      moodId: clearMood ? null : (moodId ?? this.moodId),
      tags: tags ?? List<String>.from(this.tags),
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isFavorite: isFavorite ?? this.isFavorite,
      promptId: promptId ?? this.promptId,
      inputMethod: inputMethod ?? this.inputMethod,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'date': date.toIso8601String(),
        'title': title,
        'content': content,
        'moodId': moodId,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isFavorite': isFavorite,
        'promptId': promptId,
        'inputMethod': inputMethod,
      };

  factory JournalEntry.fromMap(Map<String, dynamic> map) => JournalEntry(
        id: map['id'] as String,
        userId: map['userId'] as String,
        date: DateTime.parse(map['date'] as String),
        title: map['title'] as String?,
        content: map['content'] as String,
        moodId: map['moodId'] as String?,
        tags: List<String>.from(map['tags'] ?? []),
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
        isFavorite: map['isFavorite'] as bool? ?? false,
        promptId: map['promptId'] as String?,
        inputMethod: map['inputMethod'] as String? ?? 'typed',
      );

  String toJson() => jsonEncode(toMap());

  factory JournalEntry.fromJson(String json) =>
      JournalEntry.fromMap(jsonDecode(json) as Map<String, dynamic>);
}

/// Hand-written Hive adapter for [JournalEntry] (no build_runner required).
class JournalEntryAdapter extends TypeAdapter<JournalEntry> {
  @override
  final int typeId = kJournalEntryHiveId;

  @override
  JournalEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JournalEntry(
      id: fields[0] as String,
      userId: fields[1] as String,
      date: fields[2] as DateTime,
      title: fields[3] as String?,
      content: fields[4] as String,
      moodId: fields[5] as String?,
      tags: (fields[6] as List?)?.cast<String>() ?? [],
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
      isFavorite: fields[9] as bool? ?? false,
      promptId: fields[10] as String?,
      inputMethod: fields[11] as String? ?? 'typed',
    );
  }

  @override
  void write(BinaryWriter writer, JournalEntry obj) {
    writer.writeByte(12);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.userId);
    writer.writeByte(2);
    writer.write(obj.date);
    writer.writeByte(3);
    writer.write(obj.title);
    writer.writeByte(4);
    writer.write(obj.content);
    writer.writeByte(5);
    writer.write(obj.moodId);
    writer.writeByte(6);
    writer.write(obj.tags);
    writer.writeByte(7);
    writer.write(obj.createdAt);
    writer.writeByte(8);
    writer.write(obj.updatedAt);
    writer.writeByte(9);
    writer.write(obj.isFavorite);
    writer.writeByte(10);
    writer.write(obj.promptId);
    writer.writeByte(11);
    writer.write(obj.inputMethod);
  }
}
