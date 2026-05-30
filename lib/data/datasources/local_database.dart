import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart';

import '../models/bus_route.dart';
import '../models/bus_stop.dart';
import '../models/data_source_metadata.dart';
import '../models/favorite_route.dart';
import '../models/schedule.dart';

class LocalDatabase {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();
  static const int _databaseVersion = 5;
  static const String _databaseName = 'ybs_guide.db';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final databasesPath = await getDatabasesPath();
    final path = '$databasesPath${Platform.pathSeparator}$_databaseName';

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE bus_routes (
        id TEXT PRIMARY KEY,
        route_number TEXT NOT NULL,
        name TEXT NOT NULL,
        name_en TEXT NOT NULL DEFAULT '',
        name_mm TEXT NOT NULL DEFAULT '',
        start_stop TEXT NOT NULL,
        start_stop_en TEXT NOT NULL DEFAULT '',
        start_stop_mm TEXT NOT NULL DEFAULT '',
        end_stop TEXT NOT NULL,
        end_stop_en TEXT NOT NULL DEFAULT '',
        end_stop_mm TEXT NOT NULL DEFAULT '',
        fare_price REAL NOT NULL,
        is_air_con INTEGER NOT NULL,
        color TEXT NOT NULL,
        route_path TEXT NOT NULL,
        source TEXT NOT NULL DEFAULT 'official_seed',
        source_url TEXT NOT NULL DEFAULT '',
        last_updated TEXT NOT NULL DEFAULT '2026-05-30',
        confidence REAL NOT NULL DEFAULT 0.6
      )
    ''');

    await db.execute('''
      CREATE TABLE bus_stops (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        name_en TEXT NOT NULL DEFAULT '',
        name_mm TEXT NOT NULL DEFAULT '',
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        routes TEXT NOT NULL,
        landmark TEXT NOT NULL,
        landmark_en TEXT,
        landmark_mm TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        route_id TEXT NOT NULL,
        direction TEXT NOT NULL,
        departure_times TEXT NOT NULL,
        operating_days TEXT NOT NULL,
        first_bus TEXT NOT NULL,
        last_bus TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites (
        route_id TEXT PRIMARY KEY,
        saved_at TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        nickname TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE data_sources (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        source_url TEXT NOT NULL,
        version TEXT NOT NULL,
        last_updated TEXT NOT NULL,
        confidence REAL NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 1) {
      await _onCreate(db, newVersion);
    }
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE bus_routes ADD COLUMN route_path TEXT NOT NULL DEFAULT '[]'",
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE favorites ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 4) {
      await db.execute(
        "ALTER TABLE bus_routes ADD COLUMN source TEXT NOT NULL DEFAULT 'official_seed'",
      );
      await db.execute(
        "ALTER TABLE bus_routes ADD COLUMN source_url TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE bus_routes ADD COLUMN last_updated TEXT NOT NULL DEFAULT '2026-05-30'",
      );
      await db.execute(
        'ALTER TABLE bus_routes ADD COLUMN confidence REAL NOT NULL DEFAULT 0.6',
      );
      await db.execute('''
        CREATE TABLE IF NOT EXISTS data_sources (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          source_url TEXT NOT NULL,
          version TEXT NOT NULL,
          last_updated TEXT NOT NULL,
          confidence REAL NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute(
        "ALTER TABLE bus_routes ADD COLUMN name_en TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE bus_routes ADD COLUMN name_mm TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE bus_routes ADD COLUMN start_stop_en TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE bus_routes ADD COLUMN start_stop_mm TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE bus_routes ADD COLUMN end_stop_en TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE bus_routes ADD COLUMN end_stop_mm TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE bus_stops ADD COLUMN name_en TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE bus_stops ADD COLUMN name_mm TEXT NOT NULL DEFAULT ''",
      );
      await db.execute('ALTER TABLE bus_stops ADD COLUMN landmark_en TEXT');
      await db.execute('ALTER TABLE bus_stops ADD COLUMN landmark_mm TEXT');
    }
  }

  Future<void> insertRoute(BusRoute route) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'bus_routes',
        _routeToRow(route),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (final stop in route.stops) {
        await txn.insert(
          'bus_stops',
          _stopToRow(stop),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await txn.delete(
        'schedules',
        where: 'route_id = ?',
        whereArgs: [route.id],
      );
      for (final schedule in route.schedule) {
        await txn.insert('schedules', _scheduleToRow(schedule));
      }
    });
  }

  Future<void> insertRoutes(List<BusRoute> routes) async {
    for (final route in routes) {
      await insertRoute(route);
    }
  }

  Future<void> upsertRoutesTransaction(List<BusRoute> routes) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final route in routes) {
        await txn.insert(
          'bus_routes',
          _routeToRow(route),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        for (final stop in route.stops) {
          await txn.insert(
            'bus_stops',
            _stopToRow(stop),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        await txn.delete(
          'schedules',
          where: 'route_id = ?',
          whereArgs: [route.id],
        );
        for (final schedule in route.schedule) {
          await txn.insert('schedules', _scheduleToRow(schedule));
        }
      }
    });
  }

  Future<void> upsertRoutesWithDataSourceTransaction(
    List<BusRoute> routes,
    DataSourceMetadata metadata,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final route in routes) {
        await txn.insert(
          'bus_routes',
          _routeToRow(route),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        for (final stop in route.stops) {
          await txn.insert(
            'bus_stops',
            _stopToRow(stop),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        await txn.delete(
          'schedules',
          where: 'route_id = ?',
          whereArgs: [route.id],
        );
        for (final schedule in route.schedule) {
          await txn.insert('schedules', _scheduleToRow(schedule));
        }
      }

      await txn.insert(
        'data_sources',
        _metadataToRow(metadata),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<List<BusRoute>> getAllRoutes() async {
    final db = await database;
    final rows = await db.query('bus_routes', orderBy: 'route_number ASC');
    return Future.wait(rows.map(_routeFromRow));
  }

  Future<BusRoute?> getRouteById(String id) async {
    final db = await database;
    final rows = await db.query(
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

  Future<List<BusRoute>> searchRoutes(String query) async {
    final db = await database;
    final value = '%${query.toLowerCase()}%';
    final rows = await db.query(
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

  Future<void> updateRoute(BusRoute route) => insertRoute(route);

  Future<void> deleteRoute(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('bus_routes', where: 'id = ?', whereArgs: [id]);
      await txn.delete('schedules', where: 'route_id = ?', whereArgs: [id]);
    });
  }

  Future<void> insertStop(BusStop stop) async {
    final db = await database;
    await db.insert(
      'bus_stops',
      _stopToRow(stop),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<BusStop>> getStopsByRoute(String routeId) async {
    final db = await database;
    final rows = await db.query(
      'bus_stops',
      where: 'routes LIKE ?',
      whereArgs: ['%"$routeId"%'],
      orderBy: 'name ASC',
    );
    return rows.map(_stopFromRow).toList();
  }

  Future<void> updateStop(BusStop stop) => insertStop(stop);

  Future<void> deleteStop(String id) async {
    final db = await database;
    await db.delete('bus_stops', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertSchedule(Schedule schedule) async {
    final db = await database;
    await db.insert('schedules', _scheduleToRow(schedule));
  }

  Future<List<Schedule>> getSchedulesByRoute(String routeId) async {
    final db = await database;
    final rows = await db.query(
      'schedules',
      where: 'route_id = ?',
      whereArgs: [routeId],
      orderBy: 'direction ASC',
    );
    return rows.map(_scheduleFromRow).toList();
  }

  Future<void> deleteSchedulesForRoute(String routeId) async {
    final db = await database;
    await db.delete('schedules', where: 'route_id = ?', whereArgs: [routeId]);
  }

  Future<void> saveFavorite(FavoriteRoute favorite) async {
    final db = await database;
    await db.insert(
      'favorites',
      _favoriteToRow(favorite),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<FavoriteRoute>> getFavorites() async {
    final db = await database;
    final rows = await db.query('favorites', orderBy: 'sort_order ASC');
    return rows.map(_favoriteFromRow).toList();
  }

  Future<void> updateFavoriteOrder(List<FavoriteRoute> favorites) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var index = 0; index < favorites.length; index++) {
        await txn.update(
          'favorites',
          {'sort_order': index},
          where: 'route_id = ?',
          whereArgs: [favorites[index].routeId],
        );
      }
    });
  }

  Future<void> deleteFavorite(String routeId) async {
    final db = await database;
    await db.delete('favorites', where: 'route_id = ?', whereArgs: [routeId]);
  }

  Future<void> upsertDataSource(DataSourceMetadata metadata) async {
    final db = await database;
    await db.insert(
      'data_sources',
      _metadataToRow(metadata),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DataSourceMetadata>> getDataSources() async {
    final db = await database;
    final rows = await db.query('data_sources', orderBy: 'last_updated DESC');
    return rows.map(_metadataFromRow).toList();
  }

  Map<String, Object?> _routeToRow(BusRoute route) {
    return {
      'id': route.id,
      'route_number': route.routeNumber,
      'name': route.name,
      'name_en': route.nameEn,
      'name_mm': route.nameMm,
      'start_stop': route.startStop,
      'start_stop_en': route.startStopEn,
      'start_stop_mm': route.startStopMm,
      'end_stop': route.endStop,
      'end_stop_en': route.endStopEn,
      'end_stop_mm': route.endStopMm,
      'fare_price': route.farePrice,
      'is_air_con': route.isAirCon ? 1 : 0,
      'color': route.color,
      'route_path': jsonEncode(
        route.routePath.map((point) => point.toJson()).toList(),
      ),
      'source': route.source,
      'source_url': route.sourceUrl,
      'last_updated': route.lastUpdated,
      'confidence': route.confidence,
    };
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

  Map<String, Object?> _stopToRow(BusStop stop) {
    return {
      'id': stop.id,
      'name': stop.name,
      'name_en': stop.nameEn,
      'name_mm': stop.nameMm,
      'latitude': stop.latitude,
      'longitude': stop.longitude,
      'routes': jsonEncode(stop.routes),
      'landmark': stop.landmark,
      'landmark_en': stop.landmarkEn,
      'landmark_mm': stop.landmarkMm,
    };
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

  Map<String, Object?> _scheduleToRow(Schedule schedule) {
    return {
      'route_id': schedule.routeId,
      'direction': schedule.direction.name,
      'departure_times': jsonEncode(schedule.departureTimes),
      'operating_days': jsonEncode(schedule.operatingDays),
      'first_bus': schedule.firstBus,
      'last_bus': schedule.lastBus,
    };
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

  Map<String, Object?> _favoriteToRow(FavoriteRoute favorite) {
    return {
      'route_id': favorite.routeId,
      'saved_at': favorite.savedAt.toIso8601String(),
      'sort_order': favorite.sortOrder,
      'nickname': favorite.nickname,
    };
  }

  FavoriteRoute _favoriteFromRow(Map<String, Object?> row) {
    return FavoriteRoute(
      routeId: row['route_id']! as String,
      savedAt: DateTime.parse(row['saved_at']! as String),
      sortOrder: row['sort_order']! as int,
      nickname: row['nickname'] as String?,
    );
  }

  Map<String, Object?> _metadataToRow(DataSourceMetadata metadata) {
    return {
      'id': metadata.id,
      'name': metadata.name,
      'source_url': metadata.sourceUrl,
      'version': metadata.version,
      'last_updated': metadata.lastUpdated.toIso8601String(),
      'confidence': metadata.confidence,
    };
  }

  DataSourceMetadata _metadataFromRow(Map<String, Object?> row) {
    return DataSourceMetadata(
      id: row['id']! as String,
      name: row['name']! as String,
      sourceUrl: row['source_url']! as String,
      version: row['version']! as String,
      lastUpdated: DateTime.parse(row['last_updated']! as String),
      confidence: (row['confidence']! as num).toDouble(),
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
