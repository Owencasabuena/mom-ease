import 'dart:convert';

/// Authentication provider types supported by MomEase.
enum AuthType { local, google }

extension AuthTypeExtension on AuthType {
  String get value {
    switch (this) {
      case AuthType.local:
        return 'local';
      case AuthType.google:
        return 'google';
    }
  }

  static AuthType fromString(String? val) {
    if (val == 'google') {
      return AuthType.google;
    }
    return AuthType.local;
  }
}

/// Reusable User Model for both local and authenticated accounts.
class UserModel {
  final String id;
  final String displayName;
  final String? email;
  final String? photoUrl;
  final AuthType authType;
  final DateTime createdAt;
  final bool hasPin;

  const UserModel({
    required this.id,
    required this.displayName,
    this.email,
    this.photoUrl,
    required this.authType,
    required this.createdAt,
    this.hasPin = false,
  });

  bool get isLocal => authType == AuthType.local;
  bool get isGoogle => authType == AuthType.google;

  UserModel copyWith({
    String? id,
    String? displayName,
    String? email,
    String? photoUrl,
    AuthType? authType,
    DateTime? createdAt,
    bool? hasPin,
  }) {
    return UserModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      authType: authType ?? this.authType,
      createdAt: createdAt ?? this.createdAt,
      hasPin: hasPin ?? this.hasPin,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'authType': authType.value,
      'createdAt': createdAt.toIso8601String(),
      'hasPin': hasPin,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String? ?? 'local_user',
      displayName: map['displayName'] as String? ?? 'Mama',
      email: map['email'] as String?,
      photoUrl: map['photoUrl'] as String?,
      authType: AuthTypeExtension.fromString(map['authType'] as String?),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      hasPin: map['hasPin'] as bool? ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.displayName == displayName &&
        other.email == email &&
        other.photoUrl == photoUrl &&
        other.authType == authType &&
        other.hasPin == hasPin;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        displayName.hashCode ^
        email.hashCode ^
        photoUrl.hashCode ^
        authType.hashCode ^
        hasPin.hashCode;
  }
}
