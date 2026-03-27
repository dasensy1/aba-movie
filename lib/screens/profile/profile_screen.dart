import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../auth/login_screen.dart';

/// ============================================================================
/// PROFILE SCREEN - УЛУЧШЕННЫЙ С ТАТИСТИКОЙ
/// ============================================================================
/// Вкладка профиля пользователя со статистикой треккинга
/// ============================================================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Обновляем данные watchlist при загрузке профиля
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WatchlistProvider>().loadWatchlist();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Обновляем при возврате в приложение
      context.read<WatchlistProvider>().loadWatchlist();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A0B2E),
              const Color(0xFF0D0D0D),
            ],
            stops: const [0.0, 0.5],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: const Text(
                  'Профиль',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.red),
                    onPressed: _handleLogout,
                    tooltip: 'Выйти',
                  ),
                ],
              ),
              // Контент
              SliverToBoxAdapter(
                child: Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (!auth.isSignedIn) {
                      return _buildNotSignedIn();
                    }
                    return _buildProfile(auth);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Пользователь не авторизован
  Widget _buildNotSignedIn() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF7C4DFF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                size: 80,
                color: Color(0xFF7C4DFF),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Вы не авторизованы',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Войдите, чтобы получить доступ к профилю',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.login),
              label: const Text('Войти'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Профиль авторизованного пользователя
  Widget _buildProfile(AuthProvider auth) {
    final user = auth.user;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Аватар и информация
          _buildProfileHeader(user),
          const SizedBox(height: 24),
          // Статистика треккинга
          _buildWatchlistStats(),
          const SizedBox(height: 24),
          // Детальная статистика
          _buildDetailedStats(),
          const SizedBox(height: 24),
          // Опции профиля
          _buildProfileOptions(),
          const SizedBox(height: 24),
          // Информация об аккаунте
          _buildAccountInfo(user),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Заголовок профиля
  Widget _buildProfileHeader(user) {
    final displayName = user.displayName ?? user.email.split('@').first;
    final email = user.email;

    return Container(
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Аватар
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF7C4DFF),
            child: Text(
              displayName[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Информация
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Авторизован',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Статистика треккинга
  Widget _buildWatchlistStats() {
    return Consumer<WatchlistProvider>(
      builder: (context, provider, _) {
        final stats = provider.getStatistics();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.track_changes, color: Color(0xFF00E5FF), size: 20),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Статистика треккинга',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard(
                  icon: Icons.bookmark_border,
                  color: const Color(0xFF7C4DFF),
                  value: '${provider.wantToWatchCount}',
                  label: 'В планах',
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Icons.play_circle_outline,
                  color: const Color(0xFF00E5FF),
                  value: '${provider.watchingCount}',
                  label: 'Смотрю',
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  value: '${provider.watchedCount}',
                  label: 'Просмотрено',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard(
                  icon: Icons.cancel_outlined,
                  color: Colors.red,
                  value: '${provider.droppedCount}',
                  label: 'Бросил',
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Icons.star,
                  color: Colors.amber,
                  value: stats['averageRating'] != null && stats['averageRating'] > 0
                      ? (stats['averageRating'] as double).toStringAsFixed(1)
                      : '—',
                  label: 'Средняя оценка',
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Icons.movie_outlined,
                  color: const Color(0xFF7C4DFF),
                  value: '${provider.totalCount}',
                  label: 'Всего',
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Детальная статистика
  Widget _buildDetailedStats() {
    return Consumer<WatchlistProvider>(
      builder: (context, provider, _) {
        final stats = provider.getStatistics();
        final byMonth = stats['byMonth'] as Map<String, int>?;
        
        if (byMonth == null || byMonth.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF333333)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C4DFF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.bar_chart, color: Color(0xFF7C4DFF), size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Просмотры по месяцам',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildMonthChart(byMonth),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthChart(Map<String, int> byMonth) {
    final sortedMonths = byMonth.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    
    final recentMonths = sortedMonths.take(6).toList();
    
    if (recentMonths.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxValue = recentMonths.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        SizedBox(
          height: 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: recentMonths.map((entry) {
              final height = maxValue > 0 
                  ? (entry.value / maxValue * 80).toDouble()
                  : 0.0;
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${entry.value}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7C4DFF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 30,
                    height: height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF7C4DFF),
                          const Color(0xFF7C4DFF).withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 14,
                    child: Text(
                      entry.key.substring(5), // Только месяц
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Опции профиля
  Widget _buildProfileOptions() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        children: [
          _buildOptionItem(
            icon: Icons.person_outline,
            title: 'Редактировать профиль',
            subtitle: 'Изменить имя и фото',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Функция в разработке'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          Divider(color: Colors.grey[800], height: 1),
          _buildOptionItem(
            icon: Icons.notifications_outlined,
            title: 'Уведомления',
            subtitle: 'Настроить уведомления',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Функция в разработке'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          Divider(color: Colors.grey[800], height: 1),
          _buildOptionItem(
            icon: Icons.history,
            title: 'История просмотров',
            subtitle: 'Посмотреть историю',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Функция в разработке'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF7C4DFF).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF7C4DFF), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[500],
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
      onTap: onTap,
    );
  }

  /// Информация об аккаунте
  Widget _buildAccountInfo(user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.info_outline, color: Color(0xFF00E5FF), size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Информация об аккаунте',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('UID', user.uid),
          const SizedBox(height: 12),
          _buildInfoRow('Email', user.email),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Дата регистрации',
            user.createdAt.toString().substring(0, 10),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Выход
  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Выйти из аккаунта?'),
        content: Text(
          'Вы будете перенаправлены на экран входа',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
