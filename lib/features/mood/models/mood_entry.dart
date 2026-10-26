import 'package:hive/hive.dart';

import 'mood_type.dart';

/// Hive typeId for MoodEntry.
const int kMoodEntryHiveId = 0;

/// A single mood log entry, stored locally via Hive.
///
/// One entry per user per calendar date (date normalized to midnight).
class MoodEntry extends HiveObject {
  @HiveField(0)
  late int id;

  @HiveField(1)
  late String userId;

  /// Date stored as midnight UTC to ensure uniqueness per day.
  @HiveField(2)
  late DateTime date;

  /// Mood stored as its numeric value (1-5).
  @HiveField(3)
  late int moodValue;

  @HiveField(4)
  String? note;

  @HiveField(5)
  late DateTime createdAt;

  @HiveField(6)
  late DateTime updatedAt;

  MoodEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.moodValue,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  MoodType get mood => MoodTypeX.fromValue(moodValue);

  MoodEntry copyWith({int? moodValue, String? note, DateTime? updatedAt}) =>
      MoodEntry(
        id: id,
        userId: userId,
        date: date,
        moodValue: moodValue ?? this.moodValue,
        note: note ?? this.note,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );
}

/// Hand-written Hive adapter – no build_runner required.
class MoodEntryAdapter extends TypeAdapter<MoodEntry> {
  @override
  final int typeId = kMoodEntryHiveId;

  @override
  MoodEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MoodEntry(
      id: (fields[0] as num).toInt(),
      userId: fields[1] as String,
      date: fields[2] as DateTime,
      moodValue: (fields[3] as num).toInt(),
      note: fields[4] as String?,
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MoodEntry obj) {
    writer.writeByte(7);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.userId);
    writer.writeByte(2);
    writer.write(obj.date);
    writer.writeByte(3);
    writer.write(obj.moodValue);
    writer.writeByte(4);
    writer.write(obj.note);
    writer.writeByte(5);
    writer.write(obj.createdAt);
    writer.writeByte(6);
    writer.write(obj.updatedAt);
  }
}
