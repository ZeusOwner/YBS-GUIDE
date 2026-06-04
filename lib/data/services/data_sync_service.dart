import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../datasources/local_database.dart';
import '../models/bus_route.dart';
import '../models/data_source_metadata.dart';
import '../utils/route_validator.dart';

class SyncResult {
  const SyncResult({
    required this.success,
    this.updated = false,
    this.version,
    this.routeCount,
    this.error,
  });

  final bool success;
  final bool updated;
  final String? version;
  final int? routeCount;
  final String? error;
}

class DataSyncService {
  DataSyncService({LocalDatabase? database, http.Client? client})
    : _database = database ?? LocalDatabase.instance,
      _client = client ?? http.Client();

  static const String manifestUrl =
      'https://raw.githubusercontent.com/ZeusOwner/YBS-GUIDE/main/data/manifest.json';
  static const String _versionKey = 'data_version';
  static const String _lastUpdatedKey = 'data_last_updated';

  final LocalDatabase _database;
  final http.Client _client;

  Future<SyncResult> checkAndSync() async {
    try {
      final manifestResponse = await _client
          .get(Uri.parse(manifestUrl))
          .timeout(const Duration(seconds: 10));
      if (manifestResponse.statusCode < 200 ||
          manifestResponse.statusCode >= 300) {
        return SyncResult(
          success: false,
          error: 'Manifest HTTP ${manifestResponse.statusCode}',
        );
      }

      final manifest =
          jsonDecode(utf8.decode(manifestResponse.bodyBytes))
              as Map<String, dynamic>;
      final remoteVersion = manifest['version'] as String? ?? '';
      final downloadUrl = manifest['downloadUrl'] as String? ?? '';
      final checksum = manifest['checksum'] as String? ?? '';
      final lastUpdated = manifest['lastUpdated'] as String? ?? '';
      final routeCount = manifest['routeCount'] as int?;
      if (remoteVersion.isEmpty || downloadUrl.isEmpty || checksum.isEmpty) {
        return const SyncResult(
          success: false,
          error: 'Manifest missing version/downloadUrl/checksum.',
        );
      }

      final localVersion = await getLocalDataVersion();
      if (!_isRemoteNewer(remoteVersion, localVersion)) {
        return SyncResult(
          success: true,
          updated: false,
          version: localVersion,
          routeCount: routeCount,
        );
      }

      final routesResponse = await _client
          .get(Uri.parse(downloadUrl))
          .timeout(const Duration(seconds: 30));
      if (routesResponse.statusCode < 200 || routesResponse.statusCode >= 300) {
        return SyncResult(
          success: false,
          error: 'Routes HTTP ${routesResponse.statusCode}',
        );
      }

      final bodyBytes = routesResponse.bodyBytes;
      final actualChecksum = sha256.convert(bodyBytes).toString();
      final expectedChecksum = checksum
          .replaceFirst(RegExp(r'^sha256-', caseSensitive: false), '')
          .toLowerCase();
      if (actualChecksum.toLowerCase() != expectedChecksum) {
        return const SyncResult(success: false, error: 'Checksum mismatch.');
      }

      final parsed = jsonDecode(utf8.decode(bodyBytes));
      final routeJsonList = _extractRoutes(parsed);
      if (routeCount != null && routeJsonList.length != routeCount) {
        return SyncResult(
          success: false,
          error:
              'Route count mismatch. Expected $routeCount, got ${routeJsonList.length}.',
        );
      }

      final routes = <BusRoute>[];
      final validationErrors = <String>[];
      for (final routeJson in routeJsonList) {
        final errors = RouteValidator.validate(routeJson);
        if (errors.isNotEmpty) {
          validationErrors.add(
            '${routeJson['routeNumber'] ?? routeJson['id'] ?? 'unknown'}: ${errors.join('; ')}',
          );
          continue;
        }
        routes.add(BusRoute.fromJson(routeJson));
      }
      if (validationErrors.isNotEmpty) {
        return SyncResult(
          success: false,
          error: 'Validation failed: ${validationErrors.join(' | ')}',
        );
      }

      await _database.upsertRoutesWithDataSourceTransaction(
        routes,
        DataSourceMetadata(
          id: 'github_raw',
          name: 'GitHub YBS route data',
          sourceUrl: downloadUrl,
          version: remoteVersion,
          lastUpdated: lastUpdated.isEmpty
              ? DateTime.now()
              : DateTime.parse(lastUpdated),
          confidence: 0.8,
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_versionKey, remoteVersion);
      await prefs.setString(
        _lastUpdatedKey,
        lastUpdated.isEmpty ? DateTime.now().toIso8601String() : lastUpdated,
      );

      return SyncResult(
        success: true,
        updated: true,
        version: remoteVersion,
        routeCount: routes.length,
      );
    } on SocketException catch (error, stackTrace) {
      developer.log(
        'Route sync skipped: offline',
        error: error,
        stackTrace: stackTrace,
      );
      return SyncResult(success: false, error: error.toString());
    } on TimeoutException catch (error, stackTrace) {
      developer.log(
        'Route sync timed out',
        error: error,
        stackTrace: stackTrace,
      );
      return SyncResult(success: false, error: error.toString());
    } catch (error, stackTrace) {
      developer.log('Route sync failed', error: error, stackTrace: stackTrace);
      return SyncResult(success: false, error: error.toString());
    }
  }

  Future<String> getLocalDataVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_versionKey) ?? '0.0.0';
  }

  Future<String?> getLastUpdated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastUpdatedKey);
  }

  List<Map<String, dynamic>> _extractRoutes(Object? parsed) {
    final routeList = switch (parsed) {
      List<dynamic> list => list,
      Map<String, dynamic> map when map['routes'] is List<dynamic> =>
        map['routes'] as List<dynamic>,
      _ => throw const FormatException(
        'routes.json must be a list or contain routes list.',
      ),
    };

    return routeList
        .map((route) => Map<String, dynamic>.from(route as Map))
        .toList();
  }

  bool _isRemoteNewer(String remote, String local) {
    final remoteParts = _versionParts(remote);
    final localParts = _versionParts(local);
    for (var index = 0; index < remoteParts.length; index++) {
      if (remoteParts[index] > localParts[index]) {
        return true;
      }
      if (remoteParts[index] < localParts[index]) {
        return false;
      }
    }
    return false;
  }

  List<int> _versionParts(String value) {
    final clean = value.replaceFirst(RegExp(r'^v'), '');
    final parts = clean.split('.');
    return List<int>.generate(
      3,
      (index) => index < parts.length ? int.tryParse(parts[index]) ?? 0 : 0,
    );
  }
}
