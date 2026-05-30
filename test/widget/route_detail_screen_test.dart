import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ybs_guide/data/repositories/ybs_repository.dart';
import 'package:ybs_guide/l10n/app_localizations.dart';
import 'package:ybs_guide/presentation/screens/route_detail/route_detail_screen.dart';
import 'package:ybs_guide/presentation/viewmodels/favorites_view_model.dart';
import 'package:ybs_guide/presentation/viewmodels/route_detail_view_model.dart';

import '../helpers/test_database_helper.dart';

void main() {
  testWidgets('Route detail switches tabs', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final sqliteRepository = await TestDatabaseHelper.createSeededRepository();
    final repository = YbsRepository(sqliteRepository);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => RouteDetailViewModel(repository),
          ),
          ChangeNotifierProvider(
            create: (_) => FavoritesViewModel(repository)..load(),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RouteDetailScreen(routeId: 'ybs-36'),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.text('အချိန်ဇယား'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 3),
    );

    expect(find.text('First Bus'), findsOneWidget);
  });
}
