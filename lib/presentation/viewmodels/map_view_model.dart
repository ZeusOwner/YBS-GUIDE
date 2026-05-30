import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/utils/string_extensions.dart';
import '../../data/models/bus_route.dart';
import '../../data/models/bus_stop.dart';
import '../../data/repositories/ybs_repository.dart';

enum MapRouteFilter { all, airCon, regular }

class MapViewModel extends ChangeNotifier {
  MapViewModel(this._repository);

  static const LatLng yangonCenter = LatLng(16.8661, 96.1951);
  static const double nearbyRadiusMeters = 500;

  final YbsRepository _repository;
  final Distance _distance = const Distance();

  List<BusRoute> routes = [];
  List<BusStop> stops = [];
  BusRoute? selectedRoute;
  LatLng? userLocation;
  String searchQuery = '';
  bool isLoading = false;
  bool hasTileError = false;
  double zoom = 12;
  MapRouteFilter filter = MapRouteFilter.all;

  List<BusRoute> get visibleRoutes {
    return routes.where((route) {
      return switch (filter) {
        MapRouteFilter.all => true,
        MapRouteFilter.airCon => route.isAirCon,
        MapRouteFilter.regular => !route.isAirCon,
      };
    }).toList();
  }

  List<BusStop> get visibleStops {
    final routeIds = visibleRoutes.map((route) => route.id).toSet();
    return stops
        .where((stop) => stop.routes.any(routeIds.contains))
        .fold<Map<String, BusStop>>({}, (unique, stop) {
          unique[stop.id] = stop;
          return unique;
        })
        .values
        .toList();
  }

  List<BusStop> get nearbyStops {
    final location = userLocation ?? yangonCenter;
    return visibleStops.where((stop) {
      final distance = _distance(
        location,
        LatLng(stop.latitude, stop.longitude),
      );
      return distance <= nearbyRadiusMeters;
    }).toList();
  }

  List<Object> get searchResults {
    final query = searchQuery.trim();
    if (query.isEmpty) {
      return [];
    }

    final routeMatches = routes.where((route) {
      return route.routeNumber.containsIgnoreCase(query) ||
          route.name.containsIgnoreCase(query) ||
          route.startStop.containsIgnoreCase(query) ||
          route.endStop.containsIgnoreCase(query);
    });
    final stopMatches = stops.where((stop) {
      return stop.name.containsIgnoreCase(query) ||
          stop.landmark.containsIgnoreCase(query);
    });

    return [...routeMatches, ...stopMatches].take(8).toList();
  }

  List<BusRoute> getRoutesForStop(String stopId) {
    return routes
        .where((route) => route.stops.any((stop) => stop.id == stopId))
        .toList();
  }

  Future<void> loadMapData() async {
    isLoading = true;
    notifyListeners();

    routes = await _repository.getRoutes();
    stops = await _repository.getStops();

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadStops() => loadMapData();

  void selectRoute(BusRoute route) {
    selectedRoute = selectedRoute?.id == route.id ? null : route;
    notifyListeners();
  }

  void setFilter(MapRouteFilter value) {
    filter = value;
    selectedRoute = null;
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    searchQuery = '';
    notifyListeners();
  }

  void updateZoom(double value) {
    zoom = value;
    notifyListeners();
  }

  void markTileError() {
    if (hasTileError) {
      return;
    }
    hasTileError = true;
    notifyListeners();
  }

  Future<LatLng?> requestUserLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition();
    userLocation = LatLng(position.latitude, position.longitude);
    notifyListeners();
    return userLocation;
  }
}
