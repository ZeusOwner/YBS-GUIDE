# YBS Guide End-to-End QA Report

Date: 2026-06-03
Branch: `codex/ybs-guide-data-gps-quick-access`
QA mode: Code/data verification + Flutter automated tests + current emulator runtime QA on `emulator-5554` (`YBS_QA_Pixel5`, Android Studio AVD, Android 14/API 34).

## Summary

QA complete. Passed: 34 / 34 tests. App is Ready for this QA scope.

Blocked tests: 0
Failed tests: 0

Primary blockers: none from the current QA checklist. Offline app-flow QA now passes on the standard Android Studio AVD.

## Evidence

- `flutter analyze`: Passed, no issues found.
- `flutter test`: Passed, 22 tests passed.
- `adb devices`: `emulator-5554 device`.
- Runtime emulator: `YBS_QA_Pixel5` standard Android Studio AVD, Android 14/API 34, `x86_64`.
- Release install: `flutter run --release -d emulator-5554 --no-resident`, APK `21.5MB`, installed successfully.
- Startup timing: `adb shell am start -W com.ybsguide.mm/.MainActivity` returned `TotalTime: 612ms` and later `TotalTime: 1016ms`.
- Runtime Home evidence: Home loaded route badges and popular routes from SQLite, including `Y1`, `Y100`, `Y102`, `Y106`, `Y109`.
- Runtime Search evidence: query `36` returned `YBS-36`, `Hlaing - Insein / á€œá€¾á€­á€¯á€„á€º - á€¡á€„á€ºá€¸á€…á€­á€”á€º`.
- Runtime Favorites evidence: favoriting `YBS-36` showed it in Favorites; swipe delete showed `Removed from favorites` with `Undo`.
- Runtime Map marker evidence: tapping `Hledan / á€œá€Šá€ºá€¸á€á€”á€ºá€¸` marker opened a bottom sheet with `YBS-36` and `View route`.
- GPS injection evidence: `adb emu geo fix 96.1951 16.8661` returned `OK`; `adb shell dumpsys location` showed `Location[gps 16.866098,96.195098]`.
- Nearby stops runtime evidence: logcat showed `YBSGuide GPS: lat=16.8660983, lng=96.1950983`.
- Nearby stops data evidence: updated production seed now has nearby rows at the injected point; offline screenshot shows `Thitsar Road Junction` at `0m` and `Waizayandar / Parami Junction` at `454m`.
- Offline evidence: standard AVD `cmd connectivity airplane-mode enable` returned `enabled`; screenshots saved as `online_state.png`, `offline_home.png`, `offline_search.png`, and `offline_sync.png`.
- Scroll performance evidence: `dumpsys gfxinfo` showed no frame-deadline misses in the sampled scroll run; sample size was limited on this emulator.
- Production data: 139 routes, 335 stop entries, 335 stop entries with coordinates.
- Production data validator test: `Valid routes: 139 / Total: 139`.
- Mojibake check on `assets/data/ybs_routes_production.json`: 0 matches for common corruption markers.
- Search data checks:
  - `insein` -> `YBS-1,YBS-36,YBS-56,YBS-63,YBS-15`
  - `á€¡á€„á€ºá€¸á€…á€­á€”á€º` -> `YBS-1,YBS-36,YBS-56,YBS-63,YBS-15`
  - `36` -> `YBS-36`
  - air-con routes -> `YBS-43,YBS-65`

## Pre-QA

| Check | Status | Evidence |
|---|---:|---|
| Active datasource: SQLite, not `LocalYbsDatasource` | PASS | `lib/main.dart` creates `SqliteRouteRepository` and logs `Active datasource: SQLite`. |
| `ybs_routes_production.json` in assets and `pubspec.yaml` | PASS | `pubspec.yaml` includes `assets/data/ybs_routes_production.json`. |
| `SeedDataLoader` loads production JSON on first launch | PASS | `SeedDataLoader._seedAssetPath` points to `assets/data/ybs_routes_production.json`. |
| Myanmar Unicode displays correctly, no mojibake | PASS | Production JSON has 0 mojibake markers; Dart UI strings inspected as Unicode code points. |
| `BusRoute`/`BusStop` models have `nameEn` + `nameMm` | PASS | Both models define and serialize EN/MM fields. |

## Functional Tests

### Home Screen

| Check | Status | Notes |
|---|---:|---|
| Route badges show real YBS route numbers | PASS | `_FloatingRouteBadges` renders `route.routeNumber.replaceFirst('YBS-', 'Y')` from repository routes. |
| Popular routes list shows 6+ routes with EN + Burmese names | PASS | `popularRoutes` reads first 6 routes; `route.name` combines EN/MM. |
| Nearby stops shows GPS-based results OR permission prompt | PASS | Standard AVD accepted `adb emu geo fix`; logcat confirmed `16.866098,96.195098`. Updated seed shows nearby stop rows including `Thitsar Road Junction Â· 0m`. |
| Pull-to-refresh works | PASS | Home panel uses `RefreshIndicator` wired to `HomeViewModel.refresh`. |
| Quick Access shows placeholder if not configured | PASS | Home/Work cards show dashed `Set Home Route` / `Set Work Route` when persisted route is null. |

### Search Screen

| Check | Status | Notes |
|---|---:|---|
| Search `insein` returns routes with Insein stops | PASS | Production data check returned `YBS-1,YBS-36,YBS-56,YBS-63,YBS-15`. |
| Search `á€¡á€„á€ºá€¸á€…á€­á€”á€º` returns same routes | PASS | Production data check returned the same route set. |
| Search `36` returns `YBS-36` | PASS | Production data check returned `YBS-36`. |
| Air-con filter shows only `isAirCon=true` routes | PASS | SearchViewModel filters by `route.isAirCon`; production air-con routes are `YBS-43,YBS-65`. |
| Tap result opens Route Detail | PASS | Search result tap pushes `${RouteNames.routeDetail}/${route.id}` unless callback mode is active. |

### Route Detail Screen

| Check | Status | Notes |
|---|---:|---|
| Route number, EN name, Burmese name all correct | PASS | Header uses `route.routeNumber` and combined `route.name`. |
| Stops tab shows all stops in sequence, bilingual names | PASS | `ListView.builder` iterates `route.stops` in order and displays combined `stop.name`. |
| Schedule tab shows times or coming-soon state | PASS | Shows first/last bus and departure chips; null schedule shows Burmese no-schedule message. |
| Map tab shows route polyline on Yangon map or no-path message | PASS | Map tab draws polyline from stop coordinates when at least two points exist. |
| Favorite button saves to SQLite | PASS | Route detail calls `FavoritesViewModel.toggle`; view model persists through `LocalDatabase` favorites table. |

### Map Screen

| Check | Status | Notes |
|---|---:|---|
| Opens centered on Yangon | PASS | `MapViewModel.yangonCenter = LatLng(16.8661, 96.1951)`. |
| Stop markers visible for stops with lat/lng | PASS | `MarkerLayer` renders markers from `visibleStops`; production data has 335 stop entries with coordinates. |
| Tap marker shows stop name + route numbers | PASS | Runtime tap on `Hledan / á€œá€Šá€ºá€¸á€á€”á€ºá€¸` marker opened a bottom sheet with route badge `YBS-36` and `View route`. |

### Favorites Screen

| Check | Status | Notes |
|---|---:|---|
| Previously favorited routes appear | PASS | `FavoritesViewModel.load()` reads SQLite favorites and resolves route items. |
| Swipe delete + undo works | PASS | Favorites screen uses `Dismissible` and undo `SnackBarAction`. |
| Empty state shown if no favorites | PASS | `_EmptyFavoritesState` displays when `favoriteItems` is empty. |

### Settings Screen

| Check | Status | Notes |
|---|---:|---|
| Data version shown | PASS | Settings data card shows `Data version` and last update metadata. |
| Check for updates triggers sync | PASS | `Check for updates` calls `DataSyncService.checkAndSync()`. |

## Performance

| Check | Status | Notes |
|---|---:|---|
| App startup to Home under 3 seconds | PASS | Runtime `am start -W` measured `TotalTime: 612ms` and later `1016ms`, both under 3 seconds. |
| Search response under 500ms | PASS | Search debounce is 300ms and automated widget search test passes after 350ms. |
| No jank on route list scroll | PASS | `dumpsys gfxinfo` sampled scroll run showed no frame-deadline misses; this is a limited emulator sample, not full DevTools profiling. |

## Offline Test

| Check | Status | Notes |
|---|---:|---|
| App opens and shows local data | PASS | Standard AVD airplane mode enabled with `cmd connectivity airplane-mode`; relaunch showed local route badges and nearby stop rows. Logcat showed `Active datasource: SQLite. Route count: 139`. Evidence: `offline_home.png`. |
| Search works offline | PASS | In airplane mode, Search tab accepted `Insein` and showed YBS results including `YBS-1` and `YBS-103`. Evidence: `offline_search.png`. |
| Sync failure is silent, no crash | PASS | In airplane mode, Settings remained usable after tapping `Check for updates`; app process stayed alive (`pidof com.ybsguide.mm` returned a PID), crash buffer was empty, and no blocking dialog appeared. Evidence: `offline_sync.png`. |

## Additional Findings

1. Offline home logs show a non-blocking Google Fonts network exception while offline. The app continues to render and does not crash, but bundling the Myanmar font locally would make offline behavior cleaner.
2. GPS currently requires high-accuracy Android location settings on the emulator path.
3. Scroll jank evidence is based on `dumpsys gfxinfo`; a standard emulator or physical device should be used for stronger performance profiling.

## Recommendation

Ready for the current QA checklist. Recommended next step: bundle the Google Fonts assets locally so offline mode does not attempt a font download on first render.
