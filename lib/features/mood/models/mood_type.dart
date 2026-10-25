import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// The five moods a user can log in MomEase.
enum MoodType { veryHappy, happy, neutral, sad, verySad }

/// Hive typeId used by MoodTypeAdapter.
const int kMoodTypeHiveId = 1;

extension MoodTypeX on MoodType {
  String get id => name;

  int get value {
    switch (this) {
      case MoodType.veryHappy: return 5;
      case MoodType.happy:     return 4;
      case MoodType.neutral:   return 3;
      case MoodType.sad:       return 2;
      case MoodType.verySad:   return 1;
    }
  }

  String get label {
    switch (this) {
      case MoodType.veryHappy: return 'Very Happy';
      case MoodType.happy:     return 'Happy';
      case MoodType.neutral:   return 'Okay';
      case MoodType.sad:       return 'Sad';
      case MoodType.verySad:   return 'Very Sad';
    }
  }

  String get assetPath {
    switch (this) {
      case MoodType.veryHappy: return 'assets/moods/very_happy.png';
      case MoodType.happy:     return 'assets/moods/happy.png';
      case MoodType.neutral:   return 'assets/moods/neutral.png';
      case MoodType.sad:       return 'assets/moods/sad.png';
      case MoodType.verySad:   return 'assets/moods/very_sad.png';
    }
  }

  Color get color {
    switch (this) {
      case MoodType.veryHappy: return const Color(0xFFFFD166);
      case MoodType.happy:     return const Color(0xFF6EBF8B);
      case MoodType.neutral:   return const Color(0xFF7BA7BC);
      case MoodType.sad:       return const Color(0xFFBA6868);
      case MoodType.verySad:   return const Color(0xFF8F4747);
    }
  }

  static MoodType fromValue(int v) {
    switch (v) {
      case 5:  return MoodType.veryHappy;
      case 4:  return MoodType.happy;
      case 3:  return MoodType.neutral;
      case 2:  return MoodType.sad;
      default: return MoodType.verySad;
    }
  }
}

/// Hand-written Hive adapter for [MoodType] (no build_runner required).
class MoodTypeAdapter extends TypeAdapter<MoodType> {
  @override
  final int typeId = kMoodTypeHiveId;

  @override
  MoodType read(BinaryReader reader) => MoodTypeX.fromValue(reader.readInt());

  @override
  void write(BinaryWriter writer, MoodType obj) => writer.writeInt(obj.value);
}
