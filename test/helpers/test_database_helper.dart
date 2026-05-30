import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ybs_guide/data/datasources/local_database.dart';
import 'package:ybs_guide/data/models/bus_route.dart';
import 'package:ybs_guide/data/repositories/route_repository.dart';

class TestDatabaseHelper {
  static const List<String> _routeNumbers = [
    'YBS-36',
    'YBS-1',
    'YBS-43',
    'YBS-65',
    'YBS-9',
  ];

  static Future<SqliteRouteRepository> createSeededRepository() async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfiNoIsolate.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await LocalDatabase.createSchema(db);

    final repository = SqliteRouteRepository(db);
    for (final route in _buildTestRoutes()) {
      await repository.upsertRoute(route);
    }
    addTearDown(repository.close);
    return repository;
  }

  static List<BusRoute> _buildTestRoutes() {
    final file = File('assets/data/ybs_routes_production.json');
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final routes = (json['routes'] as List<dynamic>)
        .map((route) => BusRoute.fromJson(route as Map<String, dynamic>))
        .where((route) => _routeNumbers.contains(route.routeNumber))
        .toList();
    final routesByStop = <String, Set<String>>{};
    for (final route in routes) {
      for (final stop in route.stops) {
        routesByStop.putIfAbsent(stop.id, () => <String>{}).add(route.id);
      }
    }
    final hydratedRoutes = routes
        .map(
          (route) => route.copyWith(
            stops: route.stops
                .map(
                  (stop) => stop.copyWith(
                    routes: routesByStop[stop.id]?.toList() ?? [route.id],
                  ),
                )
                .toList(),
          ),
        )
        .toList();

    hydratedRoutes.sort(
      (left, right) => _routeNumbers
          .indexOf(left.routeNumber)
          .compareTo(_routeNumbers.indexOf(right.routeNumber)),
    );
    return hydratedRoutes;
  }
}
