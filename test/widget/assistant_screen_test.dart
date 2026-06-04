import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ybs_guide/data/repositories/ybs_repository.dart';
import 'package:ybs_guide/data/services/assistant_service.dart';
import 'package:ybs_guide/presentation/screens/assistant_screen.dart';
import 'package:ybs_guide/presentation/viewmodels/assistant_view_model.dart';

import '../helpers/test_database_helper.dart';

void main() {
  testWidgets('Assistant chat bubbles render user and assistant messages', (
    tester,
  ) async {
    final sqliteRepository = await TestDatabaseHelper.createSeededRepository();
    final repository = YbsRepository(sqliteRepository);
    final service = AssistantService(repository);
    final viewModel = AssistantViewModel(
      repository: repository,
      assistantService: service,
    );
    viewModel.messages = const [
      AssistantMessage(
        author: AssistantMessageAuthor.assistant,
        text: 'Hello! I am your YBS Assistant.',
      ),
      AssistantMessage(
        author: AssistantMessageAuthor.user,
        text: 'YBS 36 Route',
      ),
      AssistantMessage(
        author: AssistantMessageAuthor.assistant,
        text: 'YBS-36 is available from Hlaing to Insein.',
      ),
    ];

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => viewModel,
        child: const MaterialApp(home: AssistantScreen()),
      ),
    );

    expect(find.textContaining('YBS Assistant'), findsWidgets);
    expect(find.text('YBS 36 Route'), findsOneWidget);
    expect(find.textContaining('YBS-36'), findsWidgets);
  });
}
