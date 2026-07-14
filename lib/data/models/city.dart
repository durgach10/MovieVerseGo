class City {
  const City({
    required this.id,
    required this.name,
    required this.stateName,
  });

  final int id;
  final String name;
  final String stateName;

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['city_id'] as int,
      name: json['city_name'] as String,
      stateName: json['state_name'] as String? ?? '',
    );
  }

  String get displayLabel => stateName.isEmpty ? name : '$name, $stateName';
}