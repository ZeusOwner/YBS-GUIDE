import '../models/bus_route.dart';
import '../models/bus_stop.dart';
import '../models/schedule.dart';
import 'route_repository.dart';

class YbsRepository {
  const YbsRepository(this._routes);

  final RouteRepository _routes;

  Future<List<BusRoute>> getRoutes() => _routes.getAllRoutes();

  Future<BusRoute?> getRouteById(String id) => _routes.getRouteById(id);

  Future<List<BusStop>> getStops() async {
    final routes = await _routes.getAllRoutes();
    return routes
        .expand((route) => route.stops)
        .fold<Map<String, BusStop>>({}, (unique, stop) {
          unique[stop.id] = stop;
          return unique;
        })
        .values
        .toList();
  }

  Future<Schedule?> getSchedule(String routeId) async {
    final route = await _routes.getRouteById(routeId);
    return route?.schedule.firstOrNull;
  }
}
