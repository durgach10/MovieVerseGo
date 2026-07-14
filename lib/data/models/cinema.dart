class Cinema {
  const Cinema({
    required this.id,
    required this.name,
    required this.cityId,
    required this.address,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final int cityId;
  final String address;
  final String imageUrl;

  factory Cinema.fromJson(Map<String, dynamic> json) {
    return Cinema(
      id: json['Cinema_strID'] as String,
      name: json['Cinema_strName'] as String,
      cityId: json['city_id'] as int,
      address: json['cinema_address'] as String? ?? '',
      imageUrl: _firstImage(json),
    );
  }

  static String _firstImage(Map<String, dynamic> json) {
    for (var i = 1; i <= 10; i++) {
      final path = json['image_path_$i'] as String?;
      if (path != null && path.isNotEmpty) {
        return path;
      }
    }
    return '';
  }
}