import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:movieversego/data/models/movie.dart';
import 'package:movieversego/data/models/session.dart';
import 'package:movieversego/data/moviemax_api.dart';
import 'package:movieversego/view/screens/seat_selection_screen.dart';
import 'package:movieversego/view/widgets/network_poster.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({
    super.key,
    required this.movie,
    required this.cityId,
  });

  final Movie movie;
  final int cityId;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final MovieMaxApi _api = MovieMaxApi();

  bool _loading = true;
  String? _error;
  SessionData? _sessionData;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions({DateTime? date}) async {
    final filmCode = widget.movie.filmCode;
    if (filmCode == null || filmCode.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Showtimes not available for this movie';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _api.fetchSessions(
        filmCode,
        date: date,
        cityId: widget.cityId,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _sessionData = data;
        _selectedDate = date ??
            (data.dates.isNotEmpty ? data.dates.first : DateTime.now());
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _onDateSelected(DateTime date) async {
    if (_selectedDate?.year == date.year &&
        _selectedDate?.month == date.month &&
        _selectedDate?.day == date.day) {
      return;
    }

    setState(() => _selectedDate = date);
    await _loadSessions(date: date);
  }

  void _openSeatSelection({
    required CinemaShowtimes cinema,
    required ShowTiming timing,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeatSelectionScreen(
          sessionId: timing.id,
          cinemaId: cinema.id,
          cinemaName: cinema.name,
          movieTitle: _displayTitle,
          showTime: timing.time,
          imagePath: _sessionData?.movie.imagePath ?? widget.movie.imagePath,
        ),
      ),
    );
  }

  String get _displayTitle =>
      _sessionData?.movie.title ?? widget.movie.title;

  @override
  Widget build(BuildContext context) {
    final movie = _sessionData?.movie;
    final imagePath = movie?.imagePath ?? widget.movie.imagePath;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Book Tickets'),
      ),
      body: _loading && _sessionData == null
          ? const Center(
              child: CircularProgressIndicator(color: Colors.yellow),
            )
          : _error != null && _sessionData == null
              ? _ErrorBody(message: _error!, onRetry: () => _loadSessions())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MovieHeroCard(
                        title: _displayTitle,
                        imagePath: imagePath,
                        language: movie?.language ?? widget.movie.language,
                        censor: movie?.censor,
                        duration: movie?.duration,
                        genre: movie?.genre ?? widget.movie.genre,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Select Date',
                        style: TextStyle(
                          color: Colors.yellow,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 72,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _sessionData?.dates.length ?? 0,
                          separatorBuilder: (_, index) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final date = _sessionData!.dates[index];
                            final selected = _selectedDate != null &&
                                date.year == _selectedDate!.year &&
                                date.month == _selectedDate!.month &&
                                date.day == _selectedDate!.day;

                            return _DateChip(
                              date: date,
                              selected: selected,
                              onTap: () => _onDateSelected(date),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(
                              color: Colors.yellow,
                            ),
                          ),
                        )
                      else if (_sessionData!.cinemas.isEmpty)
                        const Text(
                          'No showtimes for this date',
                          style: TextStyle(color: Colors.white54),
                        )
                      else
                        ..._sessionData!.cinemas.map((cinema) {
                          return _CinemaSection(
                            cinema: cinema,
                            onShowtimeTap: (timing) => _openSeatSelection(
                              cinema: cinema,
                              timing: timing,
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}

class _MovieHeroCard extends StatelessWidget {
  const _MovieHeroCard({
    required this.title,
    required this.imagePath,
    this.language,
    this.censor,
    this.duration,
    this.genre,
  });

  final String title;
  final String? imagePath;
  final String? language;
  final String? censor;
  final int? duration;
  final String? genre;

  @override
  Widget build(BuildContext context) {
    final meta = [
      language,
      censor,
      if (duration != null) '$duration min',
    ].whereType<String>().join(' • ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A0A1E),
            const Color(0xFF2B0D2F).withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: NetworkPoster(
              imagePath: imagePath,
              width: 96,
              height: 132,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    meta,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
                if (genre != null && genre!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    genre!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isToday = _isSameDay(date, DateTime.now());
    final dayLabel = isToday ? 'Today' : DateFormat('EEE').format(date);
    final dateLabel = DateFormat('dd/MM').format(date);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.yellow : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.yellow : Colors.white24,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayLabel,
              style: TextStyle(
                color: selected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Text(
              dateLabel,
              style: TextStyle(
                color: selected ? Colors.black87 : Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _CinemaSection extends StatelessWidget {
  const _CinemaSection({
    required this.cinema,
    required this.onShowtimeTap,
  });

  final CinemaShowtimes cinema;
  final ValueChanged<ShowTiming> onShowtimeTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.yellow, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  cinema.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (cinema.address.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              cinema.address,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: cinema.timings.map((timing) {
              final label = DateFormat('hh:mm a').format(timing.time);
              return GestureDetector(
                onTap: () => onShowtimeTap(timing),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '2D',
                        style: TextStyle(
                          color: Colors.yellow.shade400,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}