import 'bus_stop.dart';
import 'schedule.dart';

class BusRoute {
  const BusRoute({
    required this.id,
    required this.routeNumber,
    required this.name,
    required this.startStop,
    required this.endStop,
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
  final String name;
  final String startStop;
  final String endStop;
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

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    final stops = (json['stops'] as List<dynamic>? ?? [])
        .map((stop) => BusStop.fromJson(stop as Map<String, dynamic>))
        .toList();
    final routePath = (json['routePath'] as List<dynamic>?)
        ?.map(
          (point) => RouteCoordinate.fromJson(point as Map<String, dynamic>),
        )
        .toList();

    return BusRoute(
      id: json['id'] as String,
      routeNumber: json['routeNumber'] as String,
      name: json['name'] as String,
      startStop: json['startStop'] as String,
      endStop: json['endStop'] as String,
      stops: stops,
      schedule: (json['schedule'] as List<dynamic>? ?? [])
          .map((item) => Schedule.fromJson(item as Map<String, dynamic>))
          .toList(),
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
      'name': name,
      'startStop': startStop,
      'endStop': endStop,
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
    String? name,
    String? startStop,
    String? endStop,
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
      name: name ?? this.name,
      startStop: startStop ?? this.startStop,
      endStop: endStop ?? this.endStop,
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

  Map<String, dynamic> toJson() {
    return {'latitude': latitude, 'longitude': longitude};
  }
}
