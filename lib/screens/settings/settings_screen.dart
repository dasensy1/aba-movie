import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';

/// ============================================================================
/// SETTINGS SCREEN
/// ============================================================================

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Тема
                _buildSection(
                  title: 'Внешний вид',
                  children: [
                    _buildSwitchTile(
                      icon: Icons.dark_mode,
                      title: 'Тёмная тема',
                      subtitle: 'Использовать тёмное оформление',
                      value: settings.isDarkTheme,
                      onChanged: (value) {
                        settings.toggleTheme(value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Язык
                _buildSection(
                  title: 'Язык',
                  children: [
                    _buildLanguageTile(settings),
                  ],
                ),
                const SizedBox(height: 16),
                // Данные
                _buildSection(
                  title: 'Данные',
                  children: [
                    _buildActionTile(
                      icon: Icons.clear_all,
                      title: 'Очистить кэш',
                      subtitle: 'Удалить кэшированные данные',
                      onTap: () => _clearCache(),
                    ),
                    _buildActionTile(
                      icon: Icons.delete_outline,
                      title: 'Очистить историю',
                      subtitle: 'Удалить историю просмотров',
                      onTap: () => _clearHistory(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // О приложении
                _buildSection(
                  title: 'О приложении',
                  children: [
                    _buildInfoTile(
                      icon: Icons.info_outline,
                      title: 'Версия',
                      value: '1.0.0',
                    ),
                    _buildActionTile(
                      icon: Icons.star_outline,
                      title: 'Оценить приложение',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Спасибо за оценку! ⭐'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Сброс настроек
                _buildSection(
                  title: 'Дополнительно',
                  children: [
                    _buildActionTile(
                      icon: Icons.restore,
                      title: 'Сбросить настройки',
                      subtitle: 'Вернуть настройки по умолчанию',
                      isDestructive: true,
                      onTap: () => _resetSettings(settings),
                    ),
                  ],
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Секция
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  /// Переключатель
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF7C4DFF)),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF7C4DFF),
      ),
    );
  }

  /// Элемент с действием
  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : const Color(0xFF7C4DFF),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  /// Информационный элемент
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF7C4DFF)),
      title: Text(title),
      trailing: Text(
        value,
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 14,
        ),
      ),
    );
  }

  /// Выбор языка
  Widget _buildLanguageTile(SettingsProvider settings) {
    return ListTile(
      leading: const Icon(Icons.language, color: Color(0xFF7C4DFF)),
      title: const Text('Язык приложения'),
      subtitle: Text(
        '${settings.getLanguageFlag(settings.language)} ${settings.getLanguageName(settings.language)}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showLanguageDialog(settings),
    );
  }

  /// Диалог выбора языка
  void _showLanguageDialog(SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Выберите язык',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...settings.supportedLanguages.map((lang) {
              final isSelected = settings.language == lang['code'];
              return ListTile(
                leading: Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                title: Text(lang['name']!),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Color(0xFF7C4DFF))
                    : null,
                onTap: () {
                  settings.setLanguage(lang['code']!);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Очистить кэш
  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить кэш?'),
        content: const Text('Это удалит кэшированные изображения и данные'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SettingsProvider>().clearCache();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Кэш очищен'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C4DFF),
            ),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }

  /// Очистить историю
  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить историю?'),
        content: const Text('Это удалит всю историю просмотров'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('История очищена'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C4DFF),
            ),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }

  /// Сброс настроек
  void _resetSettings(SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить настройки?'),
        content: const Text(
          'Все настройки будут возвращены к значениям по умолчанию',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              settings.resetToDefaults();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Настройки сброшены'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }
}
