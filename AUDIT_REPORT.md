# YBS Guide Completion Audit Report

Audit date: 2026-05-30  
Project path: `D:\YBS_Project\ybs_guide`

## Section 1: Project Structure

### Full `lib/` Folder Tree

```text
lib
|   main.dart
|
+---core
|   +---constants
|   |       app_colors.dart
|   |       app_constants.dart
|   |       app_strings.dart
|   |       route_names.dart
|   |
|   +---routes
|   |       app_router.dart
|   |
|   +---theme
|   |       app_theme.dart
|   |
|   +---utils
|           string_extensions.dart
|
+---data
|   +---datasources
|   |       local_database.dart
|   |       local_ybs_datasource.dart
|   |       seed_data_loader.dart
|   |
|   +---models
|   |       bus.dart
|   |       bus_route.dart
|   |       bus_stop.dart
|   |       data_source_metadata.dart
|   |       favorite_route.dart
|   |       schedule.dart
|   |       stop.dart
|   |
|   +---repositories
|           route_repository.dart
|           ybs_repository.dart
|
+---l10n
|       app_en.arb
|       app_localizations.dart
|       app_localizations_en.dart
|       app_localizations_my.dart
|       app_my.arb
|
+---presentation
    +---screens
    |   |   favorites_screen.dart
    |   |   home_screen.dart
    |   |   map_screen.dart
    |   |   route_detail_screen.dart
    |   |   search_screen.dart
    |   |   settings_screen.dart
    |   |   trip_planner_screen.dart
    |   |   welcome_screen.dart
    |   |
    |   +---favorites
    |   |       favorites_screen.dart
    |   |
    |   +---home
    |   |       home_screen.dart
    |   |
    |   +---map
    |   |       map_screen.dart
    |   |
    |   +---route_detail
    |   |       route_detail_screen.dart
    |   |
    |   +---search
    |   |       search_screen.dart
    |   |
    |   +---trip_planner
    |           trip_planner_screen.dart
    |
    +---viewmodels
    |       app_settings_view_model.dart
    |       favorites_view_model.dart
    |       home_view_model.dart
    |       map_view_model.dart
    |       route_detail_view_model.dart
    |       search_view_model.dart
    |       trip_planner_view_model.dart
    |
    +---widgets
            app_error_widget.dart
            app_shell.dart
            cached_app_image.dart
            loading_widget.dart
            route_card.dart
```

### Required Folder Checklist

| Folder | Status |
|---|---|
| `lib/core/constants/` | Exists |
| `lib/core/theme/` | Exists |
| `lib/core/utils/` | Exists |
| `lib/data/models/` | Exists |
| `lib/data/repositories/` | Exists |
| `lib/data/datasources/` | Exists |
| `lib/presentation/screens/` | Exists |
| `lib/presentation/widgets/` | Exists |
| `lib/presentation/viewmodels/` | Exists |

### Dart File Count

Total `.dart` files under `lib/`: **49**

### Dependency Checklist

| Dependency | Status |
|---|---|
| `provider` | Present |
| `go_router` | Present |
| `sqflite` | Present |
| `shared_preferences` | Present |
| `flutter_map` | Present |
| `latlong2` | Present |
| `google_fonts` | Present |
| `flutter_svg` | Present |
| `cached_network_image` | Present |
| `intl` | Present |
| `flutter_localizations` | Present |

Additional useful dependencies currently present: `geolocator`, `package_info_plus`, `cupertino_icons`.

## Section 2: Screens Completion Status

Wrapper files exist in `lib/presentation/screens/*.dart` and export the real screen implementations from nested folders where applicable.

| Screen | Main implementation checked | Status | Evidence |
|---|---|---|---|
| `home_screen.dart` | `lib/presentation/screens/home/home_screen.dart` | Complete | Real map-first home UI, floating search/brand area, draggable panel, quick access, nearby stops, route sections, pull-to-refresh. |
| `search_screen.dart` | `lib/presentation/screens/search/search_screen.dart` | Complete | Real search bar, filter chips, recent searches, results list, route-detail navigation, Provider-backed `SearchViewModel`. |
| `route_detail_screen.dart` | `lib/presentation/screens/route_detail/route_detail_screen.dart` | Complete | Real route header, favorite/share actions, `TabBar`/`TabBarView`, stops timeline, schedule view, map tab. |
| `map_screen.dart` | `lib/presentation/screens/map/map_screen.dart` | Complete | Real `FlutterMap`, route polylines, stop markers, search overlay, filter controls, location button, draggable bottom sheet. |
| `favorites_screen.dart` | `lib/presentation/screens/favorites/favorites_screen.dart` | Complete | Real favorites list, `Dismissible` swipe delete with undo snackbar, `ReorderableListView.builder`, empty state, detail navigation. |
| `settings_screen.dart` | `lib/presentation/screens/settings_screen.dart` | Complete | Real settings UI with theme/language controls, cache/data actions, source metadata, version area. |

## Section 3: Navigation and State Management

### Navigation

Navigation is configured with `go_router` in `lib/core/routes/app_router.dart`.

Registered routes:

| Path | Screen / Purpose |
|---|---|
| `/welcome` | Welcome/loading screen with startup location permission request |
| `/` | Home tab |
| `/search` | Search tab |
| `/map` | Map tab |
| `/favorites` | Favorites tab |
| `/route/:id` | Route detail screen |
| `/settings` | Settings screen |
| `/trip-planner` | Trip planner screen |

The app uses `StatefulShellRoute.indexedStack` for the main bottom-tab shell.

### State Management

Primary state management: **Provider + ChangeNotifier**.

Configured providers in `lib/main.dart`:

| Provider | Purpose |
|---|---|
| `LocalDatabase` | SQLite database singleton |
| `YbsRepository` | Data/repository access |
| `AppSettingsViewModel` | Theme/language settings |
| `HomeViewModel` | Home route/stops data |
| `SearchViewModel` | Search query/filter/recent searches |
| `FavoritesViewModel` | Favorites persistence/reorder/delete |
| `MapViewModel` | Map filters/search/location/selection |
| `RouteDetailViewModel` | Route detail tabs, selected route/stop/direction |
| `TripPlannerViewModel` | Stop picker and route planning |

Some screens also use local `StatefulWidget` state for controllers, tab controllers, text fields, and local UI animation.

### ViewModel Coverage

| Area | ViewModel / Notifier |
|---|---|
| Home | `HomeViewModel` |
| Search | `SearchViewModel` |
| Route Detail | `RouteDetailViewModel` |
| Map | `MapViewModel` |
| Favorites | `FavoritesViewModel` |
| Settings | `AppSettingsViewModel` |
| Trip Planner | `TripPlannerViewModel` |

### Bottom Navigation

Bottom navigation is implemented in `lib/presentation/widgets/app_shell.dart` with 4 tabs:

| Tab | Route |
|---|---|
| Home | `/` |
| Search | `/search` |
| Map | `/map` |
| Favorites | `/favorites` |

Status: **Working by design**. It uses `StatefulNavigationShell.goBranch()` and preserves tab state through `StatefulShellRoute.indexedStack`.

## Overall Summary

The requested Flutter project foundation is in place: MVVM-style Provider architecture, required folder structure, SQLite data layer, localization files, major screens, route navigation, and bottom tabs are implemented.

Main remaining production gaps to consider next:

- Replace sample route data with a maintained official/community YBS data sync workflow.
- Add production signing credentials outside source control.
- Add deeper emulator/device QA for location permission, map rendering, and route detail flows.
- Implement or verify advanced map production features such as marker clustering and offline tile caching if those are release requirements.
