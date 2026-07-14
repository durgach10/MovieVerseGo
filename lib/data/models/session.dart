class MovieDetailInfo {
  const MovieDetailInfo({
    required this.filmCode,
    required this.title,
    required this.imagePath,
    this.censor,
    this.duration,
    this.synopsis,
    this.language,
    this.genre,
    this.youtubeUrl,
    this.cityId,
  });

  final String filmCode;
  final String title;
  final String imagePath;
  final String? censor;
  final int? duration;
  final String? synopsis;
  final String? language;
  final String? genre;
  final String? youtubeUrl;
  final int? cityId;

  factory MovieDetailInfo.fromJson(Map<String, dynamic> json) {
    return MovieDetailInfo(
      filmCode: json['Film_strCode'] as String? ?? '',
      title: json['Film_strTitle'] as String? ?? 'Unknown',
      imagePath: json['image_path_1'] as String? ?? '',
      censor: json['Film_strCensor'] as String?,
      duration: json['Film_intDuration'] as int?,
      synopsis: json['movie_synopsis'] as String? ??
          json['Film_strDescription'] as String?,
      language: json['language_name'] as String?,
      genre: json['genre_name'] as String? ?? json['FilmCat_strName'] as String?,
      youtubeUrl: json['youtube_url'] as String?,
      cityId: json['city_id'] as int?,
    );
  }
}

class ShowTiming {
  const ShowTiming({
    required this.id,
    required this.time,
    required this.seatsAvailable,
    required this.totalSeats,
  });

  final int id;
  final DateTime time;
  final int seatsAvailable;
  final int totalSeats;

  factory ShowTiming.fromJson(Map<String, dynamic> json) {
    return ShowTiming(
      id: json['id'] as int,
      time: DateTime.parse(json['time'] as String),
      seatsAvailable: json['seats_available_for_sale'] as int? ?? 0,
      totalSeats: json['total_seats_available'] as int? ?? 0,
    );
  }
}

class CinemaShowtimes {
  const CinemaShowtimes({
    required this.id,
    required this.name,
    required this.address,
    required this.timings,
  });

  final String id;
  final String name;
  final String address;
  final List<ShowTiming> timings;

  factory CinemaShowtimes.fromJson(Map<String, dynamic> json) {
    final timings = (json['timing'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ShowTiming.fromJson)
        .toList();

    return CinemaShowtimes(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String? ?? '',
      timings: timings,
    );
  }
}

class SessionData {
  const SessionData({
    required this.movie,
    required this.dates,
    required this.cinemas,
  });

  final MovieDetailInfo movie;
  final List<DateTime> dates;
  final List<CinemaShowtimes> cinemas;

  factory SessionData.fromJson(Map<String, dynamic> json) {
    final movieJson = json['movieDetails'] as Map<String, dynamic>? ?? {};
    final sessionsArr = json['sessionsArr'] as List<dynamic>? ?? [];

    final dates = <DateTime>{};
    final cinemas = <CinemaShowtimes>[];

    for (final item in sessionsArr) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      for (final date in item['dateDetails'] as List<dynamic>? ?? []) {
        dates.add(DateTime.parse(date as String));
      }

      for (final cinema in item['sessionDetails'] as List<dynamic>? ?? []) {
        if (cinema is Map<String, dynamic>) {
          cinemas.add(CinemaShowtimes.fromJson(cinema));
        }
      }
    }

    final sortedDates = dates.toList()..sort();

    return SessionData(
      movie: MovieDetailInfo.fromJson(movieJson),
      dates: sortedDates,
      cinemas: cinemas,
    );
  }

  SessionData filterByCinemaIds(Set<String> cinemaIds) {
    return SessionData(
      movie: movie,
      dates: dates,
      cinemas: cinemas.where((cinema) => cinemaIds.contains(cinema.id)).toList(),
    );
  }
}