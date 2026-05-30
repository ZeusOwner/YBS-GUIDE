# YBS Guide Data Gap Report

Audit date: 2026-05-30  
Project path: `D:\YBS_Project\ybs_guide`

## Step 1: Count Current Data

Current codebase contains two route datasets:

| Dataset | File | Route count | Route numbers |
|---|---|---:|---|
| Active app hardcoded datasource | `lib/data/datasources/local_ybs_datasource.dart` | 2 | `YBS-36`, `YBS-65` |
| JSON seed dataset | `assets/data/ybs_routes.json` | 5 | `YBS-1`, `YBS-2`, `YBS-3`, `YBS-43`, `YBS-53` |
| Combined current codebase data | hardcoded + JSON seed | 7 | `YBS-1`, `YBS-2`, `YBS-3`, `YBS-36`, `YBS-43`, `YBS-53`, `YBS-65` |

Important: app UI is currently wired to the hardcoded datasource, so users only see **2 active routes** unless the repository wiring is changed to SQLite/seeded JSON.

## Step 2: Check for Real YBS Routes

Baseline route list checked: 49 representative real YBS route numbers provided in the audit request.

| Route | Status |
|---|---|
| YBS-1 | ✅ Present |
| YBS-2 | ✅ Present |
| YBS-3 | ✅ Present |
| YBS-6 | ❌ Missing |
| YBS-7 | ❌ Missing |
| YBS-9 | ❌ Missing |
| YBS-11 | ❌ Missing |
| YBS-12 | ❌ Missing |
| YBS-15 | ❌ Missing |
| YBS-19 | ❌ Missing |
| YBS-21 | ❌ Missing |
| YBS-24 | ❌ Missing |
| YBS-25 | ❌ Missing |
| YBS-30 | ❌ Missing |
| YBS-33 | ❌ Missing |
| YBS-36 | ✅ Present |
| YBS-37 | ❌ Missing |
| YBS-38 | ❌ Missing |
| YBS-40 | ❌ Missing |
| YBS-43 | ✅ Present |
| YBS-46 | ❌ Missing |
| YBS-51 | ❌ Missing |
| YBS-53 | ✅ Present |
| YBS-56 | ❌ Missing |
| YBS-58 | ❌ Missing |
| YBS-60 | ❌ Missing |
| YBS-63 | ❌ Missing |
| YBS-65 | ✅ Present |
| YBS-66 | ❌ Missing |
| YBS-69 | ❌ Missing |
| YBS-72 | ❌ Missing |
| YBS-80 | ❌ Missing |
| YBS-85 | ❌ Missing |
| YBS-88 | ❌ Missing |
| YBS-93 | ❌ Missing |
| YBS-96 | ❌ Missing |
| YBS-100 | ❌ Missing |
| YBS-102 | ❌ Missing |
| YBS-106 | ❌ Missing |
| YBS-109 | ❌ Missing |
| YBS-110 | ❌ Missing |
| YBS-127 | ❌ Missing |
| YBS-130 | ❌ Missing |
| YBS-138 | ❌ Missing |
| YBS-155 | ❌ Missing |
| YBS-174 | ❌ Missing |
| YBS-188 | ❌ Missing |
| YBS-202 | ❌ Missing |
| YBS-209 | ❌ Missing |

## Step 3: Gap Summary

| Metric | Result |
|---|---:|
| Routes present in representative list | 7 / 49 |
| Routes missing from representative list | 42 |
| Estimated coverage against ~130 total YBS routes | 7 / 130 = 5.4% |
| Active app route coverage against ~130 total YBS routes | 2 / 130 = 1.5% |
| Stop entries in active hardcoded data | 4 |
| Stop entries in JSON seed data | 20 |
| Stop data completeness for current codebase routes | 100% of current 7 routes have stops |
| Stop data completeness against ~130 production routes | About 5.4% by route coverage |
| Schedule completeness for current codebase routes | 100% of current 7 routes have schedule arrays populated |
| Schedule completeness against ~130 production routes | About 5.4% by route coverage |

Data quality caveat: current Burmese route/stop text appears encoding-corrupted in the inspected files, so production readiness is lower than the raw field counts suggest.

## Step 4: Data Integration Options

### Option A: Manual JSON Entry in `assets/data/ybs_routes.json`

| Offline | Maintenance | Update |
|---|---|---|
| Yes | High | Requires APK release |

Recommended for YBS Guide: **No, except for initial seed data.**

Why: it is simple and reliable offline, but manually maintaining ~130+ routes, stops, schedules, route path coordinates, and Burmese names inside an APK asset will become slow and error-prone. Every route update requires rebuilding and distributing a new APK.

### Option B: SQLite `.db` File Bundled with APK

| Offline | Maintenance | Update |
|---|---|---|
| Yes | Medium | Requires APK release |

Recommended for YBS Guide: **Partial.**

Why: good for faster startup, structured queries, search, favorites joins, and larger datasets. It is better than raw JSON for production-size route data. The weakness is updates still require APK releases unless paired with a sync layer.

### Option C: Firebase Firestore

| Offline | Maintenance | Update |
|---|---|---|
| Partial | Low | Real-time, no APK needed |

Recommended for YBS Guide: **Not as the primary source for this app.**

Why: Firestore gives easy remote updates and client caching, but it adds account/billing/security rules/admin tooling overhead. For a single developer and public transit reference data, Firestore may be heavier than needed. Offline behavior is partial and initial cold-start still depends on having synced data before.

### Option D: GitHub Raw JSON

| Offline | Maintenance | Update |
|---|---|---|
| No | Low | Push to GitHub, instant |

Recommended for YBS Guide: **No as the only source; yes as an update channel.**

Why: this is very easy for a single developer to maintain, version, review, and update. But the app cannot depend on it exclusively because users need bus data in low/no internet areas.

### Option E: Hybrid Bundled JSON/SQLite + Optional GitHub Sync

| Offline | Maintenance | Update |
|---|---|---|
| Yes | Low | Background sync |

Recommended for YBS Guide: **Yes.**

Why: the app can ship with a bundled production dataset for offline use, then check a lightweight GitHub-hosted manifest for newer data when internet is available. Updates can be downloaded in the background, validated, saved into SQLite, and used without requiring a new APK.

## Step 5: Recommended Approach

Single best data strategy: **Option E: Hybrid offline bundle + GitHub sync into SQLite.**

Recommended architecture:

1. Ship a bundled production dataset in `assets/data/ybs_routes.json` or a prebuilt SQLite DB.
2. On first launch, import that bundled data into SQLite.
3. Store `data_version`, `last_updated`, `source`, and checksum/hash metadata.
4. When internet is available, fetch a small GitHub raw `manifest.json`.
5. If the remote version is newer, download `routes.json`, validate schema/checksum, then upsert into SQLite.
6. Keep the last known good SQLite data available for offline use.
7. Show users a visible data timestamp such as `Data updated: YYYY-MM-DD`.

Why this is best for YBS Guide:

- Offline use works in no-internet areas of Yangon.
- Route changes can be shipped by pushing JSON to GitHub, without requiring an APK release.
- Maintenance stays realistic for one developer.
- SQLite remains the app's local source of truth for search, map filtering, favorites, trip planner, and future migration support.

## Final Gap Assessment

Current test data is useful for UI development only. It is not production-ready.

Main gaps before production:

- Expand from 7 codebase routes to a production-level YBS dataset.
- Fix app wiring so screens use SQLite-backed data, not hardcoded `_sampleRoutes`.
- Replace corrupted Burmese text with valid Myanmar Unicode.
- Add versioned update/sync logic.
- Add automated schema validation for route/stops/schedules before importing updated data.
