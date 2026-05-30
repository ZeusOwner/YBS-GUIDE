import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ybs_guide/data/datasources/local_ybs_datasource.dart';
import 'package:ybs_guide/data/repositories/ybs_repository.dart';
import 'package:ybs_guide/l10n/app_localizations.dart';
import 'package:ybs_guide/presentation/screens/search/search_screen.dart';
import 'package:ybs_guide/presentation/viewmodels/search_view_model.dart';

void main() {
  testWidgets('Search screen filters results', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repository = YbsRepository(LocalYbsDatasource());

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SearchViewModel(repository),
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SearchScreen(),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Hledan');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.textContaining('YBS-36'), findsOneWidget);
  });
}
