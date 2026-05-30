import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/bus_route.dart';
import '../../data/models/bus_stop.dart';
import '../../data/repositories/ybs_repository.dart';
import '../../data/services/data_sync_service.dart';
import '../../data/services/quick_access_service.dart';

enum NearbyStopsState { idle, loading, permissionDenied, ready, empty, error }

class NearbyStop {
  const NearbyStop({
    required this.stop,
    required this.distanceMeters,
    required this.routeNumbers,
    required this.routeIds,
  });

  final BusStop stop;
  final double distanceMeters;
  final List<String> routeNumbers;
  final List<String> routeIds;
}

class HomeViewModel extends ChangeNotifier {
  HomeViewModel(
    this._repository,
    this._dataSyncService,
    this._quickAccessService,
  );

  final YbsRepository _repository;
  final DataSyncService _dataSyncService;
  final QuickAccessService _quickAccessService;
  List<BusRoute> routes = [];
  List<NearbyStop> nearbyStops = [];
  NearbyStopsState nearbyStopsState = NearbyStopsState.idle;
  BusRoute? homeRoute;
  BusRoute? workRoute;
  bool isLoading = false;
  bool isLocationPermissionGranted = false;
  String? syncMessage;
  bool _hasStartedSync = false;

  List<BusRoute> get recentRoutes => routes.take(4).toList();

  List<BusRoute> get popularRoutes => routes.take(6).toList();

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    final results = await Future.wait([
      _repository.getRoutes(),
      _hasLocationPermission(),
    ]);
    routes = results[0] as List<BusRoute>;
    isLocationPermissionGranted = results[1] as bool;
    await _loadQuickAccessRoutes();
    isLoading = false;
    notifyListeners();

    await loadNearbyStops();
    _startBackgroundSync();
  }

  Future<void> refresh() => load();

  Future<void> loadNearbyStops() async {
    nearbyStopsState = NearbyStopsState.loading;
    notifyListeners();

    try {
      var permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        isLocationPermissionGranted = false;
        nearbyStops = [];
        nearbyStopsState = NearbyStopsState.permissionDenied;
        notifyListeners();
        return;
      }

      isLocationPermissionGranted = true;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      final stops = await _repository.getStops();
      final sourceRoutes = routes.isEmpty
          ? await _repository.getRoutes()
          : routes;
      final distance = const Distance();
      final userPoint = LatLng(position.latitude, position.longitude);

      final matches =
          stops
              .map((stop) {
                final meters = distance(
                  userPoint,
                  LatLng(stop.latitude, stop.longitude),
                );
                final matchingRoutes = sourceRoutes
                    .where(
                      (route) =>
                          stop.routes.contains(route.id) ||
                          route.stops.any(
                            (candidate) => candidate.id == stop.id,
                          ),
                    )
                    .toList();
                return NearbyStop(
                  stop: stop,
                  distanceMeters: meters,
                  routeNumbers: matchingRoutes
                      .map((route) => route.routeNumber)
                      .toSet()
                      .toList(),
                  routeIds: matchingRoutes
                      .map((route) => route.id)
                      .toSet()
                      .toList(),
                );
              })
              .where((nearbyStop) => nearbyStop.distanceMeters <= 800)
              .toList()
            ..sort(
              (left, right) =>
                  left.distanceMeters.compareTo(right.distanceMeters),
            );

      nearbyStops = matches.take(5).toList();
      nearbyStopsState = nearbyStops.isEmpty
          ? NearbyStopsState.empty
          : NearbyStopsState.ready;
    } catch (_) {
      nearbyStops = [];
      nearbyStopsState = NearbyStopsState.error;
    }
    notifyListeners();
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openAppSettings();
  }

  Future<void> setQuickAccessRoute(String type, String routeId) async {
    if (type == 'work') {
      await _quickAccessService.setWorkRouteId(routeId);
    } else {
      await _quickAccessService.setHomeRouteId(routeId);
    }
    await _loadQuickAccessRoutes();
    notifyListeners();
  }

  Future<void> clearQuickAccessRoute(String type) async {
    await _quickAccessService.clearRoute(type);
    if (type == 'work') {
      workRoute = null;
    } else {
      homeRoute = null;
    }
    notifyListeners();
  }

  String? consumeSyncMessage() {
    final message = syncMessage;
    syncMessage = null;
    return message;
  }

  void _startBackgroundSync() {
    if (_hasStartedSync) {
      return;
    }
    _hasStartedSync = true;
    _dataSyncService.checkAndSync().then((result) async {
      if (!result.success || !result.updated) {
        return;
      }
      routes = await _repository.getRoutes();
      syncMessage = 'Route data updated to v${result.version}';
      notifyListeners();
    });
  }

  Future<bool> _hasLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadQuickAccessRoutes() async {
    final homeRouteId = await _quickAccessService.getHomeRouteId();
    final workRouteId = await _quickAccessService.getWorkRouteId();
    homeRoute = homeRouteId == null
        ? null
        : await _repository.getRouteById(homeRouteId);
    workRoute = workRouteId == null
        ? null
        : await _repository.getRouteById(workRouteId);
  }
}
