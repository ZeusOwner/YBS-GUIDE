import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../presentation/screens/favorites_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/map_screen.dart';
import '../../presentation/screens/route_detail_screen.dart';
import '../../presentation/screens/search_screen.dart';
import '../../presentation/screens/settings_screen.dart';
import '../../presentation/screens/trip_planner_screen.dart';
import '../../presentation/screens/welcome_screen.dart';
import '../../presentation/viewmodels/home_view_model.dart';
import '../../presentation/widgets/app_shell.dart';
import '../../l10n/app_localizations.dart';
import '../constants/route_names.dart';

class AppRouter {
  const AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.welcome,
    routes: [
      GoRoute(
        path: RouteNames.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.search,
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.map,
                builder: (context, state) => const MapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.favorites,
                builder: (context, state) => const FavoritesScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '${RouteNames.routeDetail}/:id',
        builder: (context, state) {
          final routeId = state.pathParameters['id'] ?? '';
          return RouteDetailScreen(routeId: routeId);
        },
      ),
      GoRoute(
        path: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.tripPlanner,
        builder: (context, state) => const TripPlannerScreen(),
      ),
      GoRoute(
        path: '/select-route/:type',
        builder: (context, state) {
          final type = state.pathParameters['type'] == 'work' ? 'work' : 'home';
          return SearchScreen(
            title: type == 'work' ? 'Set Work Route' : 'Set Home Route',
            onRouteSelected: (route) async {
              await context.read<HomeViewModel>().setQuickAccessRoute(
                type,
                route.id,
              );
              if (context.mounted) {
                context.pop();
              }
            },
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('YBS Guide')),
      body: Center(child: Text(AppLocalizations.of(context).routeNotFound)),
    ),
  );
}
