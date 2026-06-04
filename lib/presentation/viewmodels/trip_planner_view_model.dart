import 'package:flutter/foundation.dart';

import '../../data/models/bus_route.dart';
import '../../data/models/bus_stop.dart';
import '../../data/repositories/ybs_repository.dart';

class TripPlanResult {
  const TripPlanResult({
    required this.routes,
    required this.totalFare,
    required this.estimatedStops,
    this.transferStop,
  });

  final List<BusRoute> routes;
  final double totalFare;
  final int estimatedStops;
  final BusStop? transferStop;

  bool get isDirect => routes.length == 1;
}

class TripPlannerViewModel extends ChangeNotifier {
  TripPlannerViewModel(this._repository);

  final YbsRepository _repository;

  List<BusRoute> routes = [];
  List<BusStop> stops = [];
  BusStop? origin;
  BusStop? destination;
  List<TripPlanResult> results = [];
  String? resultNote;
  bool isLoading = false;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    routes = await _repository.getRoutes();
    stops = routes
        .expand((route) => route.stops)
        .fold<Map<String, BusStop>>({}, (unique, stop) {
          unique[stop.id] = stop;
          return unique;
        })
        .values
        .toList();

    isLoading = false;
    notifyListeners();
  }

  void setOrigin(BusStop stop) {
    origin = stop;
    notifyListeners();
  }

  void setDestination(BusStop stop) {
    destination = stop;
    notifyListeners();
  }

  void swapStops() {
    final oldOrigin = origin;
    origin = destination;
    destination = oldOrigin;
    notifyListeners();
  }

  void findRoutes() {
    final from = origin;
    final to = destination;
    if (from == null || to == null || from.id == to.id) {
      results = [];
      resultNote = null;
      notifyListeners();
      return;
    }

    final directResults = _findDirectRoutes(from, to);
    final transferResults = _findTransferRoutes(from, to);
    results = [...directResults, ...transferResults];
    resultNote =
        routes.any(
          (route) => route.dataConfidence == DataConfidence.terminalOnly,
        )
        ? 'Limited results - some routes have incomplete stop data'
        : null;
    notifyListeners();
  }

  List<TripPlanResult> _findDirectRoutes(BusStop from, BusStop to) {
    return routes
        .where((route) {
          return _routeContainsStop(route, from.id) &&
              _routeContainsStop(route, to.id);
        })
        .map((route) {
          return TripPlanResult(
            routes: [route],
            totalFare: route.farePrice,
            estimatedStops: _stopDistance(route, from.id, to.id),
          );
        })
        .toList();
  }

  List<TripPlanResult> _findTransferRoutes(BusStop from, BusStop to) {
    final results = <TripPlanResult>[];
    final originRoutes = routes.where(
      (route) =>
          route.dataConfidence != DataConfidence.terminalOnly &&
          _routeContainsStop(route, from.id),
    );
    final destinationRoutes = routes.where(
      (route) =>
          route.dataConfidence != DataConfidence.terminalOnly &&
          _routeContainsStop(route, to.id),
    );

    for (final firstRoute in originRoutes) {
      for (final secondRoute in destinationRoutes) {
        if (firstRoute.id == secondRoute.id) {
          continue;
        }
        final transferStop = _sharedStop(firstRoute, secondRoute);
        if (transferStop == null) {
          continue;
        }
        results.add(
          TripPlanResult(
            routes: [firstRoute, secondRoute],
            totalFare: firstRoute.farePrice + secondRoute.farePrice,
            estimatedStops:
                _stopDistance(firstRoute, from.id, transferStop.id) +
                _stopDistance(secondRoute, transferStop.id, to.id),
            transferStop: transferStop,
          ),
        );
      }
    }

    return results.take(8).toList();
  }

  bool _routeContainsStop(BusRoute route, String stopId) {
    return route.stops.any((stop) => stop.id == stopId);
  }

  int _stopDistance(BusRoute route, String fromId, String toId) {
    final fromIndex = route.stops.indexWhere((stop) => stop.id == fromId);
    final toIndex = route.stops.indexWhere((stop) => stop.id == toId);
    if (fromIndex == -1 || toIndex == -1) {
      return 0;
    }
    return (toIndex - fromIndex).abs();
  }

  BusStop? _sharedStop(BusRoute firstRoute, BusRoute secondRoute) {
    for (final stop in firstRoute.stops) {
      if (secondRoute.stops.any((candidate) => candidate.id == stop.id)) {
        return stop;
      }
    }
    return null;
  }
}
