import 'package:sqflite/sqflite.dart';

import '../models/bus_route.dart';
import '../models/bus_stop.dart';
import '../models/schedule.dart';
import '../repositories/route_repository.dart';

class LocalYbsDatasource implements RouteRepository {
  Database? _database;

  Future<Database?> get database async => _database;

  Future<List<BusRoute>> getRoutes() async {
    return _sampleRoutes;
  }

  @override
  Future<List<BusRoute>> getAllRoutes() => getRoutes();

  @override
  Future<BusRoute?> getRouteById(String id) async {
    for (final route in _sampleRoutes) {
      if (route.id == id) {
        return route;
      }
    }
    return null;
  }

  Future<List<BusStop>> getStops() async {
    return _sampleRoutes.expand((route) => route.stops).toList();
  }

  @override
  Future<List<BusRoute>> searchRoutes(String query) async {
    final lowerQuery = query.toLowerCase();
    return _sampleRoutes.where((route) {
      return route.routeNumber.toLowerCase().contains(lowerQuery) ||
          route.name.toLowerCase().contains(lowerQuery) ||
          route.startStop.toLowerCase().contains(lowerQuery) ||
          route.endStop.toLowerCase().contains(lowerQuery) ||
          route.stops.any(
            (stop) => stop.name.toLowerCase().contains(lowerQuery),
          );
    }).toList();
  }

  @override
  Future<List<BusStop>> getStopsByRoute(String routeId) async {
    final route = await getRouteById(routeId);
    return route?.stops ?? [];
  }

  Future<Schedule?> getSchedule(String routeId) async {
    final route = await getRouteById(routeId);
    return route?.schedule.firstOrNull;
  }
}

const _sampleRoutes = [
  BusRoute(
    id: 'ybs-36',
    routeNumber: 'YBS-36',
    nameEn: 'Hledan - Sule',
    nameMm: 'လည်းတန်း - ဆူးလေ',
    startStopEn: 'Hledan',
    startStopMm: 'လည်းတန်း',
    endStopEn: 'Sule',
    endStopMm: 'ဆူးလေ',
    farePrice: 400,
    isAirCon: false,
    color: '#1B5E20',
    routePath: [
      RouteCoordinate(latitude: 16.8296, longitude: 96.1307),
      RouteCoordinate(latitude: 16.8120, longitude: 96.1365),
      RouteCoordinate(latitude: 16.7920, longitude: 96.1460),
      RouteCoordinate(latitude: 16.7742, longitude: 96.1588),
    ],
    stops: [
      BusStop(
        id: 'hledan',
        nameEn: 'Hledan',
        nameMm: 'လည်းတန်း',
        latitude: 16.8296,
        longitude: 96.1307,
        routes: ['ybs-36'],
        landmarkEn: 'Hledan Center',
        landmarkMm: 'လည်းတန်းစင်တာ',
      ),
      BusStop(
        id: 'sule',
        nameEn: 'Sule',
        nameMm: 'ဆူးလေ',
        latitude: 16.7742,
        longitude: 96.1588,
        routes: ['ybs-36'],
        landmarkEn: 'Sule Pagoda',
        landmarkMm: 'ဆူးလေဘုရား',
      ),
    ],
    schedule: [
      Schedule(
        routeId: 'ybs-36',
        direction: RouteDirection.forward,
        departureTimes: ['05:30', '05:40', '05:50', '06:00'],
        operatingDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        firstBus: '05:30',
        lastBus: '21:30',
      ),
      Schedule(
        routeId: 'ybs-36',
        direction: RouteDirection.reverse,
        departureTimes: ['05:45', '06:00', '06:15', '06:30'],
        operatingDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        firstBus: '05:45',
        lastBus: '21:45',
      ),
    ],
  ),
  BusRoute(
    id: 'ybs-65',
    routeNumber: 'YBS-65',
    nameEn: 'North Dagon - Downtown',
    nameMm: 'မြောက်ဒဂုံ - မြို့ထဲ',
    startStopEn: 'North Dagon',
    startStopMm: 'မြောက်ဒဂုံ',
    endStopEn: 'Downtown',
    endStopMm: 'မြို့ထဲ',
    farePrice: 500,
    isAirCon: true,
    color: '#0D47A1',
    routePath: [
      RouteCoordinate(latitude: 16.8844, longitude: 96.1911),
      RouteCoordinate(latitude: 16.8500, longitude: 96.1820),
      RouteCoordinate(latitude: 16.8100, longitude: 96.1690),
      RouteCoordinate(latitude: 16.7791, longitude: 96.1528),
    ],
    stops: [
      BusStop(
        id: 'north-dagon',
        nameEn: 'North Dagon',
        nameMm: 'မြောက်ဒဂုံ',
        latitude: 16.8844,
        longitude: 96.1911,
        routes: ['ybs-65'],
        landmarkEn: 'North Dagon Market',
        landmarkMm: 'မြောက်ဒဂုံဈေး',
      ),
      BusStop(
        id: 'downtown',
        nameEn: 'Downtown',
        nameMm: 'မြို့ထဲ',
        latitude: 16.7791,
        longitude: 96.1528,
        routes: ['ybs-65'],
        landmarkEn: 'Yangon City Hall',
        landmarkMm: 'ရန်ကုန်မြို့တော်ခန်းမ',
      ),
    ],
    schedule: [
      Schedule(
        routeId: 'ybs-65',
        direction: RouteDirection.forward,
        departureTimes: ['05:45', '06:00', '06:15', '06:30'],
        operatingDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        firstBus: '05:45',
        lastBus: '21:00',
      ),
      Schedule(
        routeId: 'ybs-65',
        direction: RouteDirection.reverse,
        departureTimes: ['06:00', '06:15', '06:30', '06:45'],
        operatingDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        firstBus: '06:00',
        lastBus: '21:15',
      ),
    ],
  ),
];
