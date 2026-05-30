# YBS Guide App — Master Audit Report

Audit date: 2026-05-30  
Project path: `D:\YBS_Project\ybs_guide`

## Overall Completion: 100%

Calculation: screens done / total planned screens x 100 = **6 / 6 x 100 = 100%**.

Note: this is screen implementation completion only. Production readiness is lower because real route data, data wiring, Burmese text quality, and some live behaviors are still incomplete.

## ✅ What is Working

- Project structure is complete with `lib/core`, `lib/data`, `lib/presentation`, `lib/l10n`, widgets, viewmodels, models, repositories, and datasources: `AUDIT_REPORT.md`.
- Required Flutter dependencies are present: `provider`, `go_router`, `sqflite`, `shared_preferences`, `flutter_map`, `latlong2`, `google_fonts`, `flutter_svg`, `cached_network_image`, `intl`, and `flutter_localizations`: `pubspec.yaml`.
- Navigation is configured with `go_router` and `StatefulShellRoute.indexedStack`: `lib/core/routes/app_router.dart`.
- Bottom navigation has 4 tabs: Home, Search, Map, Favorites: `lib/presentation/widgets/app_shell.dart`.
- Back behavior for tabs is handled through `PopScope` and `StatefulNavigationShell.goBranch()`: `lib/presentation/widgets/app_shell.dart`.
- Provider + ChangeNotifier state management is wired in app startup: `lib/main.dart`.
- Home screen has a real map-first UI, top brand bar, route badges, search shortcut, quick access cards, nearby stops, popular route list, and pull-to-refresh: `lib/presentation/screens/home/home_screen.dart`.
- Search screen has real filtering UI, recent searches, result list, filter chips, and route-detail navigation: `lib/presentation/screens/search/search_screen.dart`.
- Route Detail screen has route header, favorite/share actions, tabbed stops/schedule/map UI: `lib/presentation/screens/route_detail/route_detail_screen.dart`.
- Map screen has `flutter_map`, route polylines, stop markers, search overlay, filter controls, location button, and bottom sheet: `lib/presentation/screens/map/map_screen.dart`.
- Favorites screen has saved route list, swipe delete with undo, reorder UI, empty state, and detail navigation: `lib/presentation/screens/favorites/favorites_screen.dart`.
- Settings screen has theme/language controls, cache/data actions, source metadata, and app/version area: `lib/presentation/screens/settings_screen.dart`.
- SQLite schema exists for `bus_routes`, `bus_stops`, `schedules`, `favorites`, and `data_sources`: `lib/data/datasources/local_database.dart`.
- JSON seed loader exists and imports `assets/data/ybs_routes.json` into SQLite on first launch: `lib/data/datasources/seed_data_loader.dart`.
- Data models have constructors, `fromJson`, `toJson`, and `copyWith` for required route/stop/schedule structures: `lib/data/models`.

## ⚠️ What is Partially Done

- Data source is mixed: JSON seed and SQLite exist, but the active app repository still reads hardcoded sample data: `lib/main.dart`, `lib/data/datasources/local_ybs_datasource.dart`.
- Route coverage is only 7 routes in the codebase and only 2 routes in the active app datasource: `DATA_AUDIT.md`, `DATA_GAP_REPORT.md`.
- Burmese route/stop text exists as combined strings but appears encoding-corrupted (`Ã¡â‚¬...`) instead of valid Myanmar Unicode: `assets/data/ybs_routes.json`, `lib/data/datasources/local_ybs_datasource.dart`.
- Route and stop names are modeled as one combined `name` string, not separate `nameEn` and `nameMm` fields: `lib/data/models/bus_route.dart`, `lib/data/models/bus_stop.dart`.
- Nearby Stops UI exists, but it uses the first two stops from route data, not GPS distance sorting: `lib/presentation/screens/home/home_screen.dart`.
- HomeViewModel checks location permission, but it does not fetch current position or calculate nearest stops: `lib/presentation/viewmodels/home_view_model.dart`.
- Quick Access UI exists, but Home/Work labels are hardcoded and not backed by SharedPreferences/user preferences: `lib/presentation/screens/home/home_screen.dart`.
- Congestion/frequency bar is visually implemented as a gradient, but it is static and not tied to live frequency or arrival data: `lib/presentation/screens/home/home_screen.dart`.
- Hamburger menu exists, but it opens Settings directly instead of a drawer or bottom sheet menu: `lib/presentation/screens/home/home_screen.dart`.
- Map is implemented, but production-grade marker clustering/offline tile caching still needs verification or implementation: `UI_AUDIT.md`, `AUDIT_REPORT.md`.

## ❌ What is Missing

| Priority | Missing item | Impact |
|---|---|---|
| Critical | Active app data is still hardcoded sample data | Users see only 2 sample routes instead of production data |
| Critical | Production YBS dataset with 130+ routes is missing | App cannot be used as a real Yangon bus guide |
| Critical | Burmese text is encoding-corrupted | Burmese users will see broken route/stop names |
| High | SQLite-backed repository is not wired into UI ViewModels | Existing seed/database work is not used by screens |
| High | Versioned remote update/sync system is missing | Route changes require manual app update or remain stale |
| High | Schema/data validation for route updates is missing | Bad data can break search/map/detail flows |
| Medium | Nearby stops do not use GPS distance | Nearby section is not actually nearby |
| Medium | Nearby Stop cards have no tap action | Users cannot inspect stop details from the Home section |
| Medium | Quick Access has no saved Home/Work preferences | Cards are not personalized |
| Medium | Voice search is not implemented | Microphone icon is decoration only |
| Low | Hamburger does not open a real drawer/menu | UX differs from expected design |

## Data Layer Status

- Current data source: **Mixed**.
- Active app source: **Hardcoded Dart `_sampleRoutes`**.
- Seed source: **JSON asset imported into SQLite on first launch**.
- Persistence layer: **SQLite/sqflite present**.
- Route count: **7 / 130+ needed** in current codebase; **2 / 130+ active in UI**.
- Stop count: **20 JSON seed stop entries**, **4 active hardcoded stop entries**.
- Offline support: **Yes, partially**. Bundled data and SQLite exist, but active app data is still sample/hardcoded.
- Real data integration status: **Partial**. Schema and seed path exist, but real production data and active SQLite repository wiring are not done.

## Critical Blockers

1. Replace `YbsRepository(LocalYbsDatasource())` with a SQLite-backed production repository so screens read seeded/local database data.
2. Replace corrupted Burmese text with valid Myanmar Unicode and preferably split names into `nameEn` and `nameMm`.
3. Expand data from 7 codebase routes to a production-level 130+ route dataset with stops, schedules, colors, and route paths.
4. Add versioned data update/sync so route changes can be shipped without an APK release.
5. Add import validation for route JSON/SQLite data before saving it into the local database.

## Real YBS Data — Best Integration Plan

### 1. Data format and source

Recommended strategy: **Hybrid bundled offline data + GitHub raw JSON sync into SQLite**.

Use:

- Local source of truth: SQLite tables in `lib/data/datasources/local_database.dart`.
- Bundled initial dataset: `assets/data/ybs_routes.json` or a prebuilt SQLite database.
- Remote update channel: GitHub raw JSON files:
  - `manifest.json`
  - `routes.json`
  - optional `stops.json`
  - optional `route_shapes.json`

Why:

- Works offline after install.
- One developer can maintain JSON in GitHub.
- Updates do not require APK releases.
- SQLite remains efficient for search, map filtering, favorites, and trip planner.

### 2. Step-by-step process to add all 130+ routes

1. Define production JSON schema with explicit `nameEn`, `nameMm`, `startStopEn`, `startStopMm`, `endStopEn`, `endStopMm`, route color, fare, route type, stops, schedules, and route path.
2. Create a `manifest.json` with `version`, `lastUpdated`, `checksum`, `source`, and `minAppVersion`.
3. Clean existing 7 test routes and fix Myanmar Unicode encoding.
4. Import official/YRTA-derived, JICA GTFS, or verified community route data into normalized JSON.
5. Validate every route has required fields, at least terminal stops, coordinates, and route number.
6. Generate or normalize SQLite rows from JSON through the existing `SeedDataLoader`/database layer.
7. Add tests for schema validation, route counts, stop coordinates, Burmese Unicode detection, and repository queries.
8. QA Home, Search, Route Detail, Map, Favorites, and Trip Planner against the expanded dataset.

### 3. How to update route data without releasing new APK

1. App ships with bundled offline dataset.
2. On startup or Settings refresh, app checks remote GitHub raw `manifest.json`.
3. If remote `version` is newer, app downloads `routes.json`.
4. App validates JSON schema and checksum.
5. App imports/upserts data into SQLite in a transaction.
6. If import fails, app keeps the last known good SQLite data.
7. Settings screen shows current data version and last updated date.

### 4. Estimated work effort

| Work item | Estimate |
|---|---|
| Repository rewiring to SQLite | 0.5-1 day |
| Data schema cleanup with EN/MM fields | 1 day |
| GitHub manifest + background sync | 1-2 days |
| Import validation + tests | 1-2 days |
| Build/clean 130+ route dataset | 3-7 days depending on source quality |
| UI QA with real data | 1-2 days |

Total practical estimate: **7-14 working days** for a usable production data pipeline and first real dataset pass.

## Ordered Next Steps

Step 1: Wire UI ViewModels to SQLite-backed route repository instead of `LocalYbsDatasource` — **0.5-1 day**.

Step 2: Fix data model/schema for separate English/Myanmar fields and repair Myanmar Unicode data — **1 day**.

Step 3: Create validated production JSON schema and importer tests — **1-2 days**.

Step 4: Build the first 130+ route dataset from official/community sources and import into SQLite — **3-7 days**.

Step 5: Add GitHub raw manifest/version sync with checksum validation and rollback behavior — **1-2 days**.

Step 6: Implement real nearby-stop logic using GPS + `latlong2.Distance` — **0.5-1 day**.

Step 7: Add Quick Access persistence for Home/Work routes via SharedPreferences or SQLite — **0.5 day**.

Step 8: Decide on voice search: implement speech-to-text or remove the mic icon until supported — **0.5-1 day**.

Step 9: QA on Android device/emulator with expanded data, map, search, detail, favorites, and offline mode — **1-2 days**.

## Tech Debt Found

- Hardcoded active sample routes: `lib/data/datasources/local_ybs_datasource.dart`.
- Active repository wiring uses sample datasource: `lib/main.dart`.
- Static Home search placeholder: `WHERE TO?` in `lib/presentation/screens/home/home_screen.dart`.
- Hardcoded Quick Access labels: `Home` / `Work` in `lib/presentation/screens/home/home_screen.dart`.
- Static nearby ETA: `2 min` in `lib/presentation/screens/home/home_screen.dart`.
- Microphone icon has no action or speech implementation: `lib/presentation/screens/home/home_screen.dart`.
- Nearby Stop cards are not tappable: `lib/presentation/screens/home/home_screen.dart`.
- Burmese text data is mojibake/encoding-corrupted in current route datasets.
- EN/MM names are not modeled separately in `BusRoute` and `BusStop`.
- No remote API/GitHub sync implementation exists yet.
- No data schema validator/checksum import guard exists yet.
- No TODO/FIXME/HACK comments were found in the checked relevant files.

YBS Guide is 100% complete by planned screen implementation. Top 3 blockers: active app uses hardcoded sample data, production 130+ route dataset is missing, Burmese route/stop text is corrupted. Recommended immediate next step: wire the app to SQLite-backed data and remove `LocalYbsDatasource` from active runtime.
