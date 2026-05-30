import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/route_names.dart';
import '../../l10n/app_localizations.dart';

class AppShell extends StatelessWidget {
  const AppShell({this.child, this.title, this.navigationShell, super.key});

  final String? title;
  final Widget? child;
  final StatefulNavigationShell? navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shell = navigationShell;

    return PopScope(
      canPop: shell == null || shell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || shell == null || shell.currentIndex == 0) {
          return;
        }
        shell.goBranch(0);
      },
      child: Scaffold(
        appBar: title == null ? null : AppBar(title: Text(title!)),
        body: shell ?? child ?? const SizedBox.shrink(),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: NavigationBar(
              height: 70,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.94),
              selectedIndex: shell?.currentIndex ?? _selectedIndex(context),
              onDestinationSelected: (index) {
                if (shell != null) {
                  shell.goBranch(
                    index,
                    initialLocation: index == shell.currentIndex,
                  );
                  return;
                }

                switch (index) {
                  case 0:
                    context.go(RouteNames.home);
                  case 1:
                    context.go(RouteNames.search);
                  case 2:
                    context.go(RouteNames.map);
                  case 3:
                    context.go(RouteNames.favorites);
                }
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home_rounded),
                  label: l10n.home,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.search),
                  label: l10n.search,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.map_outlined),
                  selectedIcon: const Icon(Icons.map_rounded),
                  label: l10n.map,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.bookmark_border_rounded),
                  selectedIcon: const Icon(Icons.bookmark_rounded),
                  label: l10n.favorites,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _selectedIndex(BuildContext context) {
    final String path;
    try {
      path = GoRouterState.of(context).uri.path;
    } catch (_) {
      return 0;
    }
    if (path.startsWith(RouteNames.search)) {
      return 1;
    }
    if (path.startsWith(RouteNames.map)) {
      return 2;
    }
    if (path.startsWith(RouteNames.favorites)) {
      return 3;
    }
    return 0;
  }
}
