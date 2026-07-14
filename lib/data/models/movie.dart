class Movie {
  const Movie({
    required this.title,
    required this.imagePath,
    this.youtubeUrl,
    this.language,
    this.genre,
    this.filmCode,
  });

  final String title;
  final String imagePath;
  final String? youtubeUrl;
  final String? language;
  final String? genre;
  final String? filmCode;

  factory Movie.fromNowShowingJson(Map<String, dynamic> json) {
    return Movie(
      title: json['Film_strTitle'] as String? ?? 'Unknown',
      imagePath: json['image_path_1'] as String? ?? '',
      youtubeUrl: json['youtube_url'] as String?,
      language: json['language_name'] as String?,
      genre: json['genre_name'] as String?,
      filmCode: json['Film_strCode'] as String?,
    );
  }

  factory Movie.fromComingSoonJson(Map<String, dynamic> json) {
    return Movie(
      title: json['csm_film_title'] as String? ?? 'Unknown',
      imagePath: json['image_path_1'] as String? ?? '',
      youtubeUrl: json['youtube_url'] as String?,
      language: json['language_name'] as String?,
      genre: json['genre_name'] as String?,
    );
  }
}