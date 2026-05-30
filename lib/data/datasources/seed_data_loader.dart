import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bus_route.dart';
import '../models/data_source_metadata.dart';
import 'local_database.dart';

class SeedDataLoader {
  const SeedDataLoader(this._database);

  static const String _seedLoadedKey = 'ybs_seed_data_loaded_v1';
  static const String _seedAssetPath = 'assets/data/ybs_routes.json';

  final LocalDatabase _database;

  Future<void> loadIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoaded = prefs.getBool(_seedLoadedKey) ?? false;
    if (isLoaded) {
      return;
    }

    final jsonString = await rootBundle.loadString(_seedAssetPath);
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final metadataJson = data['metadata'] as Map<String, dynamic>?;
    final metadata = metadataJson == null
        ? DataSourceMetadata(
            id: 'official_seed',
            name: 'YRTA/JICA-derived seed data',
            sourceUrl:
                'https://jicayangonbusta.wordpress.com/up-to-date-information-for-gtfs/',
            version: 'seed-2026-05-30',
            lastUpdated: DateTime(2026, 5, 30),
            confidence: 0.6,
          )
        : DataSourceMetadata.fromJson(metadataJson);
    final routes = (data['routes'] as List<dynamic>)
        .map(
          (route) => BusRoute.fromJson(route as Map<String, dynamic>).copyWith(
            source: metadata.id,
            sourceUrl: metadata.sourceUrl,
            lastUpdated: metadata.lastUpdated.toIso8601String(),
            confidence: metadata.confidence,
          ),
        )
        .toList();

    await _database.upsertDataSource(metadata);
    await _database.insertRoutes(routes);
    await prefs.setBool(_seedLoadedKey, true);
  }

  Future<void> resetSeedFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seedLoadedKey);
  }
}
