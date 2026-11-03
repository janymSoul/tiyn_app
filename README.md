# tiyn_app

Flutter app (Android first) for tasks and pocket money for teens and parents. Backend: the `tiyn` repo (`docs/api.md`).

## Prerequisites

- Flutter 3.47.9 (pinned in `pubspec.yaml`)
- Android SDK and an emulator or device
- A Google OAuth client for the flavor's package (see `docs/plans/phase-0-foundation.md`, "Human tasks")

## Flavors

| Flavor | applicationId | Label | API |
|---|---|---|---|
| `dev` | `kz.tiyn.app.dev` | `tiyn dev` | local backend, `http://10.0.2.2:8080` |
| `staging` | `kz.tiyn.app` | `tiyn staging` | `https://api-staging.tiyn.dev` |
| `prod` | `kz.tiyn.app` | `tiyn` | `https://api.tiyn.dev` (placeholder) |

`staging` shares the prod application ID for the MVP, so the two can't be installed side by side, and staging builds must never be uploaded to Google Play.

## Run

Each flavor needs its `env/*.json` passed as dart-defines; the app refuses to start without them.

```
flutter run --flavor dev     --dart-define-from-file=env/dev.json      # local backend at http://10.0.2.2:8080
flutter run --flavor staging --dart-define-from-file=env/staging.json
flutter run --flavor prod    --dart-define-from-file=env/prod.json
```

VS Code launch configurations for all three are in `.vscode/launch.json`.

## Build

```
flutter build apk --debug --flavor staging --dart-define-from-file=env/staging.json
flutter build apk --release --flavor prod  --dart-define-from-file=env/prod.json
```

Release builds are signed from `android/key.properties` (never committed); without it they fall back to the debug key and can't be uploaded to Play.

## Plans

Implementation plans live in `docs/plans/`.
