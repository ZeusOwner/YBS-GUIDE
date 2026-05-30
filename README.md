# YBS Guide

YBS Guide is a Flutter app for browsing Yangon Bus Service routes, stops, schedules, maps, favorites, and simple trip plans. It supports Android and iOS, English and Myanmar text, local SQLite seed data, and OpenStreetMap rendering.

## Setup

1. Install Flutter stable.
2. From the project root, run:

```bash
flutter pub get
flutter gen-l10n
flutter test
```

3. Run the app:

```bash
flutter run
```

## Route Data

Seed route data lives in:

```text
assets/data/ybs_routes.json
```

To add a route, append a new object to the `routes` array with:

- `id`
- `routeNumber`
- `name`
- `startStop`
- `endStop`
- `farePrice`
- `isAirCon`
- `color`
- `stops`
- `schedule`
- `routePath`

After editing the JSON, reinstall the app or clear the seed flag/database during development so the seed loader can import the new data.

## Android Build

The Android package is configured as:

```text
com.ybsguide.mm
```

Release shrinking is enabled. To configure signing:

1. Copy `android/key.properties.template` to `android/key.properties`.
2. Replace placeholder values with your keystore details.
3. Build:

```bash
flutter build appbundle --release
```

## iOS Build

The iOS bundle identifier is configured as:

```text
com.ybsguide.mm
```

Minimum deployment target is iOS 12.0.

Build with:

```bash
flutter build ios --release
```

Open `ios/Runner.xcworkspace` in Xcode to configure signing and archive for App Store/TestFlight.

## Tests

```bash
flutter test
flutter test integration_test
```

## Screenshots

Add screenshots here before store submission:

- Home
- Search
- Route Detail
- Map
- Favorites
