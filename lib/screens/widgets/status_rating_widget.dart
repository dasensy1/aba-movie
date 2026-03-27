/// ============================================================================
/// STATUS RATING WIDGET
/// ============================================================================
/// Виджет для выбора статуса фильма и оценки в треккинге
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class StatusRatingWidget extends StatefulWidget {
  final int movieId;
  final WatchStatus initialStatus;
  final bool isInWatchlist;
  final Function(WatchStatus)? onStatusChanged;

  const StatusRatingWidget({
    Key? key,
    required this.movieId,
    required this.initialStatus,
    required this.isInWatchlist,
    this.onStatusChanged,
  }) : super(key: key);

  @override
  State<StatusRatingWidget> createState() => _StatusRatingWidgetState();
}

class _StatusRatingWidgetState extends State<StatusRatingWidget> {
  late WatchStatus _currentStatus;
  double? _userRating;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.initialStatus;
    _loadRating();
  }

  void _loadRating() {
    final provider = context.read<WatchlistProvider>();
    final watchlistMovie = provider.getWatchlistMovie(widget.movieId);
    if (watchlistMovie != null) {
      setState(() {
        _userRating = watchlistMovie.userRating;
      });
    }
  }

  Future<void> _selectStatus() async {
    final selected = await showModalBottomSheet<WatchStatus>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Выберите статус',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ...WatchStatus.values.map((status) => _buildStatusOption(status)),
          ],
        ),
      ),
    );

    if (selected != null && selected != _currentStatus) {
      setState(() {
        _currentStatus = selected;
      });
      widget.onStatusChanged?.call(selected);
      await context.read<WatchlistProvider>().updateStatus(widget.movieId, selected);
    }
  }

  Widget _buildStatusOption(WatchStatus status) {
    final isSelected = _currentStatus == status;
    return GestureDetector(
      onTap: () => Navigator.pop(context, status),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF7C4DFF).withOpacity(0.2)
              : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF7C4DFF)
                : const Color(0xFF333333),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF7C4DFF).withOpacity(0.3)
                    : const Color(0xFF333333),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                status.icon,
                color: isSelected ? const Color(0xFF7C4DFF) : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.nameRu,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFF7C4DFF) : Colors.white,
                    ),
                  ),
                  Text(
                    status.shortNameRu,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected 
                          ? const Color(0xFF7C4DFF).withOpacity(0.7)
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF7C4DFF),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isInWatchlist) {
      return _buildNotInWatchlist();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Текущий статус
        GestureDetector(
          onTap: _selectStatus,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF333333)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C4DFF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _currentStatus.icon,
                    color: const Color(0xFF7C4DFF),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Статус',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentStatus.nameRu,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Оценка
        _buildRatingSection(),
      ],
    );
  }

  Widget _buildNotInWatchlist() {
    return GestureDetector(
      onTap: () {
        widget.onStatusChanged?.call(WatchStatus.wantToWatch);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF333333), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.add_task,
                color: Color(0xFF00E5FF),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Добавить в треккинг',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Отслеживайте просмотренные фильмы',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.star, color: Colors.amber, size: 20),
            ),
            const SizedBox(width: 8),
            const Text(
              'Ваша оценка',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: Colors.amber,
                  inactiveTrackColor: const Color(0xFF333333),
                  thumbColor: Colors.amber,
                  overlayColor: Colors.amber.withOpacity(0.2),
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                ),
                child: Slider(
                  value: _userRating ?? 0,
                  min: 0,
                  max: 10,
                  divisions: 20,
                  label: _userRating?.toStringAsFixed(1) ?? '—',
                  onChanged: (value) {
                    setState(() {
                      _userRating = value;
                    });
                    context.read<WatchlistProvider>().updateRating(
                      widget.movieId,
                      value,
                    );
                  },
                ),
              ),
            ),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: Center(
                child: Text(
                  _userRating?.toStringAsFixed(1) ?? '—',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
