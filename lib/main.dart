import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/local_database.dart';
import 'data/datasources/local_ybs_datasource.dart';
import 'data/datasources/seed_data_loader.dart';
import 'data/repositories/ybs_repository.dart';
import 'l10n/app_localizations.dart';
import 'presentation/viewmodels/app_settings_view_model.dart';
import 'presentation/viewmodels/favorites_view_model.dart';
import 'presentation/viewmodels/home_view_model.dart';
import 'presentation/viewmodels/map_view_model.dart';
import 'presentation/viewmodels/route_detail_view_model.dart';
import 'presentation/viewmodels/search_view_model.dart';
import 'presentation/viewmodels/trip_planner_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SeedDataLoader(LocalDatabase.instance).loadIfNeeded();

  final repository = YbsRepository(LocalYbsDatasource());

  runApp(createYbsGuideApp(repository));
}

Widget createYbsGuideApp(YbsRepository repository) {
  return MultiProvider(
    providers: [
      Provider<LocalDatabase>.value(value: LocalDatabase.instance),
      Provider<YbsRepository>.value(value: repository),
      ChangeNotifierProvider(create: (_) => AppSettingsViewModel()..load()),
      ChangeNotifierProvider(create: (_) => HomeViewModel(repository)..load()),
      ChangeNotifierProvider(create: (_) => SearchViewModel(repository)),
      ChangeNotifierProvider(
        create: (_) => FavoritesViewModel(repository)..load(),
      ),
      ChangeNotifierProvider(
        create: (_) => MapViewModel(repository)..loadStops(),
      ),
      ChangeNotifierProvider(create: (_) => RouteDetailViewModel(repository)),
      ChangeNotifierProvider(create: (_) => TripPlannerViewModel(repository)),
    ],
    child: const YbsGuideApp(),
  );
}

class YbsGuideApp extends StatelessWidget {
  const YbsGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsViewModel>();

    return MaterialApp.router(
      title: AppConstants.appTitle,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
