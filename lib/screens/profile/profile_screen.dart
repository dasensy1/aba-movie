import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../auth/login_screen.dart';

/// ============================================================================
/// PROFILE SCREEN - С ИСТОРИЕЙ АКТИВНОСТИ
/// ============================================================================
/// Вкладка профиля пользователя со статистикой и лентой событий
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
    _refreshData();
  }

  void _refreshData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WatchlistProvider>().loadWatchlist();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshData();
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0B2E), Color(0xFF0D0D0D)],
            stops: [0.0, 0.5],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (!auth.isSignedIn) return _buildNotSignedIn();
                    return _buildProfileContent(auth);
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
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text('Профиль', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.red),
          onPressed: _handleLogout,
        ),
      ],
    );
  }

  Widget _buildProfileContent(AuthProvider auth) {
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(user),
          const SizedBox(height: 24),
          _buildWatchlistStats(),
          const SizedBox(height: 24),
          const Text(
            'История активности',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          _buildActivityLog(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(user) {
    final displayName = user.displayName ?? user.email.split('@').first;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: const Color(0xFF7C4DFF),
            child: Text(displayName[0].toUpperCase(), style: const TextStyle(fontSize: 28, color: Colors.white)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(user.email, style: TextStyle(fontSize: 14, color: Colors.grey[400])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchlistStats() {
    return Consumer<WatchlistProvider>(
      builder: (context, provider, _) {
        final stats = provider.getStatistics();
        return Row(
          children: [
            _buildStatCard('Фильмов', '${stats['total']}', const Color(0xFF7C4DFF)),
            const SizedBox(width: 12),
            _buildStatCard('Просмотров', '${stats['totalWatches']}', const Color(0xFF00E5FF)),
            const SizedBox(width: 12),
            _buildStatCard('Рейтинг', stats['averageRating'].toStringAsFixed(1), Colors.amber),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLog() {
    return Consumer<WatchlistProvider>(
      builder: (context, provider, _) {
        final logs = provider.activityLog;
        if (logs.isEmpty) {
          return Center(child: Text('История пуста', style: TextStyle(color: Colors.grey[700])));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return _buildActivityItem(log);
          },
        );
      },
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> log) {
    final status = log['status'];
    final date = DateTime.parse(log['watch_date']);
    
    String actionText = '';
    IconData iconData = Icons.info_outline;
    Color color = Colors.grey;

    if (status == 'increment_watch') {
      actionText = 'Посмотрел ещё раз';
      iconData = Icons.repeat;
      color = const Color(0xFF00E5FF);
    } else {
      switch (status) {
        case 'wantToWatch': actionText = 'Добавил в планы'; iconData = Icons.bookmark_border; color = const Color(0xFF7C4DFF); break;
        case 'watching': actionText = 'Начал смотреть'; iconData = Icons.play_circle_outline; color = const Color(0xFF00E5FF); break;
        case 'watched': actionText = 'Завершил просмотр'; iconData = Icons.check_circle_outline; color = Colors.green; break;
        case 'dropped': actionText = 'Бросил смотреть'; iconData = Icons.cancel_outlined; color = Colors.red; break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              'https://image.tmdb.org/t/p/w200${log['poster_path']}',
              width: 40, height: 60, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.movie, size: 40),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(iconData, size: 12, color: color),
                    const SizedBox(width: 4),
                    Text(actionText, style: TextStyle(color: color, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${date.day}.${date.month}',
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildNotSignedIn() {
    return const Center(child: Text('Пожалуйста, войдите', style: TextStyle(color: Colors.white)));
  }

  Future<void> _handleLogout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
    }
  }
}
