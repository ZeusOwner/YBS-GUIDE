import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ybs_guide/data/datasources/local_ybs_datasource.dart';
import 'package:ybs_guide/data/repositories/ybs_repository.dart';
import 'package:ybs_guide/main.dart';

void main() {
  testWidgets('Home screen renders correctly', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repository = YbsRepository(LocalYbsDatasource());

    await tester.pumpWidget(createYbsGuideApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('YBS Guide'), findsWidgets);
    expect(find.text('WHERE TO?'), findsOneWidget);
    expect(find.text('Quick Access'), findsOneWidget);
  });
}
