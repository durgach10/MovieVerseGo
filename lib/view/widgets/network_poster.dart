import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:movieversego/data/moviemax_api.dart';

class NetworkPoster extends StatelessWidget {
  const NetworkPoster({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  final String? imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final url = MovieMaxApi.imageUrl(imagePath);

    Widget child;

    if (url.isEmpty) {
      child = _placeholder();
    } else {
      if (kDebugMode) {
        debugPrint('Loading Image : $url');
      }

      print(MovieMaxApi.imageUrl(imagePath));

      child = Image.network(
        url,
        headers: MovieMaxApi.imageHeaders,
        fit: fit,
        width: width,
        height: height,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,

        loadingBuilder: (context, widget, progress) {
          if (progress == null) {
            return widget;
          }
          return _loading();
        },

        errorBuilder: (context, error, stackTrace) {
          if (kDebugMode) {
            debugPrint('--------------------------------');
            debugPrint('Image Load Failed');
            debugPrint('URL : $url');
            debugPrint(error.toString());
            debugPrint('--------------------------------');
          }

          return _placeholder();
        },
      );
    }

    if (borderRadius != null) {
      child = ClipRRect(
        borderRadius: borderRadius!,
        child: child,
      );
    }

    return child;
  }

  Widget _loading() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF1A0A1E),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.yellow,
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF1A0A1E),
      alignment: Alignment.center,
      child: const Icon(
        Icons.movie_creation_outlined,
        color: Colors.white38,
        size: 42,
      ),
    );
  }
}