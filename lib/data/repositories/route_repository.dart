import '../datasources/local_database.dart';
import '../models/bus_route.dart';
import '../models/bus_stop.dart';

abstract class RouteRepository {
  Future<List<BusRoute>> getAllRoutes();
  Future<BusRoute?> getRouteById(String id);
  Future<List<BusRoute>> searchRoutes(String query);
  Future<List<BusStop>> getStopsByRoute(String routeId);
}

class RouteRepositoryImpl implements RouteRepository {
  const RouteRepositoryImpl(this._database);

  final LocalDatabase _database;

  @override
  Future<List<BusRoute>> getAllRoutes() async {
    try {
      return await _database.getAllRoutes();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<BusRoute?> getRouteById(String id) async {
    try {
      return await _database.getRouteById(id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<BusRoute>> searchRoutes(String query) async {
    try {
      return await _database.searchRoutes(query);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<BusStop>> getStopsByRoute(String routeId) async {
    try {
      return await _database.getStopsByRoute(routeId);
    } catch (_) {
      return [];
    }
  }
}
