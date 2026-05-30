import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../datasources/local_database.dart';
import '../models/bus_route.dart';
import '../models/bus_stop.dart';
import '../models/schedule.dart';

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

class SqliteRouteRepository implements RouteRepository {
  const SqliteRouteRepository(this._database);

  final Database _database;

  @override
  Future<List<BusRoute>> getAllRoutes() async {
    final rows = await _database.query(
      'bus_routes',
      orderBy: 'route_number ASC',
    );
    return Future.wait(rows.map(_routeFromRow));
  }

  @override
  Future<BusRoute?> getRouteById(String id) async {
    final rows = await _database.query(
      'bus_routes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _routeFromRow(rows.first);
  }

  @override
  Future<List<BusRoute>> searchRoutes(String query) async {
    final value = '%${query.toLowerCase()}%';
    final rows = await _database.query(
      'bus_routes',
      where:
          'LOWER(route_number) LIKE ? OR LOWER(name) LIKE ? OR LOWER(name_en) LIKE ? OR LOWER(name_mm) LIKE ? OR LOWER(start_stop) LIKE ? OR LOWER(start_stop_en) LIKE ? OR LOWER(start_stop_mm) LIKE ? OR LOWER(end_stop) LIKE ? OR LOWER(end_stop_en) LIKE ? OR LOWER(end_stop_mm) LIKE ?',
      whereArgs: [
        value,
        value,
        value,
        value,
        value,
        value,
        value,
        value,
        value,
        value,
      ],
      orderBy: 'route_number ASC',
    );
    return Future.wait(rows.map(_routeFromRow));
  }

  @override
  Future<List<BusStop>> getStopsByRoute(String routeId) async {
    final rows = await _database.query(
      'bus_stops',
      where: 'routes LIKE ?',
      whereArgs: ['%"$routeId"%'],
      orderBy: 'name ASC',
    );
    return rows.map(_stopFromRow).toList();
  }

  Future<List<BusStop>> getAllStops() async {
    final rows = await _database.query('bus_stops', orderBy: 'name ASC');
    return rows.map(_stopFromRow).toList();
  }

  Future<List<Schedule>> getSchedulesByRoute(String routeId) async {
    final rows = await _database.query(
      'schedules',
      where: 'route_id = ?',
      whereArgs: [routeId],
      orderBy: 'direction ASC',
    );
    return rows.map(_scheduleFromRow).toList();
  }

  Future<BusRoute> _routeFromRow(Map<String, Object?> row) async {
    final id = row['id']! as String;
    return BusRoute(
      id: id,
      routeNumber: row['route_number']! as String,
      nameEn: _text(row, 'name_en').isEmpty
          ? _splitLegacy(row['name']! as String).en
          : _text(row, 'name_en'),
      nameMm: _text(row, 'name_mm').isEmpty
          ? _splitLegacy(row['name']! as String).mm
          : _text(row, 'name_mm'),
      startStopEn: _text(row, 'start_stop_en').isEmpty
          ? _splitLegacy(row['start_stop']! as String).en
          : _text(row, 'start_stop_en'),
      startStopMm: _text(row, 'start_stop_mm').isEmpty
          ? _splitLegacy(row['start_stop']! as String).mm
          : _text(row, 'start_stop_mm'),
      endStopEn: _text(row, 'end_stop_en').isEmpty
          ? _splitLegacy(row['end_stop']! as String).en
          : _text(row, 'end_stop_en'),
      endStopMm: _text(row, 'end_stop_mm').isEmpty
          ? _splitLegacy(row['end_stop']! as String).mm
          : _text(row, 'end_stop_mm'),
      stops: await getStopsByRoute(id),
      schedule: await getSchedulesByRoute(id),
      farePrice: (row['fare_price']! as num).toDouble(),
      isAirCon: (row['is_air_con']! as int) == 1,
      color: row['color']! as String,
      source: row['source'] as String? ?? 'official_seed',
      sourceUrl: row['source_url'] as String? ?? '',
      lastUpdated: row['last_updated'] as String? ?? '2026-05-30',
      confidence: ((row['confidence'] as num?) ?? 0.6).toDouble(),
      routePath: (jsonDecode(row['route_path']! as String) as List<dynamic>)
          .map(
            (point) => RouteCoordinate.fromJson(point as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  BusStop _stopFromRow(Map<String, Object?> row) {
    return BusStop(
      id: row['id']! as String,
      nameEn: _text(row, 'name_en').isEmpty
          ? _splitLegacy(row['name']! as String).en
          : _text(row, 'name_en'),
      nameMm: _text(row, 'name_mm').isEmpty
          ? _splitLegacy(row['name']! as String).mm
          : _text(row, 'name_mm'),
      latitude: (row['latitude']! as num).toDouble(),
      longitude: (row['longitude']! as num).toDouble(),
      routes: (jsonDecode(row['routes']! as String) as List<dynamic>)
          .map((routeId) => routeId as String)
          .toList(),
      landmarkEn: _text(row, 'landmark_en').isEmpty
          ? _splitLegacy(row['landmark']! as String).en
          : _text(row, 'landmark_en'),
      landmarkMm: _text(row, 'landmark_mm').isEmpty
          ? _splitLegacy(row['landmark']! as String).mm
          : _text(row, 'landmark_mm'),
    );
  }

  Schedule _scheduleFromRow(Map<String, Object?> row) {
    return Schedule(
      routeId: row['route_id']! as String,
      direction: RouteDirection.fromJson(row['direction']! as String),
      departureTimes:
          (jsonDecode(row['departure_times']! as String) as List<dynamic>)
              .map((time) => time as String)
              .toList(),
      operatingDays:
          (jsonDecode(row['operating_days']! as String) as List<dynamic>)
              .map((day) => day as String)
              .toList(),
      firstBus: row['first_bus']! as String,
      lastBus: row['last_bus']! as String,
    );
  }
}

String _text(Map<String, Object?> row, String key) {
  return row[key] as String? ?? '';
}

({String en, String mm}) _splitLegacy(String value) {
  final parts = value.split('/');
  if (parts.length < 2) {
    return (en: value.trim(), mm: '');
  }
  return (en: parts.first.trim(), mm: parts.sublist(1).join('/').trim());
}
