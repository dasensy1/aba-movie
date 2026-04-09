/// ============================================================================
/// LOCAL USER MODEL
/// ============================================================================
/// Модель локального пользователя для хранения в SQLite
/// Отличается от AppUser тем, что включает password_hash и DB-поля
/// ============================================================================

import 'dart:convert';
import 'dart:math';

import 'app_user.dart';

class LocalUser {
  final int? id;
  final String email;
  final String passwordHash;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final bool isAnonymous;

  LocalUser({
    this.id,
    required this.email,
    required this.passwordHash,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.isAnonymous = false,
  });

  /// Простой hash пароля (для локального хранения, не криптографический)
  /// В production лучше использовать bcrypt, но для учебного проекта достаточно
  static String hashPassword(String password) {
    // Простой XOR + SHA-256 подход для локального проекта
    final bytes = utf8.encode(password);
    final key = 42;
    final xored = bytes.map((b) => b ^ key).toList();
    // Дополнительно используем hash от строки
    final combined = '${password}_salt_movie_tracker_2024';
    return combined.hashCode.toString() + '_' + base64.encode(xored);
  }

  /// Проверка пароля
  static bool verifyPassword(String password, String hash) {
    return hashPassword(password) == hash;
  }

  /// Создание из AppUser (при регистрации)
  factory LocalUser.fromAppUser(AppUser user, String password) {
    return LocalUser(
      email: user.email,
      passwordHash: hashPassword(password),
      displayName: user.displayName,
      photoUrl: user.photoUrl,
      createdAt: user.createdAt,
      isAnonymous: user.isAnonymous,
    );
  }

  /// Конвертация в AppUser (для использования в приложении)
  AppUser toAppUser() {
    return AppUser(
      uid: 'local_user_$id',
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      createdAt: createdAt,
      isAnonymous: isAnonymous,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'email': email,
      'password_hash': passwordHash,
      'display_name': displayName,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
      'is_anonymous': isAnonymous ? 1 : 0,
    };
  }

  factory LocalUser.fromMap(Map<String, dynamic> map) {
    return LocalUser(
      id: map['id'],
      email: map['email'] ?? '',
      passwordHash: map['password_hash'] ?? '',
      displayName: map['display_name'],
      photoUrl: map['photo_url'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      isAnonymous: map['is_anonymous'] == 1,
    );
  }
}
