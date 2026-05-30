class BusStop {
  const BusStop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.routes,
    required this.landmark,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final List<String> routes;
  final String landmark;

  factory BusStop.fromJson(Map<String, dynamic> json) {
    return BusStop(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      routes: (json['routes'] as List<dynamic>? ?? [])
          .map((routeId) => routeId as String)
          .toList(),
      landmark: json['landmark'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'routes': routes,
      'landmark': landmark,
    };
  }

  BusStop copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    List<String>? routes,
    String? landmark,
  }) {
    return BusStop(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      routes: routes ?? this.routes,
      landmark: landmark ?? this.landmark,
    );
  }
}
