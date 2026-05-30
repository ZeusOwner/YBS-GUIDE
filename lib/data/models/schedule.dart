enum RouteDirection {
  forward,
  reverse;

  static RouteDirection fromJson(String value) {
    return RouteDirection.values.firstWhere(
      (direction) => direction.name == value,
      orElse: () => RouteDirection.forward,
    );
  }
}

class Schedule {
  const Schedule({
    required this.routeId,
    required this.direction,
    required this.departureTimes,
    required this.operatingDays,
    required this.firstBus,
    required this.lastBus,
  });

  final String routeId;
  final RouteDirection direction;
  final List<String> departureTimes;
  final List<String> operatingDays;
  final String firstBus;
  final String lastBus;

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      routeId: json['routeId'] as String,
      direction: RouteDirection.fromJson(json['direction'] as String),
      departureTimes: (json['departureTimes'] as List<dynamic>? ?? [])
          .map((time) => time as String)
          .toList(),
      operatingDays: (json['operatingDays'] as List<dynamic>? ?? [])
          .map((day) => day as String)
          .toList(),
      firstBus: json['firstBus'] as String,
      lastBus: json['lastBus'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'routeId': routeId,
      'direction': direction.name,
      'departureTimes': departureTimes,
      'operatingDays': operatingDays,
      'firstBus': firstBus,
      'lastBus': lastBus,
    };
  }

  Schedule copyWith({
    String? routeId,
    RouteDirection? direction,
    List<String>? departureTimes,
    List<String>? operatingDays,
    String? firstBus,
    String? lastBus,
  }) {
    return Schedule(
      routeId: routeId ?? this.routeId,
      direction: direction ?? this.direction,
      departureTimes: departureTimes ?? this.departureTimes,
      operatingDays: operatingDays ?? this.operatingDays,
      firstBus: firstBus ?? this.firstBus,
      lastBus: lastBus ?? this.lastBus,
    );
  }
}
