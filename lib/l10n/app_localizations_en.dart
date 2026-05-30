// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'YBS Guide';

  @override
  String get appNameBurmese => 'Yangon Bus Guide';

  @override
  String get home => 'Home';

  @override
  String get search => 'Search';

  @override
  String get map => 'Map';

  @override
  String get favorites => 'Favorites';

  @override
  String get settings => 'Settings';

  @override
  String get tripPlanner => 'Trip Planner';

  @override
  String get routeNotFound => 'Route not found';

  @override
  String get retry => 'Retry';

  @override
  String get networkErrorTitle => 'Network error';

  @override
  String get networkErrorMessage =>
      'Please check your connection and try again.';

  @override
  String get loading => 'Loading';

  @override
  String get searchHint => 'Search route, stop, or destination';

  @override
  String get clear => 'Clear';

  @override
  String get all => 'All';

  @override
  String get airConOnly => 'Air-con only';

  @override
  String get regular => 'Regular';

  @override
  String get recentSearches => 'Recent searches';

  @override
  String get noSearchResults => 'No YBS routes matched your search.';

  @override
  String get tryDifferentSearch =>
      'Try a route number, stop name, or destination.';

  @override
  String fareKyat(String fare) {
    return '$fare MMK';
  }

  @override
  String get noFavorites => 'No saved routes yet';

  @override
  String get removedFromFavorites => 'Removed from favorites';

  @override
  String get undo => 'Undo';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get english => 'English';

  @override
  String get myanmar => 'Myanmar';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'System';

  @override
  String get clearCache => 'Clear cache';

  @override
  String get clearCacheDescription => 'Clear temporary app data';

  @override
  String get cacheCleared => 'Cache cleared';

  @override
  String get versionLoading => 'Version loading...';

  @override
  String get findRoutes => 'Find routes';

  @override
  String get fromStop => 'From';

  @override
  String get toStop => 'To';

  @override
  String get noTripResults => 'No trip results yet';

  @override
  String get directRoute => 'Direct route';

  @override
  String get transferRoute => 'Transfer route';

  @override
  String changeAt(String stop) {
    return 'Change at $stop';
  }

  @override
  String stopsCount(int count) {
    return '$count stops';
  }
}
