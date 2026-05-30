import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/string_extensions.dart';
import '../../data/models/bus_route.dart';
import '../../data/repositories/ybs_repository.dart';

enum RouteSearchFilter { all, airConOnly, regular }

class SearchViewModel extends ChangeNotifier {
  SearchViewModel(this._repository);

  static const _recentSearchesKey = 'recent_route_searches';
  static const _debounceDuration = Duration(milliseconds: 300);

  final YbsRepository _repository;
  Timer? _debounceTimer;

  String searchQuery = '';
  List<BusRoute> filteredRoutes = [];
  List<String> recentSearches = [];
  bool isLoading = false;
  RouteSearchFilter selectedFilter = RouteSearchFilter.all;

  Future<void> loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    recentSearches = prefs.getStringList(_recentSearchesKey) ?? [];
    notifyListeners();
  }

  void search(String query) {
    searchQuery = query;
    isLoading = true;
    notifyListeners();

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () => _runSearch(query));
  }

  Future<void> applyFilter(RouteSearchFilter filter) async {
    selectedFilter = filter;
    await _runSearch(searchQuery, saveRecentSearch: false);
  }

  Future<void> clearSearch() async {
    _debounceTimer?.cancel();
    searchQuery = '';
    filteredRoutes = [];
    isLoading = false;
    notifyListeners();
  }

  Future<void> useRecentSearch(String query) async {
    searchQuery = query;
    await _runSearch(query);
  }

  Future<void> _runSearch(String query, {bool saveRecentSearch = true}) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      filteredRoutes = [];
      isLoading = false;
      notifyListeners();
      return;
    }

    final routes = await _repository.getRoutes();
    filteredRoutes = routes.where((route) {
      final matchesQuery =
          route.routeNumber.containsIgnoreCase(trimmedQuery) ||
          route.name.containsIgnoreCase(trimmedQuery) ||
          route.startStop.containsIgnoreCase(trimmedQuery) ||
          route.endStop.containsIgnoreCase(trimmedQuery) ||
          route.stops.any((stop) => stop.name.containsIgnoreCase(trimmedQuery));
      return matchesQuery && _matchesFilter(route);
    }).toList();

    if (saveRecentSearch) {
      await _saveRecentSearch(trimmedQuery);
    }

    isLoading = false;
    notifyListeners();
  }

  bool _matchesFilter(BusRoute route) {
    return switch (selectedFilter) {
      RouteSearchFilter.all => true,
      RouteSearchFilter.airConOnly => route.isAirCon,
      RouteSearchFilter.regular => !route.isAirCon,
    };
  }

  Future<void> _saveRecentSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    recentSearches = [
      query,
      ...recentSearches.where((recent) => recent != query),
    ].take(10).toList();
    await prefs.setStringList(_recentSearchesKey, recentSearches);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
