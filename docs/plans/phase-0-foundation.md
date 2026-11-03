# Phase 0: Foundation — implementation plan

**Audience:** the coding agent that carries this out.
**Repo:** `/Users/medettegistay/Projects/tiyn_app` (Flutter, Android first).
**Backend (read-only reference):** `/Users/medettegistay/Projects/tiyn`. The API contract is `docs/api.md` there. Do **not** edit the backend repo in this phase.
**Design reference:** the Tiyn mockups (37 screens, phone 390×844). The palette and type in `lib/core/theme.dart` already match them.

Phase 0 builds **no new product screens**. It sets up the structure, tools and guardrails that every later screen depends on, and it fixes defects in the existing code. When it's done, the app behaves as it does today (sign in, parent sees join code, teen joins), but on the new foundation, in three languages, with three flavors and CI.

---

## 0. Rules for this work

1. **Work in the order of the steps below.** Each step ends in one commit. After every step, `flutter analyze` and `flutter test` must pass before you commit. Don't batch steps into one commit.
2. **Do not push** and do not create a remote. The user will add the remote.
3. Commit messages: short, conventional-ish (`chore: …`, `refactor: …`, `feat: …`, `fix: …`, `ci: …`). **No `Co-Authored-By` trailer.**
4. **Add packages with `flutter pub add <name>` / `flutter pub add dev:<name>`.** Don't hand-write version numbers. Don't upgrade existing packages unless a step says so.
5. **No speculative features.** If a step doesn't name it, don't build it. No new screens beyond placeholders named here.
6. Comments: minimal. Code should be self-explanatory. A short comment is OK only for a non-obvious rule (e.g. why an idempotency key is reused).
7. **Never log** tokens, Google ID tokens, request or response bodies, names, join codes or proof images. The users are minors.
8. **Stop and ask the user** if: a package API differs from what this plan assumes and the workaround changes the design; a step would need a backend change; the Android build needs Gradle/AGP version changes; or any test you didn't write starts failing for reasons you don't understand.
9. Keep existing behaviour and copy. Where this plan says "move", move the code and change only what's required (imports, names, the fixes listed).

---

## 1. Target architecture (what you're building toward)

```
lib/
  main.dart                     # main(): bootstrap only
  app/
    app.dart                    # TiynApp (MaterialApp.router, theme, l10n)
    config.dart                 # AppConfig: flavor, API base URL, Google client id (fail fast)
    providers.dart              # app-wide providers: token storage, API client, Google identity, session events
    router/
      router.dart               # routerProvider (GoRouter)
      redirect.dart             # pure function resolveRedirect(...) — unit tested
      routes.dart               # path constants
  core/
    network/
      api_client.dart
      api_exception.dart
      idempotency_key.dart
      error_messages.dart       # ApiException code -> localized string
    session/
      role.dart                 # Role enum (shared by auth and family)
      session_events.dart       # "session expired" signal, breaks the core->auth dependency
    storage/
      token_storage.dart
    money/
      money.dart                # value type, minor units
      money_format.dart         # "1 500 ₸"
  design/
    tokens.dart                 # Palette, Space, Radii
    theme.dart                  # buildTheme()
    widgets/
      coin_badge.dart
      app_card.dart
      busy_button.dart
      info_banner.dart
      money_text.dart
  l10n/
    app_en.arb  app_ru.arb  app_kk.arb   (+ generated app_localizations*.dart)
  features/
    auth/
      data/         user.dart, auth_repository.dart, google_identity.dart
      application/  auth_controller.dart
      presentation/ sign_in_screen.dart, splash_screen.dart
    family/
      data/         family_member.dart, family_repository.dart
      application/  family_controller.dart
      presentation/ parent_code_screen.dart, join_teen_screen.dart
    teen/
      presentation/ teen_shell.dart, teen_home_placeholder.dart, placeholder_tab.dart
    parent/
      presentation/ parent_shell.dart, placeholder_tab.dart
```

**Dependency rules** (enforce by review; there's no tool for it yet):
- `core/` and `design/` never import from `features/` or `app/`.
- `features/x/data` never imports Flutter widgets.
- A feature may import another feature's `data/` or `application/` only for `auth` (it's foundational). Everything else goes through `core/`.
- `app/` wires everything and may import anything.

**Riverpod conventions:**
- Use plain `Provider` / `NotifierProvider` / `AsyncNotifierProvider`. No codegen (`riverpod_generator`) in this phase.
- **Every user-scoped provider must rebuild when the signed-in user changes.** Watch `currentUserIdProvider` (step 7). This fixes an existing bug: family data stays cached across sign-out and sign-in of a different account.
- **Disable Riverpod's automatic retry globally** (`ProviderScope(retry: (_, _) => null)`). Retries are explicit in this app because money calls need idempotency keys. Check the exact `retry` signature in the installed Riverpod 3 version.

---

## Step 1 — Git and project hygiene

1. `git init`, default branch `main`.
2. Extend `.gitignore` with:
   ```
   # Signing (never commit)
   android/key.properties
   *.jks
   *.keystore
   # Local env overrides
   env/*.local.json
   # Coverage
   coverage/
   ```
   Keep `.vscode/` tracked (the folder is empty today; you'll add `launch.json` in step 4).
3. First commit: the current code exactly as it is, plus `.gitignore` and this plan file. Message: `chore: initial import`.

**Done when:** `git log` shows one commit and `git status` is clean.

---

## Step 2 — Pin the toolchain and tighten lints

1. In `pubspec.yaml`, set `description:` to `"tiyn: tasks and pocket money for teens and parents."` Under `environment:`, add the exact Flutter version installed on the machine (`flutter --version`, currently `3.47.9`):
   ```yaml
   environment:
     sdk: ^3.13.7
     flutter: 3.47.9
   ```
   CI reads this (step 12), so local and CI builds match.
2. Replace `analysis_options.yaml` with:
   ```yaml
   include: package:flutter_lints/flutter.yaml

   analyzer:
     language:
       strict-casts: true
       strict-inference: true
       strict-raw-types: true
     exclude:
       - build/**
       - android/**
       - ios/**
       - lib/**/*.g.dart
       - lib/**/*.freezed.dart
       - lib/l10n/app_localizations*.dart

   linter:
     rules:
       always_declare_return_types: true
       avoid_dynamic_calls: true
       avoid_print: true
       directives_ordering: true
       prefer_final_locals: true
       prefer_single_quotes: true
       unawaited_futures: true
       use_build_context_synchronously: true
   ```
3. Fix every new analyzer finding in existing code. With `strict-casts`, the casts in `api_error.dart` and the repositories will flag; step 6 rewrites those anyway, so do the smallest fix that compiles.
4. Run `dart format lib test`.

**Done when:** `flutter analyze --fatal-infos` reports zero issues. Commit `chore: pin flutter, strict analysis`.

---

## Step 3 — Android identity, flavors, release-signing hook, INTERNET permission

The app ID is final: **`kz.tiyn.app`**. Flavors:

| Flavor | applicationId | App label | API |
|---|---|---|---|
| `dev` | `kz.tiyn.app.dev` | `tiyn dev` | local backend, cleartext allowed |
| `staging` | `kz.tiyn.app` (shared with prod for the MVP, no suffix) | `tiyn staging` | `https://api-staging.tiyn.dev` |
| `prod` | `kz.tiyn.app` | `tiyn` | (placeholder; no prod backend exists yet) |

1. **`android/app/build.gradle.kts`:**
   - `namespace = "kz.tiyn.app"`, `applicationId = "kz.tiyn.app"`.
   - Move `MainActivity.kt` to `android/app/src/main/kotlin/kz/tiyn/app/MainActivity.kt` and change its `package` line. Delete the old directory.
   - Add the flavors:
     ```kotlin
     flavorDimensions += "env"
     productFlavors {
         create("dev") {
             dimension = "env"
             applicationIdSuffix = ".dev"
             resValue("string", "app_name", "tiyn dev")
         }
         create("staging") {
             dimension = "env"
             resValue("string", "app_name", "tiyn staging")
         }
         create("prod") {
             dimension = "env"
             resValue("string", "app_name", "tiyn")
         }
     }
     ```
     If AGP 9 rejects `resValue`, add `buildFeatures { resValues = true }` inside `android { }`. Don't change AGP, Kotlin or Gradle versions.
   - Release signing: load `android/key.properties` if the file exists and create a `release` signing config from it (`storeFile`, `storePassword`, `keyAlias`, `keyPassword`). If the file is missing, fall back to the debug config and print a Gradle warning: `"key.properties not found: release build is signed with the debug key and cannot be uploaded to Play"`. Remove the template's TODO comments.
2. **`android/app/src/main/AndroidManifest.xml`:**
   - Add `<uses-permission android:name="android.permission.INTERNET"/>`. It's only in the **debug** manifest today, so a release build can't reach the API at all. This is a real defect.
   - `android:label="@string/app_name"`.
3. **Dev cleartext:** create `android/app/src/dev/AndroidManifest.xml`, which merges only into the dev flavor:
   ```xml
   <manifest xmlns:android="http://schemas.android.com/apk/res/android"
       xmlns:tools="http://schemas.android.com/tools">
       <application android:usesCleartextTraffic="true" tools:replace="android:usesCleartextTraffic"/>
   </manifest>
   ```
   (Drop `tools:replace` if the merger complains there's nothing to replace.)
4. **Leave iOS untouched.** It ships later, and its bundle ID changes then.

**Done when:** these all succeed:
```
flutter build apk --debug --flavor dev     --dart-define-from-file=env/dev.json
flutter build apk --debug --flavor staging --dart-define-from-file=env/staging.json
flutter build apk --release --flavor prod  --dart-define-from-file=env/prod.json   # debug-signed fallback, warning printed
```
(Create the `env/` files from step 4 first, or do steps 3 and 4 together and commit them separately.) Check the package name with `aapt dump badging` or `apkanalyzer` if one is available. Commit `build(android): kz.tiyn.app with dev/staging/prod flavors`.

> **Note for the user:** renaming the package breaks Google sign-in on Android until an Android OAuth client exists for `kz.tiyn.app.dev` and `kz.tiyn.app` (staging shares the prod ID for the MVP) with the debug key's SHA-1 (see "Human tasks"). That's expected. Don't work around it in code.

---

## Step 4 — Runtime config per flavor

1. Create `env/dev.json`, `env/staging.json`, `env/prod.json`:
   ```json
   { "FLAVOR": "staging", "API_BASE_URL": "https://api-staging.tiyn.dev", "GOOGLE_SERVER_CLIENT_ID": "" }
   ```
   - dev: `"API_BASE_URL": "http://10.0.2.2:8080"` (the Android emulator's address for the host's localhost).
   - prod: `"API_BASE_URL": "https://api.tiyn.dev"`, a placeholder.
   - `GOOGLE_SERVER_CLIENT_ID` stays empty; the user will fill it in. OAuth client IDs aren't secret, so these files are committed.
2. Replace `lib/core/config.dart` with `lib/app/config.dart`:
   ```dart
   enum Flavor { dev, staging, prod }

   class AppConfig {
     const AppConfig({required this.flavor, required this.apiBaseUrl, required this.googleServerClientId});
     final Flavor flavor;
     final Uri apiBaseUrl;
     final String? googleServerClientId;

     factory AppConfig.fromEnvironment() { … }   // reads String.fromEnvironment('FLAVOR' | 'API_BASE_URL' | 'GOOGLE_SERVER_CLIENT_ID')
   }
   ```
   - **No defaults.** If `FLAVOR` or `API_BASE_URL` is missing or invalid, throw a `StateError` whose message gives the run command (`flutter run --flavor dev --dart-define-from-file=env/dev.json`). Today's silent fallback to staging is how a prod build ends up talking to staging.
   - An empty `GOOGLE_SERVER_CLIENT_ID` becomes `null`.
   - Expose it as `appConfigProvider` (a `Provider<AppConfig>`, overridable in tests).
3. Create `.vscode/launch.json` with three configurations (dev, staging, prod) that pass `--flavor` and `--dart-define-from-file`.
4. In `README.md`, replace the template with: what the app is (one line), prerequisites, the three run commands, the build commands, and a pointer to `docs/plans/`. Keep it short.

**Done when:** `flutter run` without defines fails fast with the helpful message, and the launch configs work. Commit `feat: per-flavor runtime config`.

---

## Step 5 — Folder restructure (move only)

Move the files to the layout in section 1. **No behaviour changes in this step.** Update imports only.

| From | To |
|---|---|
| `lib/main.dart` (`TiynApp` class) | `lib/app/app.dart` (keep `main()` in `lib/main.dart`) |
| `lib/router.dart` | `lib/app/router/router.dart` |
| `lib/core/api_client.dart` | `lib/core/network/api_client.dart` |
| `lib/core/api_error.dart` | `lib/core/network/api_exception.dart` |
| `lib/core/token_storage.dart` | `lib/core/storage/token_storage.dart` |
| `lib/core/theme.dart` | split: `Palette` → `lib/design/tokens.dart`, `buildTheme` → `lib/design/theme.dart` |
| `Role` enum from `features/auth/user.dart` | `lib/core/session/role.dart` |
| `CoinBadge` from `sign_in_screen.dart` | `lib/design/widgets/coin_badge.dart` |
| `_Panel` from `parent_code_screen.dart` | `lib/design/widgets/app_card.dart` as public `AppCard` |
| `features/auth/{user,auth_repository,google_identity}.dart` | `features/auth/data/` |
| `features/auth/auth_controller.dart` | `features/auth/application/` (its providers move in step 7) |
| `features/auth/sign_in_screen.dart` | `features/auth/presentation/` |
| `features/family/{family_member,family_repository}.dart` | `features/family/data/` |
| `features/family/family_controller.dart` | `features/family/application/` |
| `features/family/{parent_code,join_teen}_screen.dart` | `features/family/presentation/` |
| `features/home/home_screens.dart` | deleted in step 8; leave it in place for now |

Use `git mv` so history follows the files.

**Done when:** analyze and test are green and the app runs identically. Commit `refactor: feature-first layout with data/application/presentation`.

---

## Step 6 — Network layer: ApiClient, errors, idempotency

**Problems this fixes:**
- `getJson` assumes every response is a JSON object, but `GET /tasks`, `/goals` and `/payouts` return **top-level arrays**.
- There's no PUT, DELETE or multipart (needed for `PUT /devices`, `DELETE /links/{id}`, proof upload).
- `newIdempotencyKey()` makes it easy to create a fresh key per call, which defeats idempotency on retries.

### 6.1 `ApiException` (`core/network/api_exception.dart`)

```dart
class ApiException implements Exception {
  const ApiException({required this.code, this.statusCode});
  final String code;          // backend error code, or 'network_error' / 'timeout' / 'unknown_error'
  final int? statusCode;

  bool get isUnauthenticated => statusCode == 401;
  bool get isNetwork => code == 'network_error' || code == 'timeout';
  bool get isRetryable => isNetwork || (statusCode != null && statusCode! >= 500) || code == 'concurrent_modification';

  factory ApiException.fromDio(DioException e) { … }
}
```
- Map `DioExceptionType.connectionTimeout`, `sendTimeout` and `receiveTimeout` to `timeout`. Map `connectionError` and missing responses to `network_error`. When the body is `{"error": "<string>"}`, use that string. Otherwise use `unknown_error`.
- `toString()` must not include the response body.

### 6.2 `IdempotencyKey` (`core/network/idempotency_key.dart`)

```dart
/// One key per user action. Reuse the same key when retrying the *same* payload;
/// create a new one when the payload changes or the action succeeded.
extension type const IdempotencyKey(String value) {
  factory IdempotencyKey.generate() => IdempotencyKey(const Uuid().v4());
}
```
(The two-line doc comment is the one allowed explanatory comment here, because it's the non-obvious rule.) Remove `ApiClient.newIdempotencyKey()`.

### 6.3 `ApiClient` (`core/network/api_client.dart`)

Public surface:
```dart
class ApiClient {
  ApiClient({required Uri baseUrl, required TokenStorage tokens, required void Function() onUnauthorized, Dio? dio});

  Future<T> get<T>(String path, {Map<String, Object?>? query, required T Function(Object? json) decode});
  Future<T> post<T>(String path, {Object? body, IdempotencyKey? idempotencyKey, required T Function(Object? json) decode});
  Future<void> postNoContent(String path, {Object? body, IdempotencyKey? idempotencyKey});
  Future<void> put(String path, {Object? body});
  Future<void> delete(String path, {Object? body});
  Future<T> postMultipart<T>(String path, {
    required List<int> bytes, required String filename, required String contentType,
    String fileField = 'file', Map<String, String> fields = const {},
    IdempotencyKey? idempotencyKey, required T Function(Object? json) decode,
  });
}
```
- Use Dio with `ResponseType.json`. Treat the response data as `Object?` and hand it to `decode`. A `204` or empty body passes `null`.
- Timeouts: connect 10 s, receive 20 s, send 60 s (proof uploads on 4G).
- Interceptors, in this order:
  1. **Auth:** adds `Authorization: Bearer <token>` when a token exists.
  2. **Unauthorized:** on 401, calls `onUnauthorized` **only if the request carried a token** (keep the current logic).
  3. **Debug log** (only when `kDebugMode`): method, path **without the query string**, status and duration. Never headers or bodies.
- Every Dio error becomes an `ApiException`. No `DioException` escapes the client.
- Add small decoding helpers in `core/network/json.dart`: `Map<String, Object?> asMap(Object? json)` and `List<Object?> asList(Object? json)`. They throw `ApiException(code: 'invalid_response')` on a wrong shape. These keep `strict-casts` happy without scattering casts.

### 6.4 Error messages (`core/network/error_messages.dart`)

`String apiErrorMessage(AppLocalizations l10n, Object error)`. A switch over known codes, including `network_error`, `timeout`, `unauthenticated`, `forbidden`, `internal_error`, `invalid_identity`, `identity_provider_unavailable`, `invalid_join_code` and `conflict`, plus a fallback that includes the code. Screens may handle specific codes themselves and use this as the default. (It depends on l10n, so write it in step 9. In this step, keep the screens' existing English switch statements working.)

### 6.5 Update the repositories

`AuthRepository` and `FamilyRepository` use the new methods with `decode:` callbacks. `FamilyRepository.unlink(String teenId)` is **not** added. That's Phase 2.

**Tests** (`test/core/network/api_client_test.dart`). Use a fake `HttpClientAdapter` on a real `Dio`; no new mocking package:
- decodes an object body and an array body;
- a 204 gives `decode(null)`;
- `{"error":"invalid_join_code"}` with 422 → `ApiException(code: 'invalid_join_code', statusCode: 422)`;
- a connection error → `network_error`, a receive timeout → `timeout`;
- sends `Idempotency-Key` when given, and not otherwise;
- 401 with a token calls `onUnauthorized` once; 401 without a token doesn't;
- the multipart request has a `file` part with the right content type.

**Done when:** tests are green. Commit `refactor(core): typed ApiClient with explicit idempotency keys`.

---

## Step 7 — Break the auth ↔ API client dependency loop; scope providers by user

**Today:** `apiClientProvider` lives in `auth_controller.dart` and calls `authControllerProvider.notifier.sessionExpired()`. So the network layer depends on the auth feature, and the auth feature depends on the network layer.

1. `core/session/session_events.dart`:
   ```dart
   class SessionExpiredNotifier extends Notifier<int> {
     @override int build() => 0;
     void expired() => state++;
   }
   final sessionExpiredProvider = NotifierProvider<SessionExpiredNotifier, int>(SessionExpiredNotifier.new);
   ```
2. `app/providers.dart` holds `tokenStorageProvider`, `googleIdentityProvider` and `apiClientProvider`. The API client's `onUnauthorized` calls `ref.read(sessionExpiredProvider.notifier).expired()`, so it no longer imports auth.
3. `AuthController.build()` registers `ref.listen(sessionExpiredProvider, (_, _) => _onSessionExpired())`. That clears the token and sets `AsyncData(null)`. Keep the current `/me` 401 handling in `build()`. Make sure a 401 during `build()` doesn't cause a double state change or an exception. Add a test for it.
4. Add `currentUserIdProvider = Provider<String?>((ref) => ref.watch(authControllerProvider.select((s) => s.value?.id)))`.
5. **Fix the stale family bug:** `FamilyController.build()` watches `currentUserIdProvider`. When it's `null`, return `const []` without calling the API. So signing out as a parent and signing in as a teen on the same phone no longer shows the parent's family.
6. Move the auth providers (`authRepositoryProvider`, `authControllerProvider`) so that nothing in `core/` imports a feature. `grep -r "features/" lib/core lib/design` must return nothing.
7. `main.dart`: `runApp(ProviderScope(retry: (_, _) => null, child: const TiynApp()))`. Adjust to the actual Riverpod 3 `retry` signature.

**Tests:**
- `AuthController`: no token → `null`; a token and `/me` OK → user; a token and `/me` 401 → `null` and token cleared; a session-expired event after sign-in → `null`.
- `FamilyController`: refetches when the user ID changes; returns empty without calling the API when signed out.

**Done when:** tests are green and the grep is empty. Commit `refactor: session events decouple network from auth; user-scoped family`.

---

## Step 8 — Router: role-based route trees and a testable redirect

**Today:** everything renders under `/`, and `HomeShell` picks the screen. Push deep links (Phase 1) need real routes, and each role needs its own bottom navigation.

### 8.1 Routes (`app/router/routes.dart`)

```
/splash
/sign-in
/teen/join
/teen/home       ┐
/teen/progress   │ StatefulShellRoute.indexedStack — TeenShell, bottom nav: Home, Progress, Goals, Activity
/teen/goals      │
/teen/activity   ┘
/parent/home     ┐ StatefulShellRoute.indexedStack — ParentShell, bottom nav: Home, To check, Activity
/parent/review   │
/parent/activity ┘
```

### 8.2 Redirect as a pure function (`app/router/redirect.dart`)

```dart
String? resolveRedirect({
  required AsyncValue<User?> auth,
  required AsyncValue<List<FamilyMember>> family,
  required String location,
});
```
Rules, in order:
1. auth is loading with no value, or has an error → `/splash`. The splash screen shows a spinner, or the error with a "Try again" button that calls `ref.invalidate(authControllerProvider)`.
2. Signed out → `/sign-in` (no redirect if already there).
3. Teen:
   - family loading → `/splash`; family error → `/splash`, which shows the error with a retry that invalidates the family provider;
   - no members → `/teen/join`;
   - linked, and the location is `/`, `/splash`, `/sign-in`, `/teen/join` or any `/parent/...` → `/teen/home`.
4. Parent: the location is `/`, `/splash`, `/sign-in` or anything under `/teen/...` → `/parent/home`.
5. Otherwise `null`.

`routerProvider` listens to both `authControllerProvider` and `familyControllerProvider` to refresh. Keep the `ValueNotifier` refresh pattern. `initialLocation: '/splash'`.

### 8.3 Screens

- `SplashScreen` (`features/auth/presentation/`): navy background, the `CoinBadge`, a spinner, or the error and retry.
- `TeenShell` / `ParentShell`: a `Scaffold` with `NavigationBar` whose items match the mockups. Teen: Home, Progress, Goals, Activity. Parent: Home, To check, Activity. The selected item gets a gold pill (`Palette.gold`) behind the icon, as in the mockups. Use `NavigationBarTheme` in `design/theme.dart`, not per-screen styling. Use Material icons that are close to the mockups' line icons.
- Teen Home tab: today's `_TeenHomePlaceholder` content (greeting, `CoinBadge` "0 ₸", connected parents, sign out).
- Parent Home tab: today's `ParentCodeScreen` content (code, share, linked teens), with a sign-out button added at the bottom like the teen placeholder.
- Every other tab: `PlaceholderTab(title)` showing the localized title and "Coming soon".
- Delete `features/home/home_screens.dart`.

**Tests:**
- `test/app/router/redirect_test.dart`: a table test covering every rule above (aim for at least 12 cases).
- Widget tests: a signed-out user sees the sign-in screen; a parent lands on `/parent/home` and sees the code and a teen's name; an unlinked teen lands on join; a linked teen lands on the teen home with the 4-item nav. Update the existing `widget_test.dart`. You may split it into `test/app/` files.

**Done when:** tests are green and the app works on the emulator as before, now with bottom navigation. Commit `feat(router): role-based shells and pure redirect`.

---

## Step 9 — Localization (ru, kk, en)

The product languages are **Russian and Kazakh**. English is the developer and test language, and it matches the mockup copy.

1. `flutter pub add flutter_localizations --sdk=flutter` (and `intl`, which is already present). In `pubspec.yaml`, set `flutter: generate: true`.
2. `l10n.yaml`:
   ```yaml
   arb-dir: lib/l10n
   template-arb-file: app_en.arb
   output-localization-file: app_localizations.dart
   nullable-getter: false
   ```
   On this Flutter version the generated files land in `lib/l10n/` (there's no synthetic package). Import `package:tiyn_app/l10n/app_localizations.dart`. Commit the generated files (CI checks they're up to date).
3. Move **every** user-visible string into the ARB files, with ICU plurals or placeholders where needed (e.g. `connectedTo(names)`, `shareCodeMessage(code)`). That covers the sign-in, splash, join, parent code and shell screens, plus all error messages. Name keys by meaning, e.g. `signInContinueWithGoogle`, `joinCodeTooShort`, `errorNoConnection`.
4. Write `app_ru.arb` with natural Russian. Write `app_kk.arb` as a best-effort Kazakh draft, and add `"@@x-review": "kk strings need native-speaker review"` at the top. The backend's push copy has the same open issue.
5. `TiynApp`: `supportedLocales: [ru, kk, en]`, with the generated `localizationsDelegates`. Locale resolution: use the device locale if it's ru or kk; otherwise **Russian**. English is used only when explicitly forced (tests, dev). A user-chosen language setting is Phase 2. Don't build it.
6. Now write `core/network/error_messages.dart` (step 6.4) and use it from the screens.
7. Test helper `test/helpers/pump_app.dart`: `pumpApp(tester, {overrides, locale = const Locale('en')})`. Tests assert on English strings.
8. Add one test that pumps the sign-in screen in `kk` and in `ru` and checks that nothing overflows (no `RenderFlex overflowed` exceptions) at **360×640** with a text scale of **1.3**. Kazakh is often ~30% longer than English.

**Done when:** no string literal shown to users remains in `lib/features` or `lib/app` (check with `grep -rn "Text('" lib/features lib/app` and review). Commit `feat(l10n): ru/kk/en with generated localizations`.

---

## Step 10 — Money value type and formatting

The backend sends money as **integer minor units** (`150000` = 1 500 ₸) plus `"currency": "KZT"`. Doubles must never touch money.

`core/money/money.dart`:
```dart
@immutable
final class Money implements Comparable<Money> {
  const Money(this.minor, this.currency);
  const Money.kzt(this.minor) : currency = 'KZT';
  final int minor;
  final String currency;

  static const zero = Money.kzt(0);
  factory Money.fromJson(Object? amount, Object? currency); // validates int + 'KZT', else ApiException('invalid_response')
  Money operator +(Money other); Money operator -(Money other);  // throw ArgumentError on currency mismatch
  bool get isNegative; bool get isZero;
  static Money? parseTenge(String input); // user input: "10 000", "10000", "1 500,50" -> minor units; null if invalid
  // == / hashCode / compareTo
}
```

`core/money/money_format.dart`: `String formatMoney(Money m, {required String locale, bool signed = false})`
- Whole tenge when `minor % 100 == 0`, otherwise two decimals.
- Digit grouping from `NumberFormat.decimalPattern(locale)` for ru and kk. Normalise the grouping separator to U+00A0 (no-break space) so amounts never wrap.
- The suffix is ` ₸`.
- Negatives use U+2212 (`−300 ₸`). With `signed: true`, positives get `+` (`+1 500 ₸`), as in the task lists in the mockups.

`design/widgets/money_text.dart`: `MoneyText(money, {style, signed})` reads the locale from context.

**Tests** (table-driven): `0`, `100` (1 ₸), `150000`, `1000000`, `150050` (1 500,50 ₸), negative, signed positive, plus ru/kk/en grouping and `parseTenge` valid and invalid cases (empty, letters, negative, too many decimals, over `int` range).

Use `CoinBadge` "0 ₸" via `formatMoney(Money.zero)` on the teen placeholder.

**Done when:** tests are green. Commit `feat(core): Money type and ₸ formatting`.

---

## Step 11 — JSON models with freezed, design widgets, fonts

### 11.1 freezed + json_serializable
1. `flutter pub add freezed_annotation json_annotation`, `flutter pub add dev:build_runner dev:freezed dev:json_serializable`.
2. Convert `User` and `FamilyMember` to `@freezed` classes with `fromJson`. Use **freezed 3 syntax** (`@freezed abstract class User with _$User { … }`); check the installed version's README. `Role` uses `@JsonEnum(fieldRename: FieldRename.screamingSnake)` or `@JsonValue('PARENT')`, and drops the hand-written `wire` / `fromWire` if nothing else needs them (sign-in still sends `role.wire`; keep whatever makes that clean).
3. **Commit the generated `*.g.dart` / `*.freezed.dart` files.** CI checks they're current.
4. `build.yaml`: set json_serializable `checked: true`, `explicit_to_json: true`, `field_rename: none`.
5. Pattern for later phases (just follow it here): **one model file per API resource in `features/x/data/`, matching the field names in the backend's `docs/api.md` exactly.** Money fields are decoded with `Money.fromJson` through a `JsonConverter` or a custom `fromJson`.

### 11.2 Design widgets (`lib/design/widgets/`)
Only these, because they're used now or on nearly every mockup:
- `CoinBadge` (moved in step 5).
- `AppCard`: white, radius 16 by default (20 for large cards), padding 16.
- `BusyButton`: wraps `FilledButton` or `OutlinedButton` with a `busy` flag that shows the 22 px white spinner. Replace the copies in sign-in and join.
- `InfoBanner`: `Palette.infoWash` background, `Palette.infoText` text, radius 16, padding 16×14 (as in the join screen and the mockups).
- `MoneyText` (step 10).

`design/tokens.dart`: keep `Palette` as it is, and add `Space` (4, 8, 12, 16, 20, 24, 28, 32) and `Radii` (14 input, 16 card, 20 large card, 28 sheet). Use them in the moved screens where it's a mechanical swap. Don't redesign anything.

### 11.3 Fonts — bundle Rubik, no runtime fetching
`google_fonts` downloads fonts from Google at runtime by default. That leaves the first launch offline without the brand font, and it sends a request to Google from a children's app.
1. Download Rubik (static TTFs: 400, 500, 600, 700, plus the license file) into `assets/google_fonts/`, and declare the folder under `flutter: assets:`.
2. In `main()`: `GoogleFonts.config.allowRuntimeFetching = false;`
3. **Check that Rubik covers Kazakh Cyrillic** (`ә ғ қ ң ө ұ ү һ і`, and capitals). Render a test string on the emulator in kk. If glyphs fall back to another font, **stop and tell the user**; don't silently switch fonts.

**Done when:** `dart run build_runner build --delete-conflicting-outputs` produces no diff, tests are green, and the app shows Rubik with airplane mode on at first launch. Commit `feat: freezed models, design widgets, bundled Rubik`.

---

## Step 12 — CI (GitHub Actions)

The backend uses GitHub Actions (`janymSoul/tiyn`), and this repo will live next to it. Match the backend's style (`/Users/medettegistay/Projects/tiyn/.github/workflows/ci.yml`).

`.github/workflows/ci.yml`:
```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main]

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version-file: pubspec.yaml
          cache: true
      - run: flutter pub get
      - name: Format
        run: dart format --output=none --set-exit-if-changed lib test
      - name: Generated code is up to date
        run: |
          dart run build_runner build --delete-conflicting-outputs
          flutter gen-l10n
          git diff --exit-code
      - name: Analyze
        run: flutter analyze --fatal-infos
      - name: Test
        run: flutter test --coverage
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: coverage
          path: coverage/lcov.info
          if-no-files-found: ignore

  android:
    needs: checks
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: "17"
      - uses: subosito/flutter-action@v2
        with:
          flutter-version-file: pubspec.yaml
          cache: true
      - run: flutter pub get
      - name: Build staging APK
        run: flutter build apk --debug --flavor staging --dart-define-from-file=env/staging.json
      - uses: actions/upload-artifact@v4
        with:
          name: app-staging-debug
          path: build/app/outputs/flutter-apk/app-staging-debug.apk
          retention-days: 7
```
- If the Android Gradle Plugin needs a newer JDK than 17, use the version it asks for and say so in the commit message.
- Check the APK output path after a local build and fix the `path:` if it differs.
- **Not in this phase:** signing in CI, Firebase App Distribution and Play upload. They need accounts and keys the user hasn't created yet (see "Human tasks"). That's Phase 1.

You can't run GitHub Actions locally. Run every command from the workflow locally in the same order, and confirm each succeeds.

**Done when:** every step's command passes locally. Commit `ci: analyze, test, codegen check, staging APK`.

---

## Phase 0 definition of done

- [ ] 12 commits on `main`, each with analyze and test green; nothing pushed.
- [ ] `flutter analyze --fatal-infos`: 0 issues. `dart format --set-exit-if-changed`: clean. build_runner and gen-l10n produce no diff.
- [ ] All three flavors build. The release prod build warns about the debug-key fallback.
- [ ] `grep -r "features/" lib/core lib/design` returns nothing.
- [ ] No user-visible string literals outside the ARB files.
- [ ] No money stored as a `double` anywhere (`grep -rn "double" lib` and review).
- [ ] Tests cover: ApiClient, the redirect table, AuthController, FamilyController user-scoping, Money and its formatting, the widget flows from step 8, and the kk/ru overflow check.
- [ ] Behaviour matches today on the staging flavor (once the user has created the Android OAuth client): sign in, parent sees the code, teen joins, parent pulls to refresh and sees the teen.
- [ ] Final report to the user: what was done, any deviations from this plan and why, the Kazakh font result, and the open items below.

---

## Human tasks (for the user, not the agent)

These block Phase 1 (push, signed builds, distribution) and make sign-in work again after the package rename:

1. **GitHub repo** for the app (e.g. `janymSoul/tiyn_app`); add it as the remote and push.
2. **Firebase projects:** `tiyn-staging` (dev + staging) and `tiyn-prod`. Register the Android apps `kz.tiyn.app.dev` and `kz.tiyn.app` (staging shares the prod ID for the MVP). The Firebase project's name doesn't need to match the app ID; the registered **package name** must.
3. **Google OAuth Android clients** for each package, with the SHA-1 of: your debug key (`./gradlew signingReport`), the upload key (step 4 below), and later the **Play App Signing** key (shown in Play Console after the first upload). Add every client ID to the backend's `GOOGLE_CLIENT_IDS` and put the **Web** client ID in `env/*.json` as `GOOGLE_SERVER_CLIENT_ID`.
4. **Upload keystore:** `keytool -genkey -v -keystore upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`. Store it and its passwords in a password manager. **Never commit it.** Enable Play App Signing.
5. **Google Play Console** account ($25), the app created with ID `kz.tiyn.app`, and the internal testing track. The target audience includes under-13s, so read the **Families policy** before adding any analytics or crash-reporting SDK.

## Coming next (not part of this phase)

- **Phase 1 (teen loop):** Firebase Messaging + `PUT /devices`; push → route deep links; dashboard, task, proof (with image compression), goals, cash out; offline dashboard snapshot; session-ended screen; signed CI builds → Firebase App Distribution.
- **Backend gaps to open in `tiyn` in parallel:** an optional text part on the image proof; `expiresAt` on payouts; `seriesId` on tasks; `Idempotency-Key` on `POST /tasks`, `/task-series` and `/goals`; `DELETE /me`; `GET /app-config` (minimum app version).
