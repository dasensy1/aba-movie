// ============================================================================
// LOCAL USER MODEL
// ============================================================================
// Модель локального пользователя для хранения в SQLite
// Отличается от AppUser тем, что включает password_hash и DB-поля
// ============================================================================

import 'dart:convert';
import 'dart:typed_data';

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

  /// Детерминированный хеш пароля с salt и key stretching.
  /// Не криптографически стоек, но значительно лучше XOR с ключом 42.
  /// Использует многократное хеширование (500 итераций) для усложнения брутфорса.
  static String hashPassword(String password) {
    const salt = 'movie_tracker_fixed_salt_2026_secure_v2';
    final data = Uint8List.fromList(utf8.encode(salt + password));

    var hash = 0;
    for (final byte in data) {
      hash = (hash * 31 + byte) & 0xFFFFFFFF;
    }

    // Key stretching — 500 итераций
    for (var i = 0; i < 500; i++) {
      hash = (hash * 31 + (hash >> 16) + i) & 0xFFFFFFFF;
      for (final byte in utf8.encode(password)) {
        hash = (hash * 31 + byte) & 0xFFFFFFFF;
      }
    }

    return hash.toRadixString(16).padLeft(8, '0');
  }

  /// Проверка пароля — сравниваем хеши
  static bool verifyPassword(String password, String hash) {
    try {
      return hashPassword(password) == hash;
    } catch (e) {
      return false;
    }
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
