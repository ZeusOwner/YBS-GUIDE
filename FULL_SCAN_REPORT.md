# YBS Guide - Full Production Readiness Scan

Date: 2026-06-04
Scope: Flutter source, Android release config, data layer, production route assets, localization, tests, release artifacts, and Play Store metadata.
Excluded: generated build folders and transient Flutter/Gradle output.

## Executive Summary

Release recommendation: NO-GO for public Play Store launch.

The app is technically buildable and the core Flutter test suite passes, but it is not yet strong enough for real public users because the production data and live update path are incomplete. The most serious issues are:

1. Android release manifest is missing `android.permission.INTERNET`.
2. Remote GitHub sync manifest URL returns 404.
3. Production dataset has 139 routes, but only 19 routes have 5+ stops; 120 routes are terminal-only.
4. Route shapes and schedules are present but not verified against an official/current GTFS or YRTA source.
5. Store readiness is incomplete: feature graphic, hosted privacy policy URL, contact email, and Play Console package availability are still pending.

Overall readiness estimate:
- App code and UI shell: 70%
- Production data quality: 30%
- Release configuration: 75%
- Play Store listing readiness: 55%
- Public launch readiness: 55%

## Validation Results

| Check | Result | Evidence |
| --- | --- | --- |
| `flutter analyze` | PASS | `No issues found!` |
| `flutter test` | PASS | 22 tests passed |
| Production route validator | PASS | `Valid routes: 139 / Total: 139` |
| Signed AAB exists | PASS | `D:\YBS_Project\release_v1.0.0\app-release.aab`, 54.5 MB |
| ARM64 APK exists | PASS | `D:\YBS_Project\release_v1.0.0\app-arm64-release.apk`, 20.8 MB |
| Package ID | PASS | `com.ybsguide.mm` |
| Android target SDK | PASS | 34 |
| Android min SDK | PASS | 24 |

## Critical Blockers

### 1. Release AndroidManifest missing INTERNET permission

File: `android/app/src/main/AndroidManifest.xml`

Current main manifest declares only:
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`

Debug/profile manifests include `INTERNET`, but release/main does not. This affects:
- OpenStreetMap tile loading
- GitHub route sync
- cached network images
- any future remote API integration

Impact: production release may be unable to use network features.

Required fix:
Add this to the main manifest:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### 2. Remote route data sync is configured to a 404 URL

File: `lib/data/services/data_sync_service.dart`

Configured URL:

```text
https://raw.githubusercontent.com/ZeusOwner/ybs-data/main/manifest.json
```

Scan result: `404 Not Found`.

Impact:
- Route data auto-update currently cannot work.
- Settings "Check for updates" cannot pull real production data.
- The app relies only on bundled seed data.

Required fix:
- Create `ZeusOwner/ybs-data` repository or update `manifestUrl`.
- Publish valid `manifest.json` and `routes.json`.
- Include checksum and route count matching the uploaded routes file.
- Add an integration test for sync success and sync failure.

### 3. Data is not production-real enough

File: `assets/data/ybs_routes_production.json`

Current metrics:
- Routes: 139
- Stop entries: 400
- Unique stop IDs: 72
- Routes with 5+ stops: 19
- Terminal-only routes: 120
- Routes with schedule arrays: 139
- Air-con routes: 2
- Dataset confidence: 0.55
- Broken Myanmar route fields: 0

The count is good, but the quality is not. Most routes only know terminal A and terminal B. This makes these features inaccurate:
- Search by intermediate stop
- Nearby stops
- Trip planner
- Transfer routing
- Route detail stop order
- Map route path

Required fix:
- Import official/verified YBS data from GTFS/GeoJSON/OSM-compatible source.
- Store real stop sequences per route.
- Store real route shapes, not straight-line terminal-derived paths.
- Mark incomplete routes visibly as "terminal data only" until verified.

## High Priority Issues

### 1. `LocalYbsDatasource` still exists with sample data

File: `lib/data/datasources/local_ybs_datasource.dart`

The active app path uses SQLite, but this legacy datasource still contains `_sampleRoutes`. It also contains old corrupted Myanmar sample strings.

Impact:
- Future imports/tests can accidentally reintroduce fake data.
- It weakens confidence that all code paths use production SQLite.

Recommendation:
- Delete it if no longer used, or move it into test-only fixtures.
- Add a guard test that production `main.dart` never wires `LocalYbsDatasource`.

### 2. Search does not query SQLite directly

File: `lib/presentation/viewmodels/search_view_model.dart`

The view model loads all routes through `YbsRepository.getRoutes()` and filters in memory.

This is fine for 139 routes, but weak for a production route/stop database with many stop aliases, township names, Unicode variants, and future data expansion.

Recommendation:
- Add repository method `searchRoutes(query, filter)`.
- Search route number, route names, stop names, landmarks, and aliases at SQLite level.
- Add normalized Myanmar search fields.

### 3. Trip planner is too simple for public use

File: `lib/presentation/viewmodels/trip_planner_view_model.dart`

Current algorithm:
- Direct route if both stops are in one route.
- One-transfer route if two routes share any stop.

Limitations:
- No real walking distance between nearby transfer stops.
- No direction validation.
- No time/headway scoring.
- No stop sequence validity for terminal-only data.
- No multi-transfer fallback.

Recommendation:
- Build a graph from verified stop sequences.
- Include nearby-stop transfer edges within 100-200m.
- Score by transfers, estimated stops, walking distance, and fare.
- Hide transfer suggestions for terminal-only routes.

### 4. Map data is visually useful but not authoritative

Files:
- `lib/presentation/screens/map/map_screen.dart`
- `assets/data/ybs_routes_production.json`

The map displays markers and polylines, but most route paths are not verified real route geometry.

Recommendation:
- Store official route shapes from GTFS `shapes.txt` or verified GeoJSON.
- Use a tile provider policy suitable for production. Public OSM tile servers are not recommended for production apps at scale.
- Add offline/cached tile strategy or commercial tile provider.

### 5. Location permission UX is risky

File: `lib/presentation/viewmodels/home_view_model.dart`

The home view model requests location during load. This can feel abrupt and may hurt Play review/user trust unless the welcome screen clearly explains why location is needed.

Recommendation:
- Ask after welcome/onboarding explanation.
- Provide "Use without location" path.
- Request permission only after user taps nearby stops/location button.

## Medium Priority Issues

### 1. Play Store listing is incomplete

Files:
- `store_listing/play_store_listing.md`
- `store_listing/graphics_needed.md`
- `store_listing/privacy_policy.md`
- `store_listing/release_checklist.md`

Ready:
- title
- short description
- full description draft
- screenshot references
- category draft
- release notes

Missing:
- hosted privacy policy URL
- contact email in privacy policy
- 512x512 Play Store icon export
- 1024x500 feature graphic
- Play Console content rating questionnaire
- Play Console package name availability final check
- Data Safety form final answers

### 2. Privacy policy is not publishable yet

File: `store_listing/privacy_policy.md`

The contact field still says `[your email]`.

Recommendation:
- Add real developer support email.
- Host policy on GitHub Pages, website, or public URL before Play submission.

### 3. Tests are good but not enough for release confidence

Current tests:
- Unit tests: 7 files
- Widget tests: 3 files
- Integration tests: 1 file
- Total run result: 22 tests passed

Gaps:
- No real-device integration test for production SQLite seed.
- No test for release manifest permissions.
- No remote sync success test against a real manifest.
- No Play Store AAB smoke install via bundletool.
- No map tile/provider test.
- No permission UX regression test.

### 4. Generated QA screenshots are stored in project root

Files:
- `final_*.png`
- `final_*_ui.xml`
- `offline_*.png`
- `online_state.png`

These are useful evidence, but they clutter the project root.

Recommendation:
- Move to `qa_evidence/`.
- Add a clean retention policy.
- Keep only screenshots needed for Play Store listing.

## What Is Working

- Flutter app builds and tests pass.
- MVVM-ish Provider architecture is present.
- SQLite database schema exists with routes, stops, schedules, favorites, and data source metadata.
- Seed loader uses `assets/data/ybs_routes_production.json`.
- Route models support English/Myanmar split fields.
- Home screen, Search, Route Detail, Map, Favorites, Settings, Trip Planner, and Welcome screens exist.
- GoRouter with indexed bottom navigation works.
- Favorites persist through SQLite.
- Quick Access persists through SharedPreferences.
- GPS-based nearby stops logic exists.
- Release signing is configured with production keystore.
- AAB and ARM64 APK artifacts exist.
- Bundled Noto Sans Myanmar font is configured.

## Data Layer Assessment

Current active source:

```text
Bundled JSON -> SeedDataLoader -> SQLite -> YbsRepository -> ViewModels
```

Remote update target:

```text
GitHub raw manifest/routes JSON -> validate -> SQLite upsert
```

Current status:
- Offline seed path: working
- SQLite read path: working
- Remote sync path: configured but blocked by 404 manifest
- Official data integration: partial/not proven
- Real-world stop completeness: poor
- Real-world route geometry: poor/partial
- Real-world schedule accuracy: unverified

Data quality score: Partial/Poor for production transit use.

## Release Configuration Assessment

Current:
- `applicationId`: `com.ybsguide.mm`
- `versionCode`: 1
- `versionName`: 1.0.0
- `minSdk`: 24
- `targetSdk`: 34
- `minifyEnabled`: true
- `shrinkResources`: true
- signing: production keystore

Issues:
- Release/main manifest lacks `INTERNET`.
- Play Store normally prefers AAB, which exists.
- Universal APK is large; ARM64 APK is much better for direct testing.
- Kotlin Gradle Plugin warning exists for `package_info_plus` and `shared_preferences_android`; not blocking today but should be monitored.

## Recommended Production Data Plan

Best strategy: Hybrid verified data pipeline.

1. Keep bundled SQLite/JSON seed for offline first launch.
2. Maintain public GitHub data repo for route updates.
3. Use official/YRTA/JICA/GTFS-derived data as source of truth.
4. Use OSM/community data only as validation/fallback.
5. Publish `manifest.json` with version, checksum, routeCount, lastUpdated, and minAppVersion.
6. Update SQLite only after checksum and validator pass.
7. Add source/confidence labels per route.
8. In UI, display "verified", "estimated", or "terminal-only" data quality.

## Ordered Next Steps

Step 1: Add release `INTERNET` permission - 15 minutes.

Step 2: Create/repair GitHub raw data repository and sync manifest - 1 to 2 hours.

Step 3: Replace terminal-only route data with real stop sequences for top 50 routes - 2 to 5 days depending on source availability.

Step 4: Import verified route geometry/shapes - 1 to 3 days.

Step 5: Change UI to label incomplete routes and hide unreliable trip plans - 1 day.

Step 6: Improve search with SQLite-level normalized English/Myanmar query support - 1 day.

Step 7: Rework trip planner using real stop graph and transfer distances - 2 to 4 days.

Step 8: Host privacy policy and complete Play Store graphics - 0.5 to 1 day.

Step 9: Run final device QA from AAB-generated APKs using bundletool - 0.5 day.

## Final Verdict

YBS Guide is a strong prototype and internal release candidate, but it is not ready for public Play Store users yet.

Top 3 blockers:
1. Missing release `INTERNET` permission.
2. Remote data sync manifest returns 404.
3. Dataset is mostly terminal-only and not real enough for route search, nearby stops, map paths, and trip planning.

Recommended immediate action:
Fix release networking and remote sync first, then focus on real production route/stop data before public launch.
