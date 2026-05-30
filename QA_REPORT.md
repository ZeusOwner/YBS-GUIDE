# YBS Guide End-to-End QA Report

Date: 2026-05-31  
Branch: `codex/ybs-guide-data-gps-quick-access`  
QA mode: Code/data verification + Flutter automated tests + current emulator runtime QA on `emulator-5554` (LDPlayer, Android 9/API 28).

## Summary

QA complete. Passed: 30 / 34 tests. App is Not Ready.

Blocked tests: 0  
Failed tests: 4  

Primary blockers: current emulator does not accept `adb emu geo fix`, and disabling Wi-Fi/mobile data with `svc` made the LDPlayer ADB shell unresponsive. Runtime GPS nearby-stops and offline checks need a standard Android emulator or physical device.

## Evidence

- `flutter analyze`: Passed, no issues found.
- `flutter test`: Passed, 15 tests passed.
- `adb devices`: `emulator-5554 device`.
- Runtime emulator: LDPlayer Android 9/API 28.
- Release install: `flutter run --release -d emulator-5554 --no-resident`, APK `21.4MB`, installed successfully.
- Startup timing: `adb shell am start -W com.ybsguide.mm/.MainActivity` returned `TotalTime: 612ms` and later `TotalTime: 1016ms`.
- Runtime Home evidence: Home loaded route badges and popular routes from SQLite, including `Y1`, `Y100`, `Y102`, `Y106`, `Y109`.
- Runtime Search evidence: query `36` returned `YBS-36`, `Hlaing - Insein / လှိုင် - အင်းစိန်`.
- Runtime Favorites evidence: favoriting `YBS-36` showed it in Favorites; swipe delete showed `Removed from favorites` with `Undo`.
- Runtime Map marker evidence: tapping `Hledan / လည်းတန်း` marker opened a bottom sheet with `YBS-36` and `View route`.
- GPS injection evidence: `adb emu geo fix 96.1951 16.8661` failed because LDPlayer refused the emulator console TCP connection; device location remained `0.000000,0.000000`.
- Offline evidence: `adb shell svc wifi disable` / `svc data disable` made LDPlayer ADB shell unresponsive and required LDPlayer restart, so offline app behavior could not be verified on this emulator.
- Scroll performance evidence: `dumpsys gfxinfo` showed no frame-deadline misses in the sampled scroll run; sample size was limited on this emulator.
- Production data: 49 routes, 155 stops, 155 stops with coordinates.
- Production data validator test: `Valid routes: 49 / Total: 49`.
- Mojibake check on `assets/data/ybs_routes_production.json`: 0 matches for common corruption markers.
- Search data checks:
  - `insein` -> `YBS-1,YBS-36,YBS-56,YBS-63,YBS-15`
  - `အင်းစိန်` -> `YBS-1,YBS-36,YBS-56,YBS-63,YBS-15`
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
| Nearby stops shows GPS-based results OR permission prompt | FAIL | Runtime permission grant succeeded, but LDPlayer rejected `adb emu geo fix`; location stayed `0.000000,0.000000`, so nearby stop distance rows could not be verified on the current emulator. |
| Pull-to-refresh works | PASS | Home panel uses `RefreshIndicator` wired to `HomeViewModel.refresh`. |
| Quick Access shows placeholder if not configured | PASS | Home/Work cards show dashed `Set Home Route` / `Set Work Route` when persisted route is null. |

### Search Screen

| Check | Status | Notes |
|---|---:|---|
| Search `insein` returns routes with Insein stops | PASS | Production data check returned `YBS-1,YBS-36,YBS-56,YBS-63,YBS-15`. |
| Search `အင်းစိန်` returns same routes | PASS | Production data check returned the same route set. |
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
| Stop markers visible for stops with lat/lng | PASS | `MarkerLayer` renders markers from `visibleStops`; production data has 155 stops with coordinates. |
| Tap marker shows stop name + route numbers | PASS | Runtime tap on `Hledan / လည်းတန်း` marker opened a bottom sheet with route badge `YBS-36` and `View route`. |

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
| App opens and shows local data | FAIL | Could not verify: disabling network with `svc wifi disable` / `svc data disable` made LDPlayer ADB unresponsive and required emulator restart. |
| Search works offline | FAIL | Could not verify for the same LDPlayer network-toggle failure. |
| Sync failure is silent, no crash | FAIL | Could not verify for the same LDPlayer network-toggle failure. |

## Additional Findings

1. GPS nearby-stop runtime QA failed on the current LDPlayer emulator because emulator-console location injection is unavailable.
2. Offline QA failed at the emulator-control layer; LDPlayer became unresponsive after `svc wifi disable` / `svc data disable`.
3. Production dataset currently contains 49 routes, not full 130+ YBS coverage.
4. Scroll jank evidence is based on `dumpsys gfxinfo`; a standard emulator or physical device should be used for stronger performance profiling.

## Recommendation

Not ready for release QA sign-off yet. Immediate next step: rerun GPS and offline QA on a standard Android Studio emulator or physical Android phone, then expand route data coverage toward 130+ routes.
