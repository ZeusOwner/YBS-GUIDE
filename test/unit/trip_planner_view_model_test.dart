import 'package:flutter_test/flutter_test.dart';
import 'package:ybs_guide/data/repositories/ybs_repository.dart';
import 'package:ybs_guide/presentation/viewmodels/trip_planner_view_model.dart';

import '../helpers/test_database_helper.dart';

void main() {
  test('Trip planner finds direct route between stops on same route', () async {
    final repository = await TestDatabaseHelper.createSeededRepository();
    final viewModel = TripPlannerViewModel(YbsRepository(repository));
    await viewModel.load();

    final route = viewModel.routes.firstWhere(
      (route) => route.routeNumber == 'YBS-36',
    );
    final origin = route.stops.first;
    final destination = route.stops.last;

    viewModel.setOrigin(origin);
    viewModel.setDestination(destination);
    viewModel.findRoutes();

    expect(viewModel.results, isNotEmpty);
    expect(viewModel.results.first.isDirect, isTrue);
    expect(viewModel.results.first.routes.first.routeNumber, 'YBS-36');
  });
}
