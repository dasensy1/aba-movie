// ============================================================================
// STATUS RATING WIDGET
// ============================================================================
// Виджет для выбора статуса фильма и оценки в треккинге
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

/// Custom clipper for rendering partial/fractional stars
class _StarClipper extends CustomClipper<Rect> {
  final double percentage;
  
  const _StarClipper({required this.percentage});
  
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * (percentage / 100), size.height);
  }
  
  @override
  bool shouldReclip(_StarClipper oldClipper) => oldClipper.percentage != percentage;
}

class StatusRatingWidget extends StatefulWidget {
  final int movieId;
  final WatchStatus initialStatus;
  final bool isInWatchlist;
  final Function(WatchStatus)? onStatusChanged;

  const StatusRatingWidget({
    super.key,
    required this.movieId,
    required this.initialStatus,
    required this.isInWatchlist,
    this.onStatusChanged,
  });

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
      if (!mounted) return;
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
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.2),
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
                color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
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
    final bool canRate = _currentStatus == WatchStatus.watched;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.star, color: Colors.amber, size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              'Ваша оценка',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: canRate ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: canRate
                    ? () async {
                        final newRating = await _showStarRatingDialog();
                        if (newRating != null && mounted) {
                          setState(() {
                            _userRating = newRating;
                          });
                          final auth = context.read<AuthProvider>();
                          await context.read<WatchlistProvider>().updateRating(
                            widget.movieId,
                            newRating,
                            auth.userId,
                          );
                        }
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: canRate ? const Color(0xFF2A2A2A) : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: canRate ? Colors.amber.withValues(alpha: 0.3) : const Color(0xFF333333),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStarRow(canRate: canRate),
                      const SizedBox(width: 12),
                      Text(
                        _userRating != null ? '${_userRating!.toStringAsFixed(1)} / 10' : 'Нажмите, чтобы оценить',
                        style: TextStyle(
                          fontSize: 14,
                          color: canRate ? Colors.amber : Colors.grey,
                          fontWeight: _userRating != null ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (!canRate) ...[
          const SizedBox(height: 8),
          Text(
            'Оценка доступна только после установки статуса "Просмотрено"',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStarRow({required bool canRate}) {
    final rating = _userRating ?? 0;
    // Convert 0-10 scale to 0-5 stars (each star = 2 points)
    final stars = rating / 2;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isActive = stars >= starValue;
        final isHalfActive = !isActive && stars > index && stars < starValue;
        
        return GestureDetector(
          onTapDown: canRate
              ? (TapDownDetails details) {
                  final tapX = details.localPosition.dx;
                  final isLeftHalf = tapX < 16; // 28px icon + 4px padding = 32px total, half = 16
                  final newRating = isLeftHalf ? (starValue - 0.5) * 2 : starValue * 2.0;
                  
                  setState(() {
                    _userRating = newRating;
                  });
                  final auth = context.read<AuthProvider>();
                  context.read<WatchlistProvider>().updateRating(
                    widget.movieId,
                    newRating,
                    auth.userId,
                  );
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: isHalfActive
                ? Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      const Icon(Icons.star_border, color: Colors.amber, size: 28),
                      ClipRect(
                        clipper: _StarClipper(percentage: (stars - index) * 100),
                        child: const Icon(Icons.star, color: Colors.amber, size: 28),
                      ),
                    ],
                  )
                : Icon(
                    isActive ? Icons.star : Icons.star_border,
                    color: canRate ? Colors.amber : Colors.grey,
                    size: 28,
                  ),
          ),
        );
      }),
     );
   }

  Future<double?> _showStarRatingDialog() async {
    double tempRating = _userRating ?? 0;
    
    return await showModalBottomSheet<double>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Поставьте оценку',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 36),
                    const SizedBox(width: 12),
                    Text(
                      tempRating > 0 ? tempRating.toStringAsFixed(1) : '—',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.amber),
                    ),
                    const Text(' / 10', style: TextStyle(fontSize: 20, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDialogStarRow(onRatingChanged: (rating) {
                  setModalState(() {
                    tempRating = rating;
                  });
                }, currentRating: tempRating),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setModalState(() {
                            tempRating = 0;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Сбросить', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, tempRating),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C4DFF),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Сохранить', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDialogStarRow({required ValueChanged<double> onRatingChanged, required double currentRating}) {
    // Convert 0-10 scale to 0-5 stars (each star = 2 points)
    final stars = currentRating / 2;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1.0;
        final isActive = stars >= starValue;
        final isHalfActive = !isActive && stars > index && stars < starValue;
        
        return GestureDetector(
          onTapDown: (TapDownDetails details) {
            final tapX = details.localPosition.dx;
            // Padding is 4px each side, icon 40px → total ~48px, half = 24
            final isLeftHalf = tapX < 24;
            final newRating = isLeftHalf ? (starValue - 0.5) * 2 : starValue * 2;
            onRatingChanged(newRating);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: isHalfActive
                ? Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      const Icon(Icons.star_border, color: Colors.amber, size: 40),
                      ClipRect(
                        clipper: _StarClipper(percentage: (stars - index) * 100),
                        child: const Icon(Icons.star, color: Colors.amber, size: 40),
                      ),
                    ],
                  )
                : Icon(
                    isActive ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
          ),
        );
      }),
    );
  }
}

/// Виджет выбора статуса с датой
class _StatusSelectionSheet extends StatefulWidget {
  final WatchStatus currentStatus;

  const _StatusSelectionSheet({required this.currentStatus});

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
                          ? _getStatusColor(status).withValues(alpha: 0.2)
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
                  final messenger = ScaffoldMessenger.of(context);
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
                      if (!mounted) return;
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Нельзя выбрать будущую дату!'),
                          backgroundColor: Colors.red,
                        ),
                      );
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
                   onPressed: () {
                     final statusToSave = _selectedStatus ?? widget.currentStatus;
                     Navigator.pop(context, (statusToSave, _selectedDate));
                   },
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
