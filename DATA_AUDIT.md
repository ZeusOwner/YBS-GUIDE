# YBS Guide Data Layer Audit

Audit date: 2026-05-30  
Project path: `D:\YBS_Project\ybs_guide`

## 1. Data Source Type

Current data source type: **Mixed**

Important finding: the app seeds JSON data into SQLite on startup, but the currently wired UI repository uses a hardcoded Dart sample datasource.

### Active Runtime Source

| Type | Status | Evidence |
|---|---|---|
| Hardcoded Dart List constants | Active for UI | `lib/data/datasources/local_ybs_datasource.dart` |
| JSON asset | Present, used for SQLite seeding | `assets/data/ybs_routes.json` |
| SQLite / sqflite | Present, seeded on first launch | `lib/data/datasources/local_database.dart` and `lib/data/datasources/seed_data_loader.dart` |
| Remote API / Firebase | Not implemented | No HTTP client, Firebase, Firestore collection, or API endpoint usage found in data layer |
| Mock/fake data | Present | `_sampleRoutes` in `lib/data/datasources/local_ybs_datasource.dart` |

### Hardcoded Dart Data

- File: `lib/data/datasources/local_ybs_datasource.dart`
- Line count: **132**
- Hardcoded routes: **2**
- Route IDs/numbers:
  - `ybs-36` / `YBS-36`
  - `ybs-65` / `YBS-65`

### JSON Asset Data

- Path: `assets/data/ybs_routes.json`
- Route entries: **5**
- Route IDs/numbers:
  - `ybs-1` / `YBS-1`
  - `ybs-2` / `YBS-2`
  - `ybs-3` / `YBS-3`
  - `ybs-43` / `YBS-43`
  - `ybs-53` / `YBS-53`

### SQLite Tables

Defined in `lib/data/datasources/local_database.dart`, database version **4**.

Tables defined:

| Table | Purpose | Row count status |
|---|---|---|
| `bus_routes` | Route master data | Runtime DB not inspected; expected 5 rows after JSON seed |
| `bus_stops` | Stops linked to routes | Runtime DB not inspected; expected 20 stop rows after JSON seed |
| `schedules` | Departure schedules | Runtime DB not inspected; expected 10 rows after JSON seed |
| `favorites` | Saved user favorites | User/runtime dependent |
| `data_sources` | Source metadata | Expected 1 row after JSON seed |

Note: SQLite is seeded by `SeedDataLoader`, but current `main.dart` wires `YbsRepository(LocalYbsDatasource())`, so most screen ViewModels read the hardcoded datasource instead of `LocalDatabase`.

### Remote API / Firebase

No active remote API or Firebase data source was found.

The only HTTP URL found is metadata/source attribution:

- `https://jicayangonbusta.wordpress.com/up-to-date-information-for-gtfs/`

This is not used as a live API endpoint.

## 2. Current Route Data Completeness

### Active App Data

Because the active UI datasource is `LocalYbsDatasource`, the current app-facing route data is:

- Bus routes: **2**
- Stop entries: **4**
- Route IDs/numbers:
  - `ybs-36` / `YBS-36`
  - `ybs-65` / `YBS-65`
- Departure schedules: populated
- GPS coordinates: present for all active stops
- Burmese/Myanmar names: present-looking text exists, but it appears mojibake/encoding-corrupted instead of valid Myanmar Unicode.

### Seed JSON Data

The JSON seed file contains:

- Bus routes: **5**
- Stop entries: **20**
- Unique stop IDs: **16**
- Schedule entries: **10**
- Empty departure schedules: **0**
- Stops missing latitude/longitude: **0**
- Route names with valid Myanmar Unicode detected: **0 of 5**
- Stop names with valid Myanmar Unicode detected: **0 of 20**

The JSON route/stop names include Burmese-looking text, but the file currently stores it as mojibake such as `á€...`, not valid Myanmar Unicode code points.

### Seed JSON Route IDs/Numbers

| ID | Route number |
|---|---|
| `ybs-1` | `YBS-1` |
| `ybs-2` | `YBS-2` |
| `ybs-3` | `YBS-3` |
| `ybs-43` | `YBS-43` |
| `ybs-53` | `YBS-53` |

### One Complete Sample Route Entry

```json
{
  "id": "ybs-1",
  "routeNumber": "YBS-1",
  "name": "Insein - Shwedagon Area / á€¡á€„á€ºá€¸á€…á€­á€”á€º - á€›á€½á€¾á€±á€á€­á€‚á€¯á€¶á€¡á€”á€®á€¸",
  "startStop": "Insein",
  "endStop": "Shwedagon Area",
  "farePrice": 400,
  "isAirCon": false,
  "color": "#1B5E20",
  "stops": [
    {
      "id": "insein-market",
      "name": "Insein Market / á€¡á€„á€ºá€¸á€…á€­á€”á€ºá€ˆá€±á€¸",
      "latitude": 16.8904,
      "longitude": 96.0999,
      "routes": ["ybs-1"],
      "landmark": "Insein Market"
    },
    {
      "id": "hlaing-campus",
      "name": "Hlaing Campus / á€œá€¾á€­á€¯á€„á€ºá€á€€á€¹á€€á€žá€­á€¯á€œá€º",
      "latitude": 16.8456,
      "longitude": 96.1287,
      "routes": ["ybs-1", "ybs-2"],
      "landmark": "Yangon University Hlaing Campus"
    },
    {
      "id": "myaynigone",
      "name": "Myaynigone / á€™á€¼á€±á€”á€®á€€á€¯á€”á€ºá€¸",
      "latitude": 16.8015,
      "longitude": 96.1435,
      "routes": ["ybs-1", "ybs-3"],
      "landmark": "Myaynigone Junction"
    },
    {
      "id": "shwedagon",
      "name": "Shwedagon Pagoda / á€›á€½á€¾á€±á€á€­á€‚á€¯á€¶á€˜á€¯á€›á€¬á€¸",
      "latitude": 16.7983,
      "longitude": 96.1496,
      "routes": ["ybs-1"],
      "landmark": "Shwedagon Pagoda"
    }
  ],
  "schedule": [
    {
      "routeId": "ybs-1",
      "direction": "forward",
      "departureTimes": ["05:30", "05:45", "06:00", "06:15", "06:30"],
      "operatingDays": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
      "firstBus": "05:30",
      "lastBus": "21:30"
    },
    {
      "routeId": "ybs-1",
      "direction": "reverse",
      "departureTimes": ["05:45", "06:00", "06:15", "06:30", "06:45"],
      "operatingDays": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
      "firstBus": "05:45",
      "lastBus": "21:45"
    }
  ]
}
```

## 3. Data Models Completeness

### `BusRoute`

File: `lib/data/models/bus_route.dart`

| Required field | Status |
|---|---|
| `id` | Present |
| `routeNumber` | Present |
| `name` EN+MM | Present as one combined `String`, not structured EN/MM fields |
| `startStop` | Present |
| `endStop` | Present |
| `stops` | Present |
| `schedule` | Present |
| `farePrice` | Present |
| `isAirCon` | Present |
| `color` | Present |

Extra fields present: `routePath`, `source`, `sourceUrl`, `lastUpdated`, `confidence`.

Missing/weak areas:

- English and Myanmar names are not separate fields.
- Current Burmese text in the seed/hardcoded data appears encoding-corrupted.

### `BusStop`

File: `lib/data/models/bus_stop.dart`

| Required field | Status |
|---|---|
| `id` | Present |
| `name` EN+MM | Present as one combined `String`, not structured EN/MM fields |
| `latitude` | Present |
| `longitude` | Present |
| `routes` | Present |
| `landmark` | Present |

Missing/weak areas:

- English and Myanmar names are not separate fields.
- Current Burmese stop names appear encoding-corrupted in data.

### `Schedule`

File: `lib/data/models/schedule.dart`

| Required field | Status |
|---|---|
| `routeId` | Present |
| `direction` | Present as `RouteDirection` enum |
| `departureTimes` | Present |
| `firstBus` | Present |
| `lastBus` | Present |

Extra field present: `operatingDays`.

Missing fields: none from the requested checklist.

## 4. Repository Pattern

### `RouteRepository`

File: `lib/data/repositories/route_repository.dart`

The abstract interface is defined.

| Method | Interface | Implementation | Data source |
|---|---|---|---|
| `getAllRoutes()` | Present | Present | `LocalDatabase.getAllRoutes()` |
| `getRouteById()` | Present | Present | `LocalDatabase.getRouteById()` |
| `searchRoutes()` | Present | Present | `LocalDatabase.searchRoutes()` |
| `getStopsByRoute()` | Present | Present | `LocalDatabase.getStopsByRoute()` |

The implementation does not return hardcoded data directly. It calls SQLite and returns empty lists/null only on caught exceptions.

### Active App Repository

File: `lib/data/repositories/ybs_repository.dart`

The currently wired repository in `main.dart` is:

```dart
final repository = YbsRepository(LocalYbsDatasource());
```

That means the app-facing ViewModels currently use hardcoded `_sampleRoutes`, not the SQLite-backed `RouteRepositoryImpl`.

## 5. Output Summary

| Item | Result |
|---|---|
| Data source type | Mixed |
| Active app source | Hardcoded Dart `_sampleRoutes` |
| Seed source | JSON Asset |
| Persistence layer | SQLite / sqflite present |
| Remote API/Firebase | Not implemented |
| Current active route count | 2 |
| Seed JSON route count | 5 |
| Current active stop count | 4 |
| Seed JSON stop entries | 20 |
| Schedule data | Populated |
| GPS coordinates | Present |
| Burmese Unicode quality | Poor; text appears mojibake/encoding-corrupted |
| Model field completeness | Structurally good, but EN/MM names are not separated |
| Repository pattern | Partially complete; SQLite repository exists but app is wired to hardcoded datasource |

## Data Quality Score

**Partial**

Reason:

- Data model structure is mostly complete.
- JSON seed and SQLite schema exist.
- Schedules and coordinates are populated.
- However, the active app data is still hardcoded sample data with only 2 routes.
- The SQLite-backed repository exists but is not the repository currently wired into the app.
- Burmese text data is not valid Myanmar Unicode in the inspected files.
