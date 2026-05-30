import 'package:flutter_test/flutter_test.dart';
import 'package:ybs_guide/data/repositories/ybs_repository.dart';

import '../helpers/test_database_helper.dart';

void main() {
  test('YbsRepository returns routes and route by id', () async {
    final sqliteRepository = await TestDatabaseHelper.createSeededRepository();
    final repository = YbsRepository(sqliteRepository);

    final routes = await repository.getRoutes();
    final route = await repository.getRouteById('ybs-36');

    expect(routes, isNotEmpty);
    expect(route?.routeNumber, 'YBS-36');
  });
}
