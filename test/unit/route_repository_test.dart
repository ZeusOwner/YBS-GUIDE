import 'package:flutter_test/flutter_test.dart';
import 'package:ybs_guide/data/datasources/local_ybs_datasource.dart';
import 'package:ybs_guide/data/repositories/ybs_repository.dart';

void main() {
  test('YbsRepository returns routes and route by id', () async {
    final repository = YbsRepository(LocalYbsDatasource());

    final routes = await repository.getRoutes();
    final route = await repository.getRouteById('ybs-36');

    expect(routes, isNotEmpty);
    expect(route?.routeNumber, 'YBS-36');
  });
}
