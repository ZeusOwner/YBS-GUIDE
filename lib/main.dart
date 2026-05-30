import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/local_database.dart';
import 'data/datasources/seed_data_loader.dart';
import 'data/repositories/route_repository.dart';
import 'data/repositories/ybs_repository.dart';
import 'data/services/data_sync_service.dart';
import 'data/services/quick_access_service.dart';
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

  final localDatabase = LocalDatabase.instance;
  final seedDataLoader = SeedDataLoader(localDatabase);
  await seedDataLoader.loadIfNeeded();

  final sqliteRepository = SqliteRouteRepository(await localDatabase.database);
  var routeCount = (await sqliteRepository.getAllRoutes()).length;
  if (routeCount == 0) {
    await seedDataLoader.resetSeedFlag();
    await seedDataLoader.loadIfNeeded();
    routeCount = (await sqliteRepository.getAllRoutes()).length;
  }
  debugPrint('Active datasource: SQLite. Route count: $routeCount');

  runApp(createYbsGuideApp(YbsRepository(sqliteRepository)));
}

Widget createYbsGuideApp(YbsRepository repository) {
  return MultiProvider(
    providers: [
      Provider<LocalDatabase>.value(value: LocalDatabase.instance),
      Provider<YbsRepository>.value(value: repository),
      Provider<DataSyncService>(create: (_) => DataSyncService()),
      Provider<QuickAccessService>(create: (_) => QuickAccessService()),
      ChangeNotifierProvider(create: (_) => AppSettingsViewModel()..load()),
      ChangeNotifierProvider(
        create: (context) => HomeViewModel(
          repository,
          context.read<DataSyncService>(),
          context.read<QuickAccessService>(),
        )..load(),
      ),
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
