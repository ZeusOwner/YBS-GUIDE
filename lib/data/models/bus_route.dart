import 'bus_stop.dart';
import 'schedule.dart';

class BusRoute {
  const BusRoute({
    required this.id,
    required this.routeNumber,
    required this.nameEn,
    required this.nameMm,
    required this.startStopEn,
    required this.startStopMm,
    required this.endStopEn,
    required this.endStopMm,
    required this.stops,
    required this.schedule,
    required this.farePrice,
    required this.isAirCon,
    required this.color,
    required this.routePath,
    this.source = 'official_seed',
    this.sourceUrl =
        'https://jicayangonbusta.wordpress.com/up-to-date-information-for-gtfs/',
    this.lastUpdated = '2026-05-30',
    this.confidence = 0.6,
  });

  final String id;
  final String routeNumber;
  final String nameEn;
  final String nameMm;
  final String startStopEn;
  final String startStopMm;
  final String endStopEn;
  final String endStopMm;
  final List<BusStop> stops;
  final List<Schedule> schedule;
  final double farePrice;
  final bool isAirCon;
  final String color;
  final List<RouteCoordinate> routePath;
  final String source;
  final String sourceUrl;
  final String lastUpdated;
  final double confidence;

  String get name => _combined(nameEn, nameMm);
  String get startStop => _combined(startStopEn, startStopMm);
  String get endStop => _combined(endStopEn, endStopMm);

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    final legacyName = _splitLegacy(json['name'] as String?);
    final legacyStart = _splitLegacy(json['startStop'] as String?);
    final legacyEnd = _splitLegacy(json['endStop'] as String?);
    final routeId = json['id'] as String;
    final stops = (json['stops'] as List<dynamic>? ?? []).map((stop) {
      final busStop = BusStop.fromJson(stop as Map<String, dynamic>);
      return busStop.routes.isEmpty
          ? busStop.copyWith(routes: [routeId])
          : busStop;
    }).toList();
    final routePath = (json['routePath'] as List<dynamic>?)
        ?.map((point) => RouteCoordinate.fromJsonValue(point))
        .toList();

    return BusRoute(
      id: routeId,
      routeNumber: json['routeNumber'] as String,
      nameEn: json['nameEn'] as String? ?? legacyName.en,
      nameMm: json['nameMm'] as String? ?? legacyName.mm,
      startStopEn: json['startStopEn'] as String? ?? legacyStart.en,
      startStopMm: json['startStopMm'] as String? ?? legacyStart.mm,
      endStopEn: json['endStopEn'] as String? ?? legacyEnd.en,
      endStopMm: json['endStopMm'] as String? ?? legacyEnd.mm,
      stops: stops,
      schedule: _scheduleFromJson(json['schedule'], routeId),
      farePrice: (json['farePrice'] as num).toDouble(),
      isAirCon: json['isAirCon'] as bool,
      color: json['color'] as String,
      source: json['source'] as String? ?? 'official_seed',
      sourceUrl:
          json['sourceUrl'] as String? ??
          'https://jicayangonbusta.wordpress.com/up-to-date-information-for-gtfs/',
      lastUpdated: json['lastUpdated'] as String? ?? '2026-05-30',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.6,
      routePath:
          routePath ??
          stops
              .map(
                (stop) => RouteCoordinate(
                  latitude: stop.latitude,
                  longitude: stop.longitude,
                ),
              )
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routeNumber': routeNumber,
      'nameEn': nameEn,
      'nameMm': nameMm,
      'startStopEn': startStopEn,
      'startStopMm': startStopMm,
      'endStopEn': endStopEn,
      'endStopMm': endStopMm,
      'stops': stops.map((stop) => stop.toJson()).toList(),
      'schedule': schedule.map((item) => item.toJson()).toList(),
      'farePrice': farePrice,
      'isAirCon': isAirCon,
      'color': color,
      'routePath': routePath.map((point) => point.toJson()).toList(),
      'source': source,
      'sourceUrl': sourceUrl,
      'lastUpdated': lastUpdated,
      'confidence': confidence,
    };
  }

  BusRoute copyWith({
    String? id,
    String? routeNumber,
    String? nameEn,
    String? nameMm,
    String? startStopEn,
    String? startStopMm,
    String? endStopEn,
    String? endStopMm,
    List<BusStop>? stops,
    List<Schedule>? schedule,
    double? farePrice,
    bool? isAirCon,
    String? color,
    List<RouteCoordinate>? routePath,
    String? source,
    String? sourceUrl,
    String? lastUpdated,
    double? confidence,
  }) {
    return BusRoute(
      id: id ?? this.id,
      routeNumber: routeNumber ?? this.routeNumber,
      nameEn: nameEn ?? this.nameEn,
      nameMm: nameMm ?? this.nameMm,
      startStopEn: startStopEn ?? this.startStopEn,
      startStopMm: startStopMm ?? this.startStopMm,
      endStopEn: endStopEn ?? this.endStopEn,
      endStopMm: endStopMm ?? this.endStopMm,
      stops: stops ?? this.stops,
      schedule: schedule ?? this.schedule,
      farePrice: farePrice ?? this.farePrice,
      isAirCon: isAirCon ?? this.isAirCon,
      color: color ?? this.color,
      routePath: routePath ?? this.routePath,
      source: source ?? this.source,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      confidence: confidence ?? this.confidence,
    );
  }
}

class RouteCoordinate {
  const RouteCoordinate({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  factory RouteCoordinate.fromJson(Map<String, dynamic> json) {
    return RouteCoordinate(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  factory RouteCoordinate.fromJsonValue(Object? value) {
    if (value is List && value.length == 2) {
      return RouteCoordinate(
        latitude: (value[0] as num).toDouble(),
        longitude: (value[1] as num).toDouble(),
      );
    }
    return RouteCoordinate.fromJson(value as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() {
    return {'latitude': latitude, 'longitude': longitude};
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

List<Schedule> _scheduleFromJson(Object? value, String routeId) {
  if (value is List) {
    return value
        .map((item) => Schedule.fromJson(item as Map<String, dynamic>))
        .toList();
  }
  if (value is Map<String, dynamic>) {
    return [
      _directionScheduleFromJson(value['forward'], routeId, 'forward'),
      _directionScheduleFromJson(value['return'], routeId, 'reverse'),
    ];
  }
  return [];
}

Schedule _directionScheduleFromJson(
  Object? value,
  String routeId,
  String direction,
) {
  final json = value as Map<String, dynamic>? ?? const {};
  final times = (json['departureTimes'] as List<dynamic>? ?? [])
      .map((time) => time as String)
      .toList();
  return Schedule(
    routeId: routeId,
    direction: RouteDirection.fromJson(direction),
    departureTimes: times,
    operatingDays: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    firstBus: times.isEmpty ? '' : times.first,
    lastBus: times.isEmpty ? '' : times.last,
  );
}
