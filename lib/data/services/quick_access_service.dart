import 'package:shared_preferences/shared_preferences.dart';

class QuickAccessService {
  static const String _homeKey = 'quick_access_home_route_id';
  static const String _workKey = 'quick_access_work_route_id';

  Future<String?> getHomeRouteId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_homeKey);
  }

  Future<String?> getWorkRouteId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_workKey);
  }

  Future<void> setHomeRouteId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_homeKey, id);
  }

  Future<void> setWorkRouteId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_workKey, id);
  }

  Future<void> clearRoute(String type) async {
    final prefs = await SharedPreferences.getInstance();
    if (type == 'home') {
      await prefs.remove(_homeKey);
    } else if (type == 'work') {
      await prefs.remove(_workKey);
    }
  }
}
