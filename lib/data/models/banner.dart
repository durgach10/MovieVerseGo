class PromoBanner {
  const PromoBanner({
    required this.id,
    required this.imageUrl,
    required this.mobileImageUrl,
    this.title,
    this.youtubeUrl,
    required this.cityId,
  });

  final int id;
  final String imageUrl;
  final String mobileImageUrl;
  final String? title;
  final String? youtubeUrl;
  final int cityId;

  factory PromoBanner.fromJson(Map<String, dynamic> json) {
    return PromoBanner(
      id: json['id'] as int,
      imageUrl: json['image_path'] as String? ?? '',
      mobileImageUrl: json['mobile_image_path'] as String? ?? '',
      title: json['Film_strTitle'] as String?,
      youtubeUrl: json['youtube_url'] as String?,
      cityId: json['city_id'] as int? ?? 0,
    );
  }

  String imageForMobile(String Function(String?) resolveUrl) {
    if (mobileImageUrl.isNotEmpty) {
      return resolveUrl(mobileImageUrl);
    }
    return resolveUrl(imageUrl);
  }
}