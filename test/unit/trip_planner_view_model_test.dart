import 'package:flutter_test/flutter_test.dart';
import 'package:ybs_guide/data/datasources/local_ybs_datasource.dart';
import 'package:ybs_guide/data/repositories/ybs_repository.dart';
import 'package:ybs_guide/presentation/viewmodels/trip_planner_view_model.dart';

void main() {
  test('Trip planner finds direct route between stops on same route', () async {
    final viewModel = TripPlannerViewModel(YbsRepository(LocalYbsDatasource()));
    await viewModel.load();

    final origin = viewModel.stops.firstWhere((stop) => stop.id == 'hledan');
    final destination = viewModel.stops.firstWhere((stop) => stop.id == 'sule');

    viewModel.setOrigin(origin);
    viewModel.setDestination(destination);
    viewModel.findRoutes();

    expect(viewModel.results, isNotEmpty);
    expect(viewModel.results.first.isDirect, isTrue);
    expect(viewModel.results.first.routes.first.routeNumber, 'YBS-36');
  });
}
