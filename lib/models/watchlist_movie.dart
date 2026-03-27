/// ============================================================================
/// WATCHLIST MOVIE MODEL
/// ============================================================================
/// Модель для трекинга фильмов: статус, оценка, заметки, дата просмотра
/// ============================================================================

import 'package:flutter/material.dart';

/// Статус фильма в треккинге
enum WatchStatus {
  wantToWatch,    // Хочу посмотреть
  watching,       // Смотрю сейчас
  watched,        // Просмотрено
  dropped,        // Бросил
}

/// Расширение для отображения статуса
extension WatchStatusExtension on WatchStatus {
  String get nameRu {
    switch (this) {
      case WatchStatus.wantToWatch:
        return 'Хочу посмотреть';
      case WatchStatus.watching:
        return 'Смотрю сейчас';
      case WatchStatus.watched:
        return 'Просмотрено';
      case WatchStatus.dropped:
        return 'Бросил';
    }
  }

  String get shortNameRu {
    switch (this) {
      case WatchStatus.wantToWatch:
        return 'Планы';
      case WatchStatus.watching:
        return 'Смотрю';
      case WatchStatus.watched:
        return 'Просмотрено';
      case WatchStatus.dropped:
        return 'Бросил';
    }
  }

  IconData get icon {
    switch (this) {
      case WatchStatus.wantToWatch:
        return Icons.bookmark_border;
      case WatchStatus.watching:
        return Icons.play_circle_outline;
      case WatchStatus.watched:
        return Icons.check_circle_outline;
      case WatchStatus.dropped:
        return Icons.cancel_outlined;
    }
  }
}

/// Модель фильма в треккинге
class WatchlistMovie {
  final int id;
  final int movieId;
  final String? imdbId;
  final String title;
  final String? posterPath;
  final WatchStatus status;
  final double? userRating;      // Оценка пользователя (0-10)
  final String? notes;           // Заметки пользователя
  final DateTime? watchedDate;   // Дата просмотра
  final DateTime addedDate;      // Дата добавления в треккинг

  WatchlistMovie({
    required this.id,
    required this.movieId,
    this.imdbId,
    required this.title,
    this.posterPath,
    required this.status,
    this.userRating,
    this.notes,
    this.watchedDate,
    required this.addedDate,
  });

  /// Создание из JSON
  factory WatchlistMovie.fromJson(Map<String, dynamic> json) {
    return WatchlistMovie(
      id: json['id'] ?? 0,
      movieId: json['movie_id'] ?? 0,
      imdbId: json['imdb_id'],
      title: json['title'] ?? 'Без названия',
      posterPath: json['poster_path'],
      status: WatchStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => WatchStatus.wantToWatch,
      ),
      userRating: json['user_rating'] != null 
          ? (json['user_rating'] as num).toDouble() 
          : null,
      notes: json['notes'],
      watchedDate: json['watched_date'] != null 
          ? DateTime.parse(json['watched_date']) 
          : null,
      addedDate: json['added_date'] != null 
          ? DateTime.parse(json['added_date']) 
          : DateTime.now(),
    );
  }

  /// Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'movie_id': movieId,
      'imdb_id': imdbId,
      'title': title,
      'poster_path': posterPath,
      'status': status.name,
      'user_rating': userRating,
      'notes': notes,
      'watched_date': watchedDate?.toIso8601String(),
      'added_date': addedDate.toIso8601String(),
    };
  }

  /// Преобразование в Map для SQLite
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'movie_id': movieId,
      'imdb_id': imdbId,
      'title': title,
      'poster_path': posterPath,
      'status': status.name,
      'user_rating': userRating,
      'notes': notes,
      'watched_date': watchedDate?.toIso8601String(),
      'added_date': addedDate.toIso8601String(),
    };
    
    // Если id != 0, значит это существующая запись, включаем id.
    // Если id == 0, не включаем его, чтобы сработал AUTOINCREMENT в SQLite.
    if (id != 0) {
      map['id'] = id;
    }
    
    return map;
  }

  /// Создание из Map SQLite
  factory WatchlistMovie.fromMap(Map<String, dynamic> map) {
    return WatchlistMovie(
      id: map['id'] ?? 0,
      movieId: map['movie_id'] ?? 0,
      imdbId: map['imdb_id'],
      title: map['title'] ?? 'Без названия',
      posterPath: map['poster_path'],
      status: WatchStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => WatchStatus.wantToWatch,
      ),
      userRating: map['user_rating'] != null 
          ? (map['user_rating'] as num).toDouble() 
          : null,
      notes: map['notes'],
      watchedDate: map['watched_date'] != null 
          ? DateTime.parse(map['watched_date']) 
          : null,
      addedDate: map['added_date'] != null 
          ? DateTime.parse(map['added_date']) 
          : DateTime.now(),
    );
  }

  /// Создание из Movie модели
  factory WatchlistMovie.fromMovie(dynamic movie, {WatchStatus status = WatchStatus.wantToWatch}) {
    return WatchlistMovie(
      id: 0, // Будет установлен БД (autoincrement)
      movieId: movie.id,
      imdbId: movie.imdbId,
      title: movie.title,
      posterPath: movie.posterPath,
      status: status,
      addedDate: DateTime.now(),
    );
  }

  /// Копия с изменениями
  WatchlistMovie copyWith({
    int? id,
    int? movieId,
    String? imdbId,
    String? title,
    String? posterPath,
    WatchStatus? status,
    double? userRating,
    String? notes,
    DateTime? watchedDate,
    DateTime? addedDate,
  }) {
    return WatchlistMovie(
      id: id ?? this.id,
      movieId: movieId ?? this.movieId,
      imdbId: imdbId ?? this.imdbId,
      title: title ?? this.title,
      posterPath: posterPath ?? this.posterPath,
      status: status ?? this.status,
      userRating: userRating ?? this.userRating,
      notes: notes ?? this.notes,
      watchedDate: watchedDate ?? this.watchedDate,
      addedDate: addedDate ?? this.addedDate,
    );
  }

  /// Получить URL постера
  String get posterUrl {
    if (posterPath == null || posterPath!.isEmpty) return '';
    if (posterPath!.startsWith('http')) return posterPath!;
    return 'https://image.tmdb.org/t/p/w500$posterPath';
  }

  /// Получить оценку для отображения
  String get ratingDisplay {
    if (userRating == null) return '—';
    return userRating!.toStringAsFixed(1);
  }

  /// Получить дату просмотра для отображения
  String get watchedDateDisplay {
    if (watchedDate == null) return '';
    final now = DateTime.now();
    final diff = now.difference(watchedDate!);
    
    if (diff.inDays == 0) return 'Сегодня';
    if (diff.inDays == 1) return 'Вчера';
    if (diff.inDays < 7) return '${diff.inDays} дн. назад';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} нед. назад';
    
    return '${watchedDate!.day}.${watchedDate!.month}.${watchedDate!.year}';
  }
}
