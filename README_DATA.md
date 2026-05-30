# YBS Guide Route Data Sync

YBS Guide reads route data from local SQLite only. Remote data is an update channel, not a runtime dependency.

## GitHub Repository Layout

Create a separate public data repository, for example:

```text
ybs-data/
├── manifest.json
└── routes.json
```

Expected raw URLs:

```text
https://raw.githubusercontent.com/[YOUR_USERNAME]/ybs-data/main/manifest.json
https://raw.githubusercontent.com/[YOUR_USERNAME]/ybs-data/main/routes.json
```

## `manifest.json`

```json
{
  "version": "1.0.0",
  "lastUpdated": "2026-05-30",
  "routeCount": 130,
  "checksum": "sha256-of-routes-json",
  "minAppVersion": "1.0.0",
  "downloadUrl": "https://raw.githubusercontent.com/[USER]/ybs-data/main/routes.json"
}
```

## `routes.json`

Use the schema shown in `assets/data/schema/route_template.json`.

The file may be either:

```json
[
  { "id": "ybs-1", "routeNumber": "YBS-1" }
]
```

or:

```json
{
  "routes": [
    { "id": "ybs-1", "routeNumber": "YBS-1" }
  ]
}
```

## Update Flow

1. App starts with bundled offline data.
2. Home screen triggers background sync without blocking UI.
3. App downloads `manifest.json`.
4. If remote `version` is newer than local `data_version`, app downloads `routes.json`.
5. App validates SHA256 checksum.
6. App validates every route with `RouteValidator`.
7. If every route is valid, app upserts all routes into SQLite in one transaction.
8. App saves `data_version` and `data_last_updated` to SharedPreferences.
9. If any step fails, SQLite remains unchanged and the app keeps using local data.

## Local Storage Keys

```text
data_version
data_last_updated
```

## Current Placeholder URL

`DataSyncService.manifestUrl` currently points to:

```text
https://raw.githubusercontent.com/ZeusOwner/ybs-data/main/manifest.json
```

Change it if the production data repository uses a different owner or path.
