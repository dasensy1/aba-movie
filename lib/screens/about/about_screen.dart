import 'package:flutter/material.dart';
import '../../utils/config.dart';

/// ============================================================================
/// ABOUT SCREEN
/// ============================================================================

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('О приложении'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Логотип
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF7C4DFF).withOpacity(0.3),
                    const Color(0xFF00E5FF).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.movie_filter,
                size: 80,
                color: Color(0xFF7C4DFF),
              ),
            ),
            const SizedBox(height: 24),
            // Название
            const Text(
              'Movie Tracker',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7C4DFF),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Версия ${AppConfig.appVersion}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ваш персональный киногид',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 32),
            // Описание
            _buildInfoCard(
              icon: Icons.description,
              title: 'О приложении',
              content: '''Movie Tracker - это современное приложение для отслеживания фильмов и сериалов.

Приложение работает полностью локально, без подключения к внешним API. Все данные хранятся на вашем устройстве.''',
            ),
            const SizedBox(height: 16),
            // Возможности
            _buildInfoCard(
              icon: Icons.checklist,
              title: 'Возможности',
              content: '''• Поиск фильмов по названию
• Просмотр трендов и популярных фильмов
• Категории по жанрам
• Избранные фильмы
• Тёмная тема оформления
• Локальная авторизация
• Сохранение настроек''',
            ),
            const SizedBox(height: 16),
            // Технологии
            _buildInfoCard(
              icon: Icons.code,
              title: 'Технологии',
              content: '''• Flutter & Dart
• Provider (State Management)
• SQLite (локальное хранилище)
• SharedPreferences
• Cached Network Image''',
            ),
            const SizedBox(height: 16),
            // Данные
            _buildInfoCard(
              icon: Icons.storage,
              title: 'Данные',
              content: '''Все данные хранятся локально на вашем устройстве:

• Избранные фильмы - SQLite база данных
• Настройки - SharedPreferences
• Демо-фильмы - встроенные заглушки

Приложение не требует подключения к интернету.''',
            ),
            const SizedBox(height: 24),
            // Кнопки действий
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Приложение работает локально 📱'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.info),
                  label: const Text('Инфо'),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Спасибо за оценку! ⭐'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.star),
                  label: const Text('Оценить'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF7C4DFF),
                    side: const BorderSide(color: Color(0xFF7C4DFF)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 80),
            // Копирайт
            Text(
              '© 2024 Movie Tracker. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF333333),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF7C4DFF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF7C4DFF), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
