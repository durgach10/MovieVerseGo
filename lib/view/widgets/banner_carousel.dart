import 'package:flutter/material.dart';
import 'package:movieversego/data/models/banner.dart';
import 'package:movieversego/data/models/movie.dart';
import 'package:movieversego/view/widgets/network_poster.dart';


class BannerCarousel extends StatefulWidget {
  const BannerCarousel({
    super.key,
    required this.banners,
    this.fallbackMovies = const [],
  });

  final List<PromoBanner> banners;
  final List<Movie> fallbackMovies;

  static const _bannerAspectRatio = 16 / 9;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = _buildSlides();

    if (slides.isEmpty) {
      return _emptyPlaceholder();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: BannerCarousel._bannerAspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: slides.length == 1
                  ? slides.first
                  : PageView.builder(
                      controller: _pageController,
                      itemCount: slides.length,
                      onPageChanged: (index) =>
                          setState(() => _currentPage = index),
                      itemBuilder: (_, index) => slides[index],
                    ),
            ),
          ),
          if (slides.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(slides.length, (index) {
                final selected = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: selected ? 18 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: selected ? Colors.yellow : Colors.white38,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildSlides() {
    if (widget.banners.isNotEmpty) {
      return widget.banners.map((banner) {
        final imagePath = banner.mobileImageUrl.isNotEmpty
            ? banner.mobileImageUrl
            : banner.imageUrl;
        return _PromoBannerSlide(
          imagePath: imagePath,
          title: banner.title,
          fitForBanner: true,
        );
      }).toList();
    }

    return widget.fallbackMovies
        .where((movie) => movie.imagePath.isNotEmpty)
        .map(
          (movie) => _MovieBannerSlide(
            imagePath: movie.imagePath,
            title: movie.title,
          ),
        )
        .toList();
  }

  Widget _emptyPlaceholder() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: AspectRatio(
        aspectRatio: BannerCarousel._bannerAspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: const ColoredBox(
            color: Color(0xFF1A0A1E),
            child: Center(
              child: Icon(Icons.movie, size: 56, color: Colors.white38),
            ),
          ),
        ),
      ),
    );
  }
}

class _PromoBannerSlide extends StatelessWidget {
  const _PromoBannerSlide({
    required this.imagePath,
    this.title,
    this.fitForBanner = false,
  });

  final String imagePath;
  final String? title;
  final bool fitForBanner;

  @override
  Widget build(BuildContext context) {
    return _BannerImageFrame(
      imagePath: imagePath,
      title: title,
      fitForBanner: fitForBanner,
    );
  }
}

class _MovieBannerSlide extends StatelessWidget {
  const _MovieBannerSlide({
    required this.imagePath,
    required this.title,
  });

  final String imagePath;
  final String title;

  @override
  Widget build(BuildContext context) {
    return _BannerImageFrame(
      imagePath: imagePath,
      title: title,
      fitForBanner: false,
    );
  }
}

class _BannerImageFrame extends StatelessWidget {
  const _BannerImageFrame({
    required this.imagePath,
    this.title,
    this.fitForBanner = false,
  });

  final String imagePath;
  final String? title;
  final bool fitForBanner;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF1A0A1E),
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          if (!fitForBanner) ...[
            Positioned.fill(
              child: NetworkPoster(
                imagePath: imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
          ],
          Positioned.fill(
            child: NetworkPoster(
              imagePath: imagePath,
              fit: fitForBanner ? BoxFit.cover : BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.05),
                  Colors.black.withValues(alpha: 0.25),
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
          if (title != null && title!.trim().isNotEmpty)
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: Text(
                title!.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}