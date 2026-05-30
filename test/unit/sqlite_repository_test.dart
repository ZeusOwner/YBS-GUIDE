import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database_helper.dart';

void main() {
  test('getAllRoutes returns seeded data', () async {
    final repository = await TestDatabaseHelper.createSeededRepository();

    final routes = await repository.getAllRoutes();

    expect(routes, hasLength(5));
    expect(routes.map((route) => route.routeNumber), contains('YBS-36'));
  });

  test('getRouteById returns correct route', () async {
    final repository = await TestDatabaseHelper.createSeededRepository();

    final route = await repository.getRouteById('ybs-36');

    expect(route?.routeNumber, 'YBS-36');
  });

  test('searchRoutes finds Insein routes by English text', () async {
    final repository = await TestDatabaseHelper.createSeededRepository();

    final routes = await repository.searchRoutes('insein');

    expect(routes.map((route) => route.routeNumber), contains('YBS-36'));
    expect(routes, isNotEmpty);
  });

  test('searchRoutes finds Insein routes by Burmese text', () async {
    final repository = await TestDatabaseHelper.createSeededRepository();

    final routes = await repository.searchRoutes('အင်းစိန်');

    expect(routes.map((route) => route.routeNumber), contains('YBS-36'));
    expect(routes, isNotEmpty);
  });

  test('searchRoutes finds YBS-36 by route number', () async {
    final repository = await TestDatabaseHelper.createSeededRepository();

    final routes = await repository.searchRoutes('36');

    expect(routes.map((route) => route.routeNumber), contains('YBS-36'));
  });

  test('getStopsByRoute returns stop list', () async {
    final repository = await TestDatabaseHelper.createSeededRepository();

    final stops = await repository.getStopsByRoute('ybs-36');

    expect(stops, isNotEmpty);
    expect(stops.every((stop) => stop.routes.contains('ybs-36')), isTrue);
  });

  test('seeded routes populate English and Burmese names', () async {
    final repository = await TestDatabaseHelper.createSeededRepository();

    final route = await repository.getRouteById('ybs-36');
    final stops = await repository.getStopsByRoute('ybs-36');

    expect(route?.nameEn, isNotEmpty);
    expect(route?.nameMm, isNotEmpty);
    expect(stops.first.nameEn, isNotEmpty);
    expect(stops.first.nameMm, isNotEmpty);
  });
}
