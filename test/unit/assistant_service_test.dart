import 'package:flutter_test/flutter_test.dart';
import 'package:ybs_guide/data/models/bus_route.dart';
import 'package:ybs_guide/data/models/bus_stop.dart';
import 'package:ybs_guide/data/repositories/route_repository.dart';
import 'package:ybs_guide/data/repositories/ybs_repository.dart';
import 'package:ybs_guide/data/services/assistant_service.dart';

import '../helpers/test_database_helper.dart';

void main() {
  test(
    'from current location to Sule resolves route from nearest stop',
    () async {
      final repository = await TestDatabaseHelper.createSeededRepository();
      final service = AssistantService(YbsRepository(repository));
      final route36 = (await repository.getAllRoutes()).firstWhere(
        (route) => route.routeNumber == 'YBS-36',
      );
      final currentStop = route36.stops[1];

      final answer = await service.generateOfflineTripAnswer(
        'from here to Sule',
        currentStop: currentStop,
      );

      expect(answer.legs, isNotEmpty);
      expect(answer.text, contains('YBS-36'));
      expect(answer.origin?.id, currentStop.id);
    },
  );

  test('Burmese Sule query returns destination match', () async {
    final repository = await TestDatabaseHelper.createSeededRepository();
    final service = AssistantService(YbsRepository(repository));
    final route36 = (await repository.getAllRoutes()).firstWhere(
      (route) => route.routeNumber == 'YBS-36',
    );

    final answer = await service.generateOfflineTripAnswer(
      'ဆူးလေ သွားချင်တယ်',
      currentStop: route36.stops[1],
    );

    expect(answer.destination?.name, contains('ဆူးလေ'));
    expect(answer.text, isNotEmpty);
  });

  test('offline mode returns answer without AI worker', () async {
    final repository = await TestDatabaseHelper.createSeededRepository();
    final service = AssistantService(YbsRepository(repository));

    final answer = await service.generateOfflineTripAnswer('YBS 36 Route');

    expect(answer.text, contains('YBS-36'));
    expect(answer.legs, isEmpty);
  });

  test('terminal-only routes are not used as transfer routes', () async {
    final origin = _stop('origin', 'Origin');
    final transfer = _stop('transfer', 'Transfer');
    final destination = _stop('dest', 'Destination');
    final repository = YbsRepository(
      _FakeRouteRepository([
        _route('verified-a', 'YBS-1', [
          origin,
          transfer,
        ], DataConfidence.verified),
        _route('terminal-b', 'YBS-2', [
          transfer,
          destination,
        ], DataConfidence.terminalOnly),
      ]),
    );
    final service = AssistantService(repository);

    final answer = await service.generateOfflineTripAnswer(
      'to Destination',
      currentStop: origin,
    );

    expect(answer.legs, isEmpty);
    expect(answer.limitedData, isTrue);
  });
}

BusStop _stop(String id, String name) {
  return BusStop(
    id: id,
    nameEn: name,
    nameMm: name,
    latitude: 16.8,
    longitude: 96.1,
    routes: const [],
  );
}

BusRoute _route(
  String id,
  String number,
  List<BusStop> stops,
  DataConfidence confidence,
) {
  return BusRoute(
    id: id,
    routeNumber: number,
    nameEn: '$number route',
    nameMm: '$number route',
    startStopEn: stops.first.nameEn,
    startStopMm: stops.first.nameMm,
    endStopEn: stops.last.nameEn,
    endStopMm: stops.last.nameMm,
    stops: stops.map((stop) => stop.copyWith(routes: [id])).toList(),
    schedule: const [],
    farePrice: 300,
    isAirCon: false,
    color: '#1B5E20',
    routePath: const [],
    dataConfidence: confidence,
  );
}

class _FakeRouteRepository implements RouteRepository {
  const _FakeRouteRepository(this.routes);

  final List<BusRoute> routes;

  @override
  Future<List<BusRoute>> getAllRoutes() async => routes;

  @override
  Future<BusRoute?> getRouteById(String id) async {
    return routes.where((route) => route.id == id).firstOrNull;
  }

  @override
  Future<List<BusStop>> getAllStops() async {
    return routes.expand((route) => route.stops).toList();
  }

  @override
  Future<List<BusStop>> getStopsByRoute(String routeId) async {
    return routes.where((route) => route.id == routeId).firstOrNull?.stops ??
        const [];
  }

  @override
  Future<List<BusRoute>> searchRoutes(String query) async => routes;
}
