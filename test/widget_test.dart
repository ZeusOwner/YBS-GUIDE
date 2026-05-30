import 'package:flutter_test/flutter_test.dart';

import 'package:ybs_guide/data/datasources/local_ybs_datasource.dart';
import 'package:ybs_guide/data/repositories/ybs_repository.dart';
import 'package:ybs_guide/main.dart';

void main() {
  testWidgets('YBS Guide renders home screen', (WidgetTester tester) async {
    final repository = YbsRepository(LocalYbsDatasource());

    await tester.pumpWidget(createYbsGuideApp(repository));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('YBS Guide'), findsWidgets);
    expect(find.text('WHERE TO?'), findsOneWidget);
    expect(find.text('Quick Access'), findsOneWidget);
  });
}
