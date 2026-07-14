import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:movieversego/data/models/banner.dart';
import 'package:movieversego/data/models/cinema.dart';
import 'package:movieversego/data/models/city.dart';
import 'package:movieversego/data/models/movie.dart';
import 'package:movieversego/data/models/seat_layout.dart';
import 'package:movieversego/data/models/session.dart';

class MovieMaxApi {
  MovieMaxApi({http.Client? client}) : _client = client ?? http.Client();

  static const baseUrl = 'https://moviemax.co.in';
  static const apiBase = '$baseUrl/api/v1.0/webapp';

  static const imageHeaders = {
    'Referer': 'https://moviemax.co.in/',
    'User-Agent': 'Mozilla/5.0',
  };

  final http.Client _client;
  final Map<String, Set<String>> _filmCinemaCache = {};

  static String imageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return '';
    }
    if (path.startsWith('http')) {
      return path;
    }
    return '$baseUrl$path';
  }

  Future<List<City>> fetchCities() async {
    final response = await _get('$apiBase/locations/cities');
    return _parseList(response.body, City.fromJson);
  }

  Future<List<Cinema>> fetchCinemas() async {
    final response = await _get('$apiBase/cinemas');
    return _parseList(response.body, Cinema.fromJson);
  }

  Future<List<PromoBanner>> fetchBanners(int cityId) async {
    final response = await _get('$apiBase/banners?city_id=$cityId');
    final banners = _parseList(response.body, PromoBanner.fromJson);
    return banners.where((banner) => banner.cityId == cityId).toList();
  }

  Future<List<Movie>> fetchNowShowing(
    int cityId, {
    List<Cinema>? cinemas,
  }) async {
    final movies = await _fetchRawNowShowing(cityId);
    final cinemaList = cinemas ?? await fetchCinemas();
    final cityCinemaIds = cinemaList
        .where((cinema) => cinema.cityId == cityId)
        .map((cinema) => cinema.id)
        .toSet();

    if (cityCinemaIds.isEmpty) {
      return [];
    }

    return _filterMoviesForCinemas(movies, cityCinemaIds);
  }

  Future<List<Movie>> _fetchRawNowShowing(int cityId) async {
    final response = await _client.post(
      Uri.parse('$apiBase/now-showing'),
      headers: _jsonHeaders,
      body: jsonEncode({'user_id': null, 'city_id': cityId}),
    );
    _ensureSuccess(response);
    return _parseList(response.body, Movie.fromNowShowingJson);
  }

  Future<List<Movie>> _filterMoviesForCinemas(
    List<Movie> movies,
    Set<String> cityCinemaIds,
  ) async {
    const batchSize = 8;
    final available = <Movie>[];

    for (var start = 0; start < movies.length; start += batchSize) {
      final end = (start + batchSize).clamp(0, movies.length);
      final batch = movies.sublist(start, end);

      final checks = await Future.wait(
        batch.map((movie) => _movieAvailableInCinemas(movie, cityCinemaIds)),
      );

      for (var i = 0; i < batch.length; i++) {
        if (checks[i]) {
          available.add(batch[i]);
        }
      }
    }

    return available;
  }

  Future<bool> _movieAvailableInCinemas(
    Movie movie,
    Set<String> cityCinemaIds,
  ) async {
    final filmCode = movie.filmCode;
    if (filmCode == null || filmCode.isEmpty) {
      return false;
    }

    final cinemaIds = await _cinemaIdsForFilm(filmCode);
    return cinemaIds.any(cityCinemaIds.contains);
  }

  Future<Set<String>> _cinemaIdsForFilm(String filmCode) async {
    final cached = _filmCinemaCache[filmCode];
    if (cached != null) {
      return cached;
    }

    try {
      final session = await _fetchRawSessions(filmCode);
      final ids = session.cinemas.map((cinema) => cinema.id).toSet();
      _filmCinemaCache[filmCode] = ids;
      return ids;
    } catch (_) {
      _filmCinemaCache[filmCode] = {};
      return {};
    }
  }

  Future<SessionData> _fetchRawSessions(String filmCode, {DateTime? date}) async {
    final path = date == null
        ? DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now())
        : DateFormat('yyyy-MM-dd').format(date);

    final encodedPath = Uri.encodeComponent(path);
    final response = await _get('$apiBase/session/$filmCode/$encodedPath');
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (decoded['status'] != true) {
      throw Exception(decoded['message'] ?? 'Failed to load sessions');
    }

    return SessionData.fromJson(decoded['data'] as Map<String, dynamic>);
  }

  Future<List<Movie>> fetchComingSoon(int cityId) async {
    final response = await _get('$apiBase/coming-soon?city_id=$cityId');
    return _parseList(response.body, Movie.fromComingSoonJson);
  }

  Future<SessionData> fetchSessions(
    String filmCode, {
    DateTime? date,
    int? cityId,
  }) async {
    var sessionData = await _fetchRawSessions(filmCode, date: date);

    if (cityId != null) {
      final cinemas = await fetchCinemas();
      final cityCinemaIds = cinemas
          .where((cinema) => cinema.cityId == cityId)
          .map((cinema) => cinema.id)
          .toSet();
      sessionData = sessionData.filterByCinemaIds(cityCinemaIds);
    }

    return sessionData;
  }

  Future<SeatLayoutData> fetchSeatLayout(int sessionId, String cinemaId) async {
    final response = await _get('$apiBase/seat_layout/$sessionId/$cinemaId');
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (decoded['status'] != true) {
      throw Exception(decoded['message'] ?? 'Failed to load seat layout');
    }

    return SeatLayoutData.fromJson(decoded['data'] as Map<String, dynamic>);
  }

  Future<http.Response> _get(String url) async {
    final response = await _client.get(
      Uri.parse(url),
      headers: imageHeaders,
    );
    _ensureSuccess(response);
    return response;
  }

  Map<String, String> get _jsonHeaders => {
        ...imageHeaders,
        'Content-Type': 'application/json',
      };

  List<T> _parseList<T>(
    String body,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    if (decoded['status'] != true) {
      throw Exception(decoded['message'] ?? 'Request failed');
    }

    final data = decoded['data'] as List<dynamic>? ?? [];
    return data.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }
  }
}