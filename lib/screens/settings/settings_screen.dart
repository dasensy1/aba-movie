// ============================================================================
// SETTINGS SCREEN — MODERN UI with gradient icon tiles
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../utils/modern_ui.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: ModernGradients.darkBackgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Consumer<SettingsProvider>(
                  builder: (context, settings, _) {
                    return AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - _animation.value)),
                          child: Opacity(opacity: _animation.value, child: child),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(ModernSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSection(
                              title: 'Внешний вид',
                              icon: Icons.palette_rounded,
                              gradient: ModernGradients.primaryGradient,
                              children: [
                                _buildModernSwitchTile(
                                  icon: Icons.dark_mode_rounded,
                                  title: 'Тёмная тема',
                                  subtitle: 'Использовать тёмное оформление',
                                  value: settings.isDarkTheme,
                                  onChanged: (value) {
                                    final auth = context.read<AuthProvider>();
                                    settings.toggleTheme(value, auth.userId);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: ModernSpacing.lg),
                            _buildSection(
                              title: 'Язык',
                              icon: Icons.language_rounded,
                              gradient: ModernGradients.oceanGradient,
                              children: [
                                _buildModernActionTile(
                                  icon: Icons.translate_rounded,
                                  title: 'Язык приложения',
                                  subtitle: settings.getLanguageName(settings.language),
                                  onTap: () => _showLanguageDialog(settings),
                                ),
                              ],
                            ),
                            const SizedBox(height: ModernSpacing.lg),
                            _buildSection(
                              title: 'Данные',
                              icon: Icons.storage_rounded,
                              gradient: ModernGradients.sunsetGradient,
                              children: [
                                _buildModernActionTile(
                                  icon: Icons.cleaning_services_rounded,
                                  title: 'Очистить кэш',
                                  subtitle: 'Удалить кэшированные данные',
                                  onTap: () => _clearCache(),
                                ),
                                _buildModernActionTile(
                                  icon: Icons.history_rounded,
                                  title: 'Очистить историю',
                                  subtitle: 'Удалить историю просмотров',
                                  onTap: () => _clearHistory(),
                                  destructive: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: ModernSpacing.lg),
                            _buildSection(
                              title: 'О приложении',
                              icon: Icons.info_rounded,
                              gradient: ModernGradients.sunsetGradient,
                              children: [
                                _buildInfoTile(
                                  icon: Icons.version_rounded,
                                  title: 'Версия',
                                  value: '1.0.0',
                                ),
                              ],
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: ModernGradients.sunsetGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.settings_rounded, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Text('Настройки', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Gradient gradient,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3)),
            ],
          ),
        ),
        Container(
          decoration: Glassmorphism.glassCard(opacity: 0.04, borderRadius: ModernRadius.lg),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildModernSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: ModernGradients.primaryGradient,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)) : null,
      trailing: Transform.scale(
        scale: 0.85,
        child: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: ModernColors.primaryPurple,
          activeTrackColor: ModernColors.primaryPurple.withValues(alpha: 0.4),
          inactiveThumbColor: Colors.grey,
          inactiveTrackColor: Colors.grey.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  Widget _buildModernActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    bool destructive = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: destructive
              ? const LinearGradient(colors: [ModernColors.error, Color(0xFFDC2626)])
              : ModernGradients.oceanGradient,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
      title: Text(title, style: TextStyle(color: destructive ? ModernColors.error : Colors.white, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)) : null,
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.3)),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: ModernGradients.oceanGradient,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: ModernColors.accentCyan.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ModernColors.accentCyan.withValues(alpha: 0.2)),
        ),
        child: Text(value, style: const TextStyle(color: ModernColors.accentCyan, fontSize: 13, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildLanguageTile(SettingsProvider settings) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: ModernGradients.oceanGradient,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.translate_rounded, size: 20, color: Colors.white),
      ),
      title: const Text('Язык приложения', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(settings.getLanguageName(settings.language), style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.3)),
      onTap: () => _showLanguageDialog(settings),
    );
  }

  void _showLanguageDialog(SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: Glassmorphism.glassBottomSheet,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: ModernGradients.oceanGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.translate_rounded, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text('Выберите язык', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 20),
            ...settings.supportedLanguages.map((lang) {
              final isSelected = settings.language == lang['code'];
              return GestureDetector(
                onTap: () {
                  final auth = context.read<AuthProvider>();
                  settings.setLanguage(lang['code']!, auth.userId);
                  Navigator.pop(context);
                },
                child: AnimatedContainer(
                  duration: ModernAnimations.fast,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ModernColors.primaryPurple.withValues(alpha: 0.15)
                        : ModernColors.surfaceDark.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(ModernRadius.md),
                    border: Border.all(
                      color: isSelected
                          ? ModernColors.primaryPurple.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.06),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(settings.getLanguageIcon(lang['code']!), color: ModernColors.primaryPurple, size: 22),
                      const SizedBox(width: 14),
                      Text(lang['name']!, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      if (isSelected) const Icon(Icons.check_circle_rounded, color: ModernColors.primaryPurple, size: 22),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ModernColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ModernRadius.lg)),
        title: const Text('Очистить кэш?', style: TextStyle(color: Colors.white)),
        content: const Text('Это удалит кэшированные изображения и данные', style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SettingsProvider>().clearCache();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Кэш очищен'), behavior: SnackBarBehavior.floating, backgroundColor: ModernColors.success),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: ModernColors.primaryPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ModernRadius.sm))),
            child: const Text('Очистить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ModernColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ModernRadius.lg)),
        title: const Text('Очистить историю?', style: TextStyle(color: Colors.white)),
        content: const Text('Это удалит всю историю просмотров', style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('История очищена'), behavior: SnackBarBehavior.floating, backgroundColor: ModernColors.success),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: ModernColors.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ModernRadius.sm))),
            child: const Text('Очистить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
