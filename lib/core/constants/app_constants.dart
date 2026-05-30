import 'package:flutter/material.dart';

class AppConstants {
  const AppConstants._();

  static const String appNameEn = 'YBS Guide';
  static const String appNameMm = 'ရန်ကုန်ဘတ်စ်ကားလမ်းညွှန်';
  static const String appTitle = appNameEn;

  static const String welcomeRoute = '/welcome';
  static const String homeRoute = '/';
  static const String searchRoute = '/search';
  static const String routeDetailRoute = '/route';
  static const String mapRoute = '/map';
  static const String favoritesRoute = '/favorites';
  static const String settingsRoute = '/settings';
  static const String tripPlannerRoute = '/trip-planner';

  static const String imageAssetPath = 'assets/images/';
  static const String iconAssetPath = 'assets/icons/';
  static const String svgAssetPath = 'assets/svg/';
  static const String dataAssetPath = 'assets/data/';
  static const String ybsLogoAsset = '${imageAssetPath}ybs_logo.png';
  static const String busIconAsset = '${svgAssetPath}bus.svg';
  static const String routesJsonAsset = '${dataAssetPath}routes.json';
}

class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF1B5E20);
  static const Color primaryDark = Color(0xFF0D3D12);
  static const Color primaryLight = Color(0xFF4C8C4A);
  static const Color secondary = Color(0xFFFFC107);
  static const Color background = Color(0xFFF7FAF7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color darkBackground = Color(0xFF101510);
  static const Color darkSurface = Color(0xFF182018);
  static const Color error = Color(0xFFB3261E);
  static const Color textPrimary = Color(0xFF172117);
  static const Color textSecondary = Color(0xFF5D6B5E);
}

class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const BorderRadius card = BorderRadius.all(Radius.circular(md));
  static const BorderRadius sheet = BorderRadius.all(Radius.circular(lg));
}

class AppElevation {
  const AppElevation._();

  static const double none = 0;
  static const double low = 1;
  static const double medium = 3;
  static const double high = 6;
}
