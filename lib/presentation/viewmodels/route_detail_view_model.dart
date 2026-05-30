import 'package:flutter/foundation.dart';

import '../../data/models/bus_route.dart';
import '../../data/models/bus_stop.dart';
import '../../data/models/schedule.dart';
import '../../data/repositories/ybs_repository.dart';

class RouteDetailViewModel extends ChangeNotifier {
  RouteDetailViewModel(this._repository);

  final YbsRepository _repository;

  BusRoute? route;
  bool isLoading = false;
  int selectedTabIndex = 0;
  RouteDirection selectedDirection = RouteDirection.forward;
  BusStop? selectedStop;

  List<Schedule> get schedules => route?.schedule ?? [];

  Schedule? get selectedSchedule {
    for (final schedule in schedules) {
      if (schedule.direction == selectedDirection) {
        return schedule;
      }
    }
    return schedules.isEmpty ? null : schedules.first;
  }

  String? get nextDeparture {
    final schedule = selectedSchedule;
    if (schedule == null) {
      return null;
    }

    final now = DateTime.now();
    for (final departure in schedule.departureTimes) {
      final parts = departure.split(':');
      if (parts.length != 2) {
        continue;
      }
      final departureTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.tryParse(parts[0]) ?? 0,
        int.tryParse(parts[1]) ?? 0,
      );
      if (departureTime.isAfter(now)) {
        return departure;
      }
    }
    return null;
  }

  Future<void> load(String routeId) async {
    isLoading = true;
    notifyListeners();

    route = await _repository.getRouteById(routeId);
    selectedDirection = RouteDirection.forward;
    selectedStop = null;
    isLoading = false;
    notifyListeners();
  }

  void selectTab(int index) {
    selectedTabIndex = index;
    notifyListeners();
  }

  void selectDirection(RouteDirection direction) {
    selectedDirection = direction;
    notifyListeners();
  }

  void selectStop(BusStop stop) {
    selectedStop = stop;
    notifyListeners();
  }
}
