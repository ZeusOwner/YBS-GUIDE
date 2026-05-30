import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ybs_guide/data/repositories/ybs_repository.dart';
import 'package:ybs_guide/main.dart';

import '../test/helpers/test_database_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('open app, search route, view detail, save favorite', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final sqliteRepository = await TestDatabaseHelper.createSeededRepository();
    final repository = YbsRepository(sqliteRepository);

    await tester.pumpWidget(createYbsGuideApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'Hledan');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('YBS-36').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });
}
