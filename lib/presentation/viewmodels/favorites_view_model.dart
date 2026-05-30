import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/datasources/local_database.dart';
import '../../data/models/bus_route.dart';
import '../../data/models/favorite_route.dart';
import '../../data/repositories/ybs_repository.dart';

class FavoriteRouteItem {
  const FavoriteRouteItem({required this.favorite, required this.route});

  final FavoriteRoute favorite;
  final BusRoute route;
}

class FavoritesViewModel extends ChangeNotifier {
  FavoritesViewModel(this._repository, {LocalDatabase? database})
    : _database = database ?? LocalDatabase.instance;

  final YbsRepository _repository;
  final LocalDatabase _database;
  final StreamController<List<FavoriteRouteItem>> _favoritesController =
      StreamController<List<FavoriteRouteItem>>.broadcast();

  List<FavoriteRoute> favorites = [];
  List<FavoriteRouteItem> favoriteItems = [];
  List<String> favoriteIds = [];
  List<BusRoute> favoriteRoutes = [];

  Stream<List<FavoriteRouteItem>> get favoritesStream =>
      _favoritesController.stream;

  Future<void> load() async {
    try {
      favorites = await _database.getFavorites();
    } catch (_) {
      favorites = [];
    }
    await _hydrateRoutes();
  }

  Future<void> addFavorite(String routeId, {String? nickname}) async {
    final favorite = FavoriteRoute(
      routeId: routeId,
      savedAt: DateTime.now(),
      sortOrder: favorites.length,
      nickname: nickname,
    );
    try {
      await _database.saveFavorite(favorite);
    } catch (_) {
      favorites = [...favorites, favorite];
    }
    await load();
  }

  Future<void> removeFavorite(String routeId) async {
    try {
      await _database.deleteFavorite(routeId);
    } catch (_) {
      favorites = favorites
          .where((favorite) => favorite.routeId != routeId)
          .toList();
    }
    await load();
  }

  Future<void> restoreFavorite(FavoriteRoute favorite) async {
    try {
      await _database.saveFavorite(favorite);
    } catch (_) {
      favorites = [...favorites, favorite];
    }
    await load();
  }

  Future<void> reorderFavorites(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final items = [...favoriteItems];
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    favorites = [
      for (var index = 0; index < items.length; index++)
        items[index].favorite.copyWith(sortOrder: index),
    ];

    try {
      await _database.updateFavoriteOrder(favorites);
    } catch (_) {
      // Keep in-memory order if SQLite is unavailable in tests.
    }
    await _hydrateRoutes();
  }

  Future<void> toggle(String routeId) async {
    if (favoriteIds.contains(routeId)) {
      await removeFavorite(routeId);
    } else {
      await addFavorite(routeId);
    }
  }

  Future<void> _hydrateRoutes() async {
    final routes = await _repository.getRoutes();
    favoriteIds = favorites.map((favorite) => favorite.routeId).toList();
    favoriteItems = [
      for (final favorite in favorites)
        if (routes.any((route) => route.id == favorite.routeId))
          FavoriteRouteItem(
            favorite: favorite,
            route: routes.firstWhere((route) => route.id == favorite.routeId),
          ),
    ];
    favoriteRoutes = favoriteItems.map((item) => item.route).toList();
    _favoritesController.add(favoriteItems);
    notifyListeners();
  }

  @override
  void dispose() {
    _favoritesController.close();
    super.dispose();
  }
}
