import 'package:flutter/material.dart';
import 'package:movieversego/data/models/movie.dart';
import 'package:movieversego/view/screens/movie_details_screen.dart';
import 'package:movieversego/view/widgets/network_poster.dart';

class SearchScreen extends SearchDelegate<String> {
  final List<Movie> movies;
  final int cityId;

  SearchScreen({
    required this.movies,
    required this.cityId,
  });

  @override
  String get searchFieldLabel => "Search Movie";

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = "";
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ""),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildMovieList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(
        child: Text(
          "Type a movie name",
          style: TextStyle(
            color: Colors.white54,
            fontSize: 18,
          ),
        ),
      );
    }

    return _buildMovieList(context);
  }

  Widget _buildMovieList(BuildContext context) {
    final results = movies.where((movie) {
      return movie.title
          .toLowerCase()
          .contains(query.toLowerCase().trim());
    }).toList();

    if (results.isEmpty) {
      return const Center(
        child: Text(
          "No Movies Found",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final movie = results[index];

        return ListTile(
          leading: SizedBox(
            width: 50,
            height: 70,
            child: NetworkPoster(
              imagePath: movie.imagePath,
            ),
          ),
          title: Text(
            movie.title,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            movie.genre ?? "",
            style: const TextStyle(color: Colors.white54),
          ),
          onTap: () {
            close(context, "");

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MovieDetailScreen(
                  movie: movie,
                  cityId: cityId,
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData.dark().copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white54),
      ),
    );
  }
}