import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ybs_guide/data/repositories/ybs_repository.dart';
import 'package:ybs_guide/presentation/viewmodels/search_view_model.dart';

import '../helpers/test_database_helper.dart';

void main() {
  test('SearchViewModel filters by route and stop name', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = await TestDatabaseHelper.createSeededRepository();
    final viewModel = SearchViewModel(YbsRepository(repository));

    viewModel.search('Hledan');
    await Future<void>.delayed(const Duration(milliseconds: 350));

    expect(viewModel.filteredRoutes, isNotEmpty);
    expect(viewModel.filteredRoutes.first.routeNumber, 'YBS-36');
  });

  test('SearchViewModel applies air-con filter', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = await TestDatabaseHelper.createSeededRepository();
    final viewModel = SearchViewModel(YbsRepository(repository));

    await viewModel.applyFilter(RouteSearchFilter.airConOnly);
    viewModel.search('Downtown');
    await Future<void>.delayed(const Duration(milliseconds: 350));

    expect(viewModel.filteredRoutes.every((route) => route.isAirCon), isTrue);
  });
}
