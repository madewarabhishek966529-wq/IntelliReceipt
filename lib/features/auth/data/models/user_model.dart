import '../../domain/entities/user_entity.dart';

/// Data-layer representation of a user. Handles JSON (de)serialization and
/// converts to/from [UserEntity] so the domain layer stays framework-free.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    super.photoUrl,
    super.emailVerified,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      email: json['email'] as String,
      name: json['name'] as String,
      photoUrl: json['photo_url'] as String?,
      emailVerified: json['email_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'photo_url': photoUrl,
        'email_verified': emailVerified,
        'created_at': createdAt.toIso8601String(),
      };

  factory UserModel.fromEntity(UserEntity entity) => UserModel(
        id: entity.id,
        email: entity.email,
        name: entity.name,
        photoUrl: entity.photoUrl,
        emailVerified: entity.emailVerified,
        createdAt: entity.createdAt,
      );
}
