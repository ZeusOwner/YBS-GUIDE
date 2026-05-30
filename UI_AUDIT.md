# YBS Guide UI Audit

Audit date: 2026-05-30  
Project path: `D:\YBS_Project\ybs_guide`

Reference checked against the provided YBS Guide/YBS GO style screenshots.

## Overall Result

The current Home UI visually follows the reference direction: map background, floating app bar, route badges, green search bar, quick access cards, nearby stop cards, and rounded bottom navigation exist.

The main gap is functionality/data quality: several visible elements are using sample route data, static ETA values, or UI-only icons instead of real user/location/voice behavior.

## Element Checklist

| # | Reference element | Widget code exists? | Data source | Burmese rendering | Status |
|---|---|---|---|---|---|
| 1 | App bar: hamburger + logo + `YBS Guide` title | Yes: `lib/presentation/screens/home/home_screen.dart`, `_TopBrandBar`, `_YbsLogo` | Static title from `AppConstants.appNameEn`; logo asset from `AppConstants.ybsLogoAsset` | No Burmese title shown in this bar | ✅ Done |
| 2 | Route badges: colored pills with route numbers | Yes: `_FloatingRouteBadges` | Real route list from `HomeViewModel.routes`, but that currently comes from hardcoded sample data | Not applicable; route badge is route number only | ⚠️ Partial |
| 3 | Search bar: green rounded bar, `WHERE TO?`, mic, map icon | Yes: `_SearchBar` | Static placeholder text; tap opens Search/Map | No Burmese placeholder | ⚠️ Partial |
| 4 | Quick Access: Home/Work cards with icons and arrows | Yes: `_QuickAccessRoutes`, `_QuickAccessCard` | Uses `recentRoutes`, which is currently `routes.take(4)`; no saved Home/Work prefs | Labels are English only | ⚠️ Partial |
| 5 | Nearby Stops cards: bilingual name, ETA, gradient bar | Yes: `_NearbyStopCards`, `_NearbyStopCard` | Uses first 2 stops from current route list; ETA is static `2 min` | Data contains corrupted Burmese mojibake, not valid Myanmar Unicode | ⚠️ Partial |
| 6 | Bottom nav: Home, Search, Map, Favorites | Yes: `lib/presentation/widgets/app_shell.dart`, `NavigationBar` | Navigation state from `StatefulNavigationShell` | Labels come from localization | ✅ Done |

## Specific Functionality Checks

### Quick Access Cards

Status: **⚠️ Partial**

- Code: `lib/presentation/screens/home/home_screen.dart`
- Widgets: `_QuickAccessRoutes`, `_QuickAccessCard`
- Current behavior:
  - Displays up to 2 routes from `HomeViewModel.recentRoutes`.
  - `recentRoutes` is defined as `routes.take(4).toList()`.
  - Card labels are hardcoded by index: first card `Home`, second card `Work`.
  - Tapping a card opens route detail: `context.push('${RouteNames.routeDetail}/${route.id}')`.
- SharedPreferences:
  - Not used for Quick Access.
  - No saved Home/Work route selection exists.
- Data:
  - Currently backed by hardcoded sample route data through `YbsRepository(LocalYbsDatasource())`.
  - In active app data, this means Home/Work will normally show `YBS-36` and `YBS-65`.

### Nearby Stops

Status: **⚠️ Partial**

- Code: `lib/presentation/screens/home/home_screen.dart`
- Widgets: `_NearbyStopCards`, `_NearbyStopCard`
- Current behavior:
  - Uses `routes.expand((route) => route.stops).take(2)`.
  - Does not calculate distance from user GPS.
  - Does not sort by nearest stop.
  - Displays static ETA text: `'$routeNumber - 2 min'`.
- Location:
  - `HomeViewModel` checks permission using `Geolocator.checkPermission()`.
  - It does not fetch current position or compute nearby distances.
- Tap behavior:
  - Nearby Stop card is a plain `Container`.
  - No `InkWell`, `GestureDetector`, or `onTap` exists for stop card navigation/details.

### Congestion/Frequency Bar

Status: **✅ Done visually / ⚠️ Partial functionally**

- Code: `_NearbyStopCard`
- Implementation:
  - Uses `LinearGradient` with green/yellow/red colors.
  - It is not a static image.
- Data behavior:
  - The bar is static.
  - It is not tied to real frequency, bus arrival, or congestion data.

### Voice Search Microphone Icon

Status: **❌ Missing functionality**

- Code: `_SearchBar`
- Current behavior:
  - `Icons.mic_none_rounded` is displayed inside the green search bar.
  - It has no separate tap handler.
  - No speech-to-text package or voice search flow was found in the checked UI path.
- Result:
  - The microphone is UI decoration only.

### Map Icon in Search Bar

Status: **✅ Done**

- Code: `_SearchBar`
- Current behavior:
  - Far-right map icon button calls `onMapTap`.
  - Home panel passes `onMapTap: () => context.go(RouteNames.map)`.
  - It navigates to the Map tab.

### Route Badge Colors

Status: **✅ Done**

- Code: `_FloatingRouteBadges`, `_routeColor(BusRoute route)`
- Current behavior:
  - Reads `route.color`.
  - Parses route hex color dynamically.
  - Displays per-route colored pills.
- Data limitation:
  - Active route list is still sample data, so only sample route colors appear unless data wiring is changed.

### Burmese Stop Names

Status: **⚠️ Partial / data issue**

- Model support:
  - `BusStop.name` exists.
  - `BusRoute.name` exists.
- Data issue:
  - Names are stored as one combined string such as `English / Burmese`.
  - English and Myanmar names are not separated into `nameEn` and `nameMm`.
  - Current Burmese-looking text in checked data appears mojibake/encoding-corrupted, for example `á€...`, not valid Myanmar Unicode.
- Result:
  - Burmese text rendering cannot be considered correct until the data is replaced/fixed with valid Myanmar Unicode.

## Additional Checks

### Hamburger Menu

Status: **⚠️ Partial**

- Code: `_TopBrandBar`
- Current behavior:
  - Hamburger icon exists: `Icons.menu_rounded`.
  - Tapping it runs `context.push(RouteNames.settings)`.
- Drawer/bottom sheet:
  - No `Drawer`, `showModalBottomSheet`, or menu bottom sheet is attached to the hamburger.
  - It is effectively a Settings shortcut, not a real drawer/menu.

### Tapping a Nearby Stop Card

Status: **❌ Missing**

- Current behavior:
  - No tap action.
  - The card is a passive `Container`.
- Expected next behavior:
  - Open stop detail, nearby routes list, or map focused on the stop.

### Tapping Home or Work in Quick Access

Status: **✅ Done**

- Current behavior:
  - Opens route detail screen for the corresponding route.
  - Uses `context.push('${RouteNames.routeDetail}/${route.id}')`.
- Limitation:
  - Home/Work are not user-configured saved destinations.
  - They are just labels over the first two current routes.

## Screen-by-Screen Evidence

| File | Relevant widgets / behavior |
|---|---|
| `lib/presentation/screens/home/home_screen.dart` | `_TopBrandBar`, `_FloatingRouteBadges`, `_HomePanel`, `_SearchBar`, `_QuickAccessRoutes`, `_NearbyStopCards` |
| `lib/presentation/widgets/app_shell.dart` | `NavigationBar` with Home/Search/Map/Favorites |
| `lib/presentation/viewmodels/home_view_model.dart` | Loads routes, exposes recent/popular routes, checks location permission only |
| `lib/data/datasources/local_ybs_datasource.dart` | Active sample route data: `YBS-36`, `YBS-65` |

## Final UI Gap Summary

| Area | Status | Main gap |
|---|---|---|
| Screenshot visual match | Good | Some text/spacing can still be tuned, but major visual elements exist |
| Real data usage | Partial | Active Home UI uses sample routes through hardcoded datasource |
| Burmese support | Partial/Poor | UI can render fonts, but current route/stop data is encoding-corrupted |
| Location-based nearby stops | Missing | Permission check exists, but no GPS distance calculation |
| Voice search | Missing | Microphone icon only |
| Hamburger menu | Partial | Opens Settings directly; no drawer/menu sheet |
| Quick Access personalization | Missing | No SharedPreferences-backed Home/Work saved routes |

## Recommended Next UI Work

1. Wire Home/Search/Map screens to SQLite-backed production route data instead of `LocalYbsDatasource`.
2. Replace mojibake Burmese route/stop names with valid Myanmar Unicode.
3. Add real nearby stop calculation with `Geolocator.getCurrentPosition()` and `latlong2.Distance`.
4. Make Nearby Stop cards tappable and route to a stop detail or map-focused view.
5. Store Quick Access Home/Work route choices in SharedPreferences or SQLite.
6. Either implement voice search with a speech package or remove/disable the mic icon until supported.
7. Decide whether the hamburger should open Settings directly or a real drawer/bottom sheet menu.
