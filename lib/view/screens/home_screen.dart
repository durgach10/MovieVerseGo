import 'package:flutter/material.dart';
import 'package:movie_max/data/models/banner.dart';
import 'package:movie_max/data/models/cinema.dart';
import 'package:movie_max/data/models/city.dart';
import 'package:movie_max/data/models/movie.dart';
import 'package:movie_max/data/moviemax_api.dart';
import 'package:movie_max/view/screens/movie_details_screen.dart';
import 'package:movie_max/view/widgets/banner_carousel.dart';
import 'package:movie_max/view/widgets/bottom_nav_bar.dart';
import 'package:movie_max/view/widgets/custom_app_bar.dart';
import 'package:movie_max/view/widgets/movie_card.dart';
import 'package:movie_max/view/screens/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MovieMaxApi _api = MovieMaxApi();

  int _bottomNavIndex = 0;
  int _tabIndex = 0;

  bool _isLoading = true;
  String? _errorMessage;

  List<City> _cities = [];
  List<Cinema> _cinemas = [];
  List<PromoBanner> _banners = [];
  List<Movie> _nowShowing = [];
  List<Movie> _comingSoon = [];

  City? _selectedCity;

  List<Movie> get _activeMovies => _tabIndex == 0 ? _nowShowing : _comingSoon;

  List<Cinema> get _cityCinemas {
    final cityId = _selectedCity?.id;
    if (cityId == null) {
      return [];
    }
    return _cinemas.where((cinema) => cinema.cityId == cityId).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _api.fetchCities(),
        _api.fetchCinemas(),
      ]);

      final cities = results[0] as List<City>;
      final cinemas = results[1] as List<Cinema>;

      if (cities.isEmpty) {
        throw Exception('No cities available');
      }

      final defaultCity = cities.firstWhere(
        (city) => city.id == 55,
        orElse: () => cities.first,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _cities = cities;
        _cinemas = cinemas;
        _selectedCity = defaultCity;
      });

      await _loadCityContent(defaultCity.id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _loadCityContent(int cityId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _api.fetchBanners(cityId),
        _api.fetchNowShowing(cityId, cinemas: _cinemas),
        _api.fetchComingSoon(cityId),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _banners = results[0] as List<PromoBanner>;
        _nowShowing = results[1] as List<Movie>;
        _comingSoon = results[2] as List<Movie>;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _onCitySelected(City city) async {
    Navigator.pop(context);
    if (_selectedCity?.id == city.id) {
      return;
    }

    setState(() => _selectedCity = city);
    await _loadCityContent(city.id);
  }

  void _showCityPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A0A1E),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select City',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _cities.length,
                  itemBuilder: (context, index) {
                    final city = _cities[index];
                    final selected = city.id == _selectedCity?.id;

                    return ListTile(
                      title: Text(
                        city.name,
                        style: TextStyle(
                          color: selected ? Colors.yellow : Colors.white,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        city.stateName,
                        style: const TextStyle(color: Colors.white54),
                      ),
                      trailing: selected
                          ? const Icon(Icons.check, color: Colors.yellow)
                          : null,
                      onTap: () => _onCitySelected(city),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B0D2F),
      appBar: CustomAppBar(
  selectedCity: _selectedCity,
  onCityTap: _cities.isEmpty ? null : _showCityPicker,
  onSearch: () {
    if (_selectedCity == null) return;

    showSearch(
      context: context,
      delegate: SearchScreen(
        movies: _activeMovies,
        cityId: _selectedCity!.id,
      ),
    );
  },
),
      body: _buildBody(),
      bottomNavigationBar: MovieBottomNavBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) => setState(() => _bottomNavIndex = index),
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null && _cities.isEmpty) {
      return _ErrorView(
        message: _errorMessage!,
        onRetry: _loadInitialData,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (_selectedCity != null) {
          await _loadCityContent(_selectedCity!.id);
        } else {
          await _loadInitialData();
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BannerCarousel(
              banners: _banners,
              fallbackMovies: _nowShowing.take(5).toList(),
            ),
            if (_cityCinemas.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${_cityCinemas.length} cinemas in ${_selectedCity?.name ?? ''}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _TabLabel(
                    label: 'Now Showing',
                    selected: _tabIndex == 0,
                    onTap: () => setState(() => _tabIndex = 0),
                  ),
                  const SizedBox(width: 24),
                  _TabLabel(
                    label: 'Coming Soon',
                    selected: _tabIndex == 1,
                    onTap: () => setState(() => _tabIndex = 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.yellow),
                ),
              )
            else if (_errorMessage != null)
              _ErrorView(
                message: _errorMessage!,
                onRetry: () {
                  if (_selectedCity != null) {
                    _loadCityContent(_selectedCity!.id);
                  }
                },
              )
            else if (_activeMovies.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No movies found for this city',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: _activeMovies.length,
                  itemBuilder: (context, index) {
                    final movie = _activeMovies[index];
                    return MovieCard(
                      title: movie.title,
                      imagePath: movie.imagePath,
                      onTap: _tabIndex == 0 && movie.filmCode != null
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MovieDetailScreen(
                                    movie: movie,
                                    cityId: _selectedCity!.id,
                                  ),
                                ),
                              );
                            }
                          : null,
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.yellow : Colors.white54,
              fontSize: 22,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          if (selected)
            Container(
              height: 3,
              width: 40,
              color: Colors.yellow,
            ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow,
              foregroundColor: Colors.black,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}