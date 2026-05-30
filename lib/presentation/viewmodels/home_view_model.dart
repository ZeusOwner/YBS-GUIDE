import 'package:flutter/foundation.dart';

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
    routes = await _repository.getRoutes();
    isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => load();
}
