class BusStop {
  const BusStop({
    required this.id,
    required this.nameEn,
    required this.nameMm,
    required this.latitude,
    required this.longitude,
    required this.routes,
    this.landmarkEn,
    this.landmarkMm,
  });

  final String id;
  final String nameEn;
  final String nameMm;
  final double latitude;
  final double longitude;
  final List<String> routes;
  final String? landmarkEn;
  final String? landmarkMm;

  String get name => _combined(nameEn, nameMm);
  String get landmark => _combined(landmarkEn ?? '', landmarkMm ?? '');

  factory BusStop.fromJson(Map<String, dynamic> json) {
    final legacyName = _splitLegacy(json['name'] as String?);
    final legacyLandmark = _splitLegacy(json['landmark'] as String?);

    return BusStop(
      id: json['id'] as String,
      nameEn: json['nameEn'] as String? ?? legacyName.en,
      nameMm: json['nameMm'] as String? ?? legacyName.mm,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      routes: (json['routes'] as List<dynamic>? ?? [])
          .map((routeId) => routeId as String)
          .toList(),
      landmarkEn: json['landmarkEn'] as String? ?? legacyLandmark.en,
      landmarkMm: json['landmarkMm'] as String? ?? legacyLandmark.mm,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameEn': nameEn,
      'nameMm': nameMm,
      'latitude': latitude,
      'longitude': longitude,
      'routes': routes,
      'landmarkEn': landmarkEn,
      'landmarkMm': landmarkMm,
    };
  }

  BusStop copyWith({
    String? id,
    String? nameEn,
    String? nameMm,
    double? latitude,
    double? longitude,
    List<String>? routes,
    String? landmarkEn,
    String? landmarkMm,
  }) {
    return BusStop(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      nameMm: nameMm ?? this.nameMm,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      routes: routes ?? this.routes,
      landmarkEn: landmarkEn ?? this.landmarkEn,
      landmarkMm: landmarkMm ?? this.landmarkMm,
    );
  }
}

({String en, String mm}) _splitLegacy(String? value) {
  if (value == null || value.trim().isEmpty) {
    return (en: '', mm: '');
  }
  final parts = value.split('/');
  if (parts.length < 2) {
    return (en: value.trim(), mm: '');
  }
  return (en: parts.first.trim(), mm: parts.sublist(1).join('/').trim());
}

String _combined(String en, String mm) {
  if (mm.trim().isEmpty) {
    return en;
  }
  if (en.trim().isEmpty) {
    return mm;
  }
  return '$en / $mm';
}
