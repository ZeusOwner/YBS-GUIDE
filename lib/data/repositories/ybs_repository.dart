import '../datasources/local_ybs_datasource.dart';
import '../models/bus_route.dart';
import '../models/bus_stop.dart';
import '../models/schedule.dart';

class YbsRepository {
  const YbsRepository(this._datasource);

  final LocalYbsDatasource _datasource;

  Future<List<BusRoute>> getRoutes() => _datasource.getRoutes();

  Future<BusRoute?> getRouteById(String id) => _datasource.getRouteById(id);

  Future<List<BusStop>> getStops() => _datasource.getStops();

  Future<Schedule?> getSchedule(String routeId) =>
      _datasource.getSchedule(routeId);
}
