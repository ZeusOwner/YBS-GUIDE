class FavoriteRoute {
  const FavoriteRoute({
    required this.routeId,
    required this.savedAt,
    required this.sortOrder,
    this.nickname,
  });

  final String routeId;
  final DateTime savedAt;
  final int sortOrder;
  final String? nickname;

  factory FavoriteRoute.fromJson(Map<String, dynamic> json) {
    return FavoriteRoute(
      routeId: json['routeId'] as String,
      savedAt: DateTime.parse(json['savedAt'] as String),
      sortOrder: json['sortOrder'] as int? ?? 0,
      nickname: json['nickname'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'routeId': routeId,
      'savedAt': savedAt.toIso8601String(),
      'sortOrder': sortOrder,
      'nickname': nickname,
    };
  }

  FavoriteRoute copyWith({
    String? routeId,
    DateTime? savedAt,
    int? sortOrder,
    String? nickname,
  }) {
    return FavoriteRoute(
      routeId: routeId ?? this.routeId,
      savedAt: savedAt ?? this.savedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      nickname: nickname ?? this.nickname,
    );
  }
}
