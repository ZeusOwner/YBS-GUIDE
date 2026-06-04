import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ybs_guide/data/repositories/ybs_repository.dart';
import 'package:ybs_guide/main.dart';

import '../helpers/test_database_helper.dart';

void main() {
  testWidgets('Home screen renders correctly', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final sqliteRepository = await TestDatabaseHelper.createSeededRepository();
    final repository = YbsRepository(sqliteRepository);

    await tester.pumpWidget(createYbsGuideApp(repository));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('YBS Guide'), findsWidgets);
    expect(find.text('WHERE TO?'), findsOneWidget);
    expect(find.text('Quick Access'), findsOneWidget);

    await tester.tap(find.text('WHERE TO?'));
    await tester.pumpAndSettle();

    expect(find.text('YBS Assistant'), findsOneWidget);
  });
}
