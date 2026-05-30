import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/models/bus_route.dart';
import '../../data/repositories/ybs_repository.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._repository);

  final YbsRepository _repository;
  List<BusRoute> routes = [];
  bool isLoading = false;
  bool isLocationPermissionGranted = false;

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
    isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => load();

  Future<bool> _hasLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }
}
