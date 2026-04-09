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
    final auth = context.read<AuthProvider>();
    final result = await showModalBottomSheet<(WatchStatus, DateTime?)>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _StatusSelectionSheet(currentStatus: _currentStatus),
    );

    if (result != null) {
      final (selected, selectedDate) = result;
      if (selected != _currentStatus || selectedDate != null) {
        setState(() {
          _currentStatus = selected;
        });
        widget.onStatusChanged?.call(selected);
        await context.read<WatchlistProvider>().updateStatus(
          widget.movieId,
          selected,
          auth.userId,
          watchedDate: selectedDate,
        );
      }
    }
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
                    final auth = context.read<AuthProvider>();
                    context.read<WatchlistProvider>().updateRating(
                      widget.movieId,
                      value,
                      auth.userId,
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

/// Виджет выбора статуса с датой
class _StatusSelectionSheet extends StatefulWidget {
  final WatchStatus currentStatus;

  const _StatusSelectionSheet({Key? key, required this.currentStatus}) : super(key: key);

  @override
  State<_StatusSelectionSheet> createState() => _StatusSelectionSheetState();
}

class _StatusSelectionSheetState extends State<_StatusSelectionSheet> {
  WatchStatus? _selectedStatus;
  DateTime? _selectedDate;

  Color _getStatusColor(WatchStatus status) {
    switch (status) {
      case WatchStatus.wantToWatch:
        return const Color(0xFF7C4DFF);
      case WatchStatus.watching:
        return const Color(0xFF00E5FF);
      case WatchStatus.watched:
        return Colors.green;
      case WatchStatus.dropped:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Выберите статус',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              ...WatchStatus.values.map((status) {
                final isSelected = _selectedStatus == status || (_selectedStatus == null && status == widget.currentStatus);
                return GestureDetector(
                  onTap: () {
                    setModalState(() {
                      _selectedStatus = status;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _getStatusColor(status).withOpacity(0.2)
                          : const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? _getStatusColor(status)
                            : const Color(0xFF333333),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(status.icon, color: _getStatusColor(status)),
                        const SizedBox(width: 12),
                        Text(status.nameRu, style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFF333333)),
              const SizedBox(height: 8),
              const Text(
                'Дата просмотра',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final now = DateTime.now();
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? now,
                    firstDate: DateTime(1900),
                    lastDate: now,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFF7C4DFF),
                            onPrimary: Colors.white,
                            surface: Color(0xFF1A1A1A),
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (pickedDate != null) {
                    if (pickedDate.isAfter(now)) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Нельзя выбрать будущую дату!'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }
                    setModalState(() {
                      _selectedDate = pickedDate;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF333333)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Color(0xFF7C4DFF)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedDate != null
                              ? '${_selectedDate!.day.toString().padLeft(2, '0')}.${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.year}'
                              : 'Выберите дату (необязательно)',
                          style: TextStyle(
                            color: _selectedDate != null ? Colors.white : Colors.grey[500],
                          ),
                        ),
                      ),
                      if (_selectedDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.red),
                          onPressed: () {
                            setModalState(() {
                              _selectedDate = null;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedStatus != null
                      ? () => Navigator.pop(context, (_selectedStatus!, _selectedDate))
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C4DFF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Сохранить',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
