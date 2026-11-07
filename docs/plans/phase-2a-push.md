# Phase 2a: push notifications — implementation plan

**Audience:** the coding agent that carries this out, after the user has signed off Part 1.
**Repo:** `/Users/medettegistay/Projects/tiyn_app`, branch `feat/push` off `main`. **Backend (read-only):** `/Users/medettegistay/Projects/tiyn`, contract in `docs/api.md` §"Push notifications". Do **not** edit the backend in this phase.

**Goal:** a push reaches the right phone, shows up as a system notification when the app is closed, opens the right screen when tapped, and updates the screen on its own when the app is open. A signed-out user never gets pushes.

**What the backend already does** (verified in `notification/push`): `PUT /devices` is an upsert by token, and it **reassigns the token to the caller**, so a phone that changes hands is safe once the new user registers. `DELETE /devices` only removes a token **owned by the caller**, so it needs the old user's JWT. Every push has a localised `notification` plus `data` (`type`, and `taskId` or `payoutId`). Priority is `NORMAL` except `PAYOUT_REQUESTED`.

---

# Part 1 — Design (the user signs this off)

## 1.1 Decisions

**Decided by the user** (taken as given, not reopened):

| # | Decision |
|---|---|
| A1 | Packages: `firebase_core` + `firebase_messaging` only. No `flutter_local_notifications`, no `onBackgroundMessage`. The system shows pushes that carry a `notification` while the app is in the background. |
| A2 | One `android/app/google-services.json` with both clients (`kz.tiyn.app`, `kz.tiyn.app.dev`). Gitignored (public repo). CI writes it from the base64 secret `GOOGLE_SERVICES_JSON`. One README paragraph for local setup. `Firebase.initializeApp()` reads the native config: no `firebase_options.dart`. |
| A3 | `firebase_messaging` sits behind a small `PushMessaging` interface; only `core/push` imports it. |
| A4 | Registration lifecycle, sign-out, and the "never the previous user's pushes" rule (1.3). |
| A5 | Permission is asked in context, never at launch: parent after a task is created, teen as a soft card on home. Our explanation first, then the system dialog. One dismissible card after a denial. No nagging. |
| A6 | Android presentation: one channel `tiyn`, a monochrome small icon, brand-navy colour. |
| A7 | Foreground: one in-app banner (no stacking) + provider refresh by type. |
| A8 | Taps go through one pure function `(type, data, role) -> location`; cold start holds the link until auth resolves. |
| A9 | The FCM token is logged in the dev flavor only. |
| A10 | Back from a deep-linked parent review lands on the **To check** list. With the shell, `go(/parent/review/:id)` builds the stack `To check list → review`, which is the natural place for that task. The teen's task and milestone screens sit under `/teen/home`, so back does reach home there. (This refines A8's "role home" for the parent only.) |

**Choices I made that you can change.** If you say nothing, the default applies.

| # | Question | Default |
|---|---|---|
| D1 | **Opening the app's notification settings.** Neither Firebase package can do it, and A1 says no other package. | A 10-line native method channel in `MainActivity` (`ACTION_APP_NOTIFICATION_SETTINGS`), behind a `NotificationSettingsOpener` interface so it can be faked. Alternative: `flutter pub add app_settings` (less code, one more dependency). |
| D2 | **Channel creation without a plugin.** Dart cannot create a channel without `flutter_local_notifications`. | Created natively in `MainActivity.onCreate` on every launch (re-creating with the same id refreshes the localised name). The name comes from Android resources (`values`, `values-ru`, `values-kk`). If a user never opened the app after install, FCM falls back to its own channel, but a user who can receive a push has signed in, so has launched it. |
| D3 | *(moved to A10, decided)* | |
| D4 | **Where the prompt flags live** (`explained`, `deniedCardDismissed`, last registration). No `shared_preferences` in the app. | `flutter_secure_storage` (already a dependency), keys namespaced by user id. The flags are per user: on a shared phone a second account is a new person and gets its own one-time prompt. Sign-out clears the registration record but **not** the prompt flags. |
| D5 | **Sign-out when the phone is offline.** DELETE fails, and `deleteToken()` may fail too, so the old token stays alive. Nothing can retry DELETE later, because it needs the old JWT. | **Added to A4:** a `pendingTokenDelete` marker is written before sign-out and cleared when `deleteToken()` succeeds. It is retried at app start and on resume, before any new registration. Once the FCM token is dead the server prunes its row (api.md: dead tokens are removed). |
| D6 | **Firebase cannot start** (a `google-services.json` that is missing at runtime, or a phone without Google Play services, such as a Huawei). | The app starts anyway. `initPush()` catches the failure and binds `UnavailablePushMessaging` (everything is a no-op). Push is an enhancement here, never a gate. **It can come on later:** while push is unavailable, every app resume retries `initPush()` once, so a phone that installs or updates Google Play services starts working without reinstalling the app. A phone that never has Play services (some Huawei models) never gets push. |
| D7 | **Notification small icon art.** Android needs a flat white shape on transparent. The launcher icon is still the Flutter default, so the real brand mark is the in-app coin (`CoinBadge`: gold disc, navy ₸). A web search found nothing closer: the stock Material "toll" glyph is two overlapping rings, not our coin. | A hand-drawn vector `ic_stat_tiyn.xml`: a solid coin disc with the **₸ knocked out** (even-odd path, 24 dp viewport). It reads as the same coin at 24 px. Replace the file when design provides a real one. |
| D8 | **Banner when there is no session** (splash, sign-in). | No banner and no refresh: a push cannot be for this phone any more. |
| D9 | **The permission flag when the teen taps "Not now".** | Counts as "explained". No system dialog, no denied card (nothing was denied), never asked again. That is the "no nagging" reading of A5. |

## 1.2 How it fits together

```
core/push/                         (the only place that imports firebase_*)
  push_messaging.dart              interface + PushMessage, PushPermission
  firebase_push_messaging.dart     real implementation
  unavailable_push_messaging.dart  no-op (D6)
  push_payload.dart                data map -> PushPayload{type, taskId, payoutId}, tolerant
  push_type.dart                   enum PushType with wire names; unknown -> null

features/push/
  data/       device_repository.dart (PUT/DELETE /devices), push_store.dart (secure storage, D4)
  application/
    device_registration.dart       lifecycle + sign-out cleanup (1.3)
    push_location.dart             PURE (type, data, role) -> location
    push_refresh.dart              PURE type -> refresh targets, plus the applier
    push_link_coordinator.dart     opened/initial messages -> pending link -> router
    push_permission.dart           status + prompt state machine (1.4)
  presentation/ push_banner.dart, notify_prompt_sheet.dart, notify_cards.dart
```
`features/push` may import `features/auth` (foundational) and `features/tasks`, `features/family`, `features/teen` **application** providers only to refresh them. `core/` imports nothing from `features/`.

**Auth ↔ push seam.** `AuthController.signOut` must start the device cleanup *before* it clears the JWT. `AuthController` already imports `app/providers.dart`, so the registration object is exposed there as `deviceRegistrationProvider` and `AuthController` calls it. No new abstraction layer. `features/auth` does not import `features/push`.

**Tests never touch Firebase.** `pushMessagingProvider` throws `UnimplementedError` unless overridden (the same pattern as `appConfigProvider`); `main` overrides it with the real or the no-op implementation, and `pumpApp` overrides it with a `FakePushMessaging`. A test (`push_imports_test`) fails if any file outside `core/push` imports `firebase_*`.

## 1.3 Registration lifecycle and sign-out

**Register** (`DeviceRegistration`, one single-flight `sync()`):
1. Runs when `currentUserIdProvider` becomes non-null, on `onTokenRefresh`, and on app resume.
2. `token = await push.token()`. A `null` token skips quietly.
3. `locale = appLocale` (`kk` → `"kk"`, anything else → `"ru"`; this reuses the rule in `TiynApp._resolve`, moved to `core/l10n/app_locale.dart`, so there is one rule).
4. If `{userId, token, locale}` equals the stored record, stop. Otherwise `PUT /devices {token, platform:"ANDROID", locale}`, and **only on success** store the record. After the await, check that the user is still the same one; if not, drop the result.
5. Failure → log the error class (never the token), keep the old record, and the next resume retries. It never reaches the UI. A 401 goes through the normal expired-session path.
6. Registration does not depend on permission (A4): it runs when the permission is denied.
7. Dev flavor only (`flavor == dev && kDebugMode`): `debugPrint` the token. This is an explicit, single exception to the "never log tokens" rule from Phase 0, guarded in one place and covered by a test.

**Sign-out** (must stay instant, see `c5650c8`; `AuthController.signOut` is `await repo.signOut(); state = null`, and that does not change):
1. In `signOut()`, before clearing the token, `deviceRegistration.beginSignOut()` reads the JWT (a local read) and writes `pendingTokenDelete`.
2. It then starts, **not awaited**, a detached task: `DELETE /devices` with an **explicit** bearer, 3 s timeout, errors swallowed; then `deleteToken()` (own timeout), regardless of the DELETE outcome; then, on success, it clears `pendingTokenDelete` and the stored registration.
3. A listener on `currentUserIdProvider` (non-null → null) covers every path that ends a session without `signOut()` (expired session, `/me` 401): no JWT is available, so it skips DELETE and does only `deleteToken()` plus the stored-registration cleanup.

Two `ApiClient` changes this needs (both small, both tested):
- `delete(..., authToken:)`. The interceptor reads the JWT from storage at request time, so a DELETE sent next to `tokens.clear()` would race and lose its header. The explicit token wins.
- That request must **not** call `onUnauthorized`. A 401 on a late DELETE would otherwise run `_onSessionExpired` and clear the token of a user who has signed in since.

## 1.4 Permission flow (Android 13+; older Android reports `granted` and nothing is asked)

Android 12 and older already allow notifications at install, so those phones need no prompt. From Android 13 notifications are **off until the app asks**, and nothing can grant them at install time. Asking right at first launch is possible, but we ask in context (A5): a prompt with a reason converts better and a denial at launch is permanent after the second time. Creating the channel (D2) does not trigger the dialog for an app that targets Android 13+; the P4 device check confirms it on a clean install.

```
status: granted | denied | notDetermined        (re-read on resume)
per user: explained (bool), deniedCardDismissed (bool)
```
- **Parent:** after a task or milestone is created and `status == notDetermined && !explained`, the screen the form returns to shows a bottom sheet: "Get notified when <name> sends proof" → **Turn on** (system dialog) / **Not now**. This triggers on the first create *after the app learns it was never asked*, so a parent who already has tasks is covered too.
- **Teen:** on home, `status == notDetermined && !explained` shows a soft card "Get notified about new tasks and money" → **Turn on** / **Not now**. Linking is when the teen first reaches home.
- Both set `explained` as soon as they are shown and answered (D9).
- **Denied:** if the system dialog is answered "Don't allow" (`status == denied` and `explained`), home shows **one** card "Notifications are off · Open settings" → opens the app's notification settings (D1). **Dismiss** sets `deniedCardDismissed` and the card never returns. If the user turns them on in settings, the next resume reads `granted` and the card goes away on its own.
- The foreground banner works whatever the permission is. The app still works with it denied.

## 1.5 Tap routing (A8)

One pure function in `push_location.dart`:

| Type | Role | Location |
|---|---|---|
| `TASK_SUBMITTED` | parent | `Routes.parentReviewTask(taskId)` |
| `TASK_ASSIGNED`, `TASK_APPROVED`, `TASK_REJECTED`, `TASK_REDO_REQUESTED`, `TASK_CANCELLED`, `TASK_EXPIRED`, `TASK_EXPIRED_WITH_PENALTY` | teen | `Routes.teenTask(taskId)` |
| `PENALTY_APPLIED`, `PAYOUT_*` | either | role home (Phase 2b remaps the `PAYOUT_*`) |
| `FAMILY_LINKED_*`, `FAMILY_UNLINKED` | either | role home |
| unknown type, missing or blank id, a type meant for the other role | either | role home. Never throws. |

**A milestone id arrives as `taskId`.** Today `TeenTaskScreen` shows a milestone as an ordinary task, including a "Submit proof" button that skips the all-steps-approved rule. Fix in the routing step: when the loaded task has `kind == milestone`, the screen replaces itself (`pushReplacement`) with `Routes.teenMilestone(id)`. Back then goes to home. `TeenMilestoneScreen` reads the dashboard's recent window, so a milestone older than the window shows its existing "task changed" card; acceptable, it is not reachable from a fresh push.

**Cold start and warm taps share one path.** `getInitialMessage()` and `onMessageOpenedApp` write a `PushLink` into `pendingPushLinkProvider`. `PushLinkCoordinator` applies it when auth has resolved (teen: and the family has loaded). No session → dropped. A teen with no family members → role home (the redirect then sends them to join). The link is applied once, then cleared. The router redirect still decides what is allowed.

## 1.6 Foreground (A7)

`PushBannerHost` wraps the app in `MaterialApp.builder`, above the router: a single slot, a new push replaces the current banner, auto-dismiss after 5 s, swipe or tap-away to dismiss, an **Open** action that goes through the same routing function, and a live-region semantics label. It holds the title and body of the push, so long text wraps (max 2 + 3 lines) and the banner is scrollable-safe at 1.3× text. It does not use `ScaffoldMessenger` (there are several nested `Scaffold`s).

`push_refresh.dart` maps type to the providers to refresh, **using the silent `refresh()` methods, not `ref.invalidate`**. Reason: `resolveRedirect` sends a teen to `/splash` whenever `family.isLoading`, and an invalidated provider reports loading. The silent methods keep the old data on screen and ignore failures.

| Push | Refresh |
|---|---|
| teen `TASK_*` | dashboard, task detail `taskId` |
| teen `PENALTY_APPLIED`, `PAYOUT_*` | dashboard |
| parent `TASK_SUBMITTED` | submitted list, assigned list, that teen's list, task detail |
| `FAMILY_*` | family, then the role's lists |
| unknown | the role's primary lists (never nothing, never throws) |

`RefreshOnForeground` stays: a push is a nudge, it can be late or lost, and refetch-on-resume is the safety net. Only its doc comment ("there is no push in Phase 1") changes.

## 1.7 Rules for this phase
- No new user-visible strings outside the ARB files; ru, kk and en, new kk strings get the existing `@@x-review` treatment.
- Never log: tokens, the push title or body (they contain names and amounts), payload values. The one exception is the dev token log (1.3).
- Every new widget passes 360×640 at 1.3× text in ru and kk with no overflow.
- Nothing outside `core/push` imports `firebase_*` (enforced by a test).

---

# Part 2 — Steps

Rules are the same as Phase 0, 0.1 and 1: one commit per step, **analyze (`--fatal-infos`), `dart format`, all tests, codegen and l10n clean before each commit**, no push, **no Co-Authored-By**, add packages only with `flutter pub add`, and stop and ask if a step needs a backend change or an Android Gradle / AGP version change.

## P0. This plan
Commit: `docs: phase-2a push plan`. Stop for review.

## P1. Firebase setup and CI secret
- `flutter pub add firebase_core firebase_messaging`.
- Add the `com.google.gms.google-services` Gradle plugin (`settings.gradle.kts` plugin block, `app/build.gradle.kts`). **First task: check that it builds with the project's Android Gradle Plugin (AGP) 9.1.0**, the Android build tool already pinned in `settings.gradle.kts`. AGP 9 removed some interfaces third-party plugins relied on, and I could not confirm google-services' AGP 9 support from the docs, so use its newest release. If it only works with an AGP or Gradle change or an opt-out flag, **stop and ask** (Phase 0 rule 8).
- `.gitignore`: `android/app/google-services.json`.
- `core/push/` gets `initPush()` (the `Firebase.initializeApp()` call with the D6 fallback); `main()` becomes async and calls it. `pushMessagingProvider` lands in P2.
- CI: before "Build staging APK", a step that writes `android/app/google-services.json` from `GOOGLE_SERVICES_JSON` (`base64 -d`). Written so it also applies cleanly on top of the unmerged `ci/android-on-demand`.
- README: one paragraph in the setup section ("Push: get `google-services.json` from the Firebase console (both Android apps in one project), put it in `android/app/`; CI uses the `GOOGLE_SERVICES_JSON` secret").

**Human tasks before this step can be verified:** the Firebase project `tiyn-notification` exists and the staging service account belongs to it (checked: its `project_id` is `tiyn-notification`). Still open: (1) the project has only the `kz.tiyn.app` Android app. **Add a second Android app `kz.tiyn.app.dev`** in the Firebase console and download the new `google-services.json`, which then holds both clients. Without it the `dev` flavor fails to build ("No matching client found for package name"). (2) The client file is not in Downloads yet; the only Firebase file there is the **service-account key**, which is a server secret and must never go in this repo or the app. (3) The `GOOGLE_SERVICES_JSON` secret (base64 of the client file).
**Check:** `flutter build apk --debug --flavor staging` and `--flavor dev` both build locally and in CI, and the app starts with and without the file's presence at runtime.
Commit: `build: firebase for android, google-services from a CI secret`.

## P2. PushMessaging wrapper and fake
`push_messaging.dart` (token, `onTokenRefresh`, `deleteToken`, `requestPermission`, `permissionStatus`, `onForegroundMessage`, `onOpenedMessage`, `initialMessage`), `firebase_push_messaging.dart`, `unavailable_push_messaging.dart`, `push_payload.dart`, `push_type.dart`, `pushMessagingProvider`, `test/helpers/fake_push_messaging.dart`, and `pumpApp` / `parent_harness` overrides so the existing suite stays green.
Tests: payload parsing (all types, unknown, missing, blank, extra keys); the fake behaves like the contract; `push_imports_test` (no `firebase_*` import outside `core/push`).
Commit: `feat(push): PushMessaging interface with Firebase and fake implementations`.

## P3. Registration lifecycle and sign-out
`device_repository`, `push_store`, `device_registration`, `core/l10n/app_locale.dart`, the two `ApiClient` changes, the `AuthController` hook, `deviceRegistrationProvider`.
Tests: PUT after sign-in; PUT on token refresh; **no** PUT when nothing changed; PUT when the locale changes; PUT when only the user changes; a failed PUT is retried on the next resume and never surfaces; a registration result for a user who has signed out is dropped; registers with permission denied; **sign-out returns at once while DELETE hangs**; `deleteToken` is called when DELETE fails, times out, or the session already expired; the stored registration is cleared; `pendingTokenDelete` is retried at start when `deleteToken` failed (offline); DELETE carries the explicit bearer; a 401 on that DELETE does not clear a new session; the token is logged in dev only.
Commit: `feat(push): device registration and sign-out cleanup`.

## P4. Channel, icon and manifest
Manifest: `POST_NOTIFICATIONS`; meta-data `default_notification_channel_id` (`tiyn`), `default_notification_icon`, `default_notification_color`. `MainActivity` creates the channel (importance high) on launch. `strings.xml` for `values`, `values-ru`, `values-kk`; `ic_stat_tiyn.xml`; `notification_navy` in `colors.xml`.
Tests: a Dart test over the Android resources (the three meta-data entries, the permission, `notification_navy` equals `Palette.navy` as the launch colour already does, the channel name present in all three languages, the channel id the same in the manifest and in Kotlin). Native behaviour is checked on a device: a clean install on Android 13+ shows **no** permission dialog at launch, `adb shell dumpsys notification` shows channel `tiyn`, and a console test push shows the coin icon, not a grey square.
Commit: `feat(push): notification channel, icon and colour`.

## P5. Foreground banner and provider refresh
`push_refresh.dart`, `push_banner.dart`, `PushBannerHost` in `app.dart`, strings (Open, Dismiss, semantics).
Tests: the banner shows title and body; a second push replaces the first (never two); auto-dismiss (fake clock); Open navigates; no banner without a session; each refresh row of the table calls the right silent refresh and **does not set the family loading**; unknown type still refreshes; the teen home balance updates with no pull-to-refresh when an `APPROVED` push arrives.
Commit: `feat(push): foreground banner and refresh by push type`.

## P6. Tap routing and cold start
`push_location.dart`, `pendingPushLinkProvider`, `PushLinkCoordinator`, the milestone replace in `TeenTaskScreen`.
Tests: **every `PushType`** in the right role, in the wrong role, with a missing id, with a blank id; unknown type; the pure function never throws on garbage; **a cold-start link goes through splash**, is applied once auth resolves, and is dropped with no session; a warm tap with the app open; a teen with no family goes to join; a milestone id opened as a task lands on the milestone screen and back reaches home; back from a parent review goes to the To check list (D3).
Commit: `feat(push): tap routing and cold-start deep links`.

## P7. Permission flow and cards
`push_permission.dart`, the prompt store flags, `notify_prompt_sheet`, `notify_cards`, `NotificationSettingsOpener` (D1), hooks on the screen after create (parent), teen home and parent home. Strings in ru, kk and en.
Tests: the parent sheet appears after a create when `notDetermined`, once; not when granted; not after `explained`; Turn on requests the permission; the teen card shows on home once and "Not now" is remembered; a denial shows the settings card once, dismissal is remembered across a restart, it never returns; the card disappears when the status becomes `granted` on resume; flags are per user; nothing is shown on older Android (`granted`).
Commit: `feat(push): in-context notification permission`.

## P8. Hardening
Layout tests (extend `test/app/layout_test.dart`) for the banner, the parent sheet and both cards in ru and kk at 360×640 and 1.3×. Semantics for the banner (live region), the cards and the sheet actions. The routing-table test confirms it covers every `PushType` (exhaustive switch plus a test over `PushType.values`). Update the `RefreshOnForeground` doc comment. Fix findings by wrapping or scrolling, never by shrinking fonts.
Commit: `test: layout and semantics for push UI`.

---

# Part 3 — Backend requests

None blocks this phase. Each has a fallback.

| # | Request | Why | Fallback used now |
|---|---|---|---|
| B1 | `AndroidConfig` priority `HIGH` for `TASK_SUBMITTED` (and ideally `TASK_ASSIGNED`). Today only `PAYOUT_REQUESTED` is high. | A normal-priority push to a locked, idle phone can be held back by Doze. The "parent's locked phone shows the push" check can be slow or flaky because of this. | Accept the delay; test with the phone awake and recently used. |
| B2 | Confirm in `docs/api.md` that for a **milestone** the `taskId` in `data` is the milestone's id. | The routing relies on it (1.5). | Verify on staging in the device check; the milestone replace handles either shape that still resolves to a milestone id. |
| B3 | (Operations, not code) The staging backend's FCM service account must be from the same Firebase project as `google-services.json`. | A mismatch means no push ever arrives, with no error on the phone. | None; checked in P1. |

Not requested: an Android channel id and a `click_action` (the manifest default and the plugin's tap handling cover both); English push copy (api.md gap 6; the app sends `ru` for English devices, by decision).

---

## Definition of done
- [ ] The plan commit plus 8 step commits; analyze, format and all tests green; codegen and l10n produce no diff.
- [ ] CI green with the `GOOGLE_SERVICES_JSON` secret (staging APK builds).
- [ ] Every test named in the steps exists. In particular: registration (PUT after sign-in, on refresh, none when unchanged, on locale change); sign-out instant with a hanging DELETE and `deleteToken` always called; the full routing table, unknown type, missing id, wrong role; cold start through splash; the foreground banner shows and refreshes; the permission card shows once and dismissal is remembered.
- [ ] Real-device check on staging with two phones, each written up in the final report with what was seen:
  1. The teen submits → the parent's locked phone shows the push → tap opens that review.
  2. The parent approves while the teen has the app open → the banner shows and the balance updates with no pull-to-refresh.
  3. The parent signs out → a later push for that parent does not arrive.
  4. Deny the permission → the app still works and the card shows once.
  Plus, since the plan depends on them: a milestone push (B2), the coin icon on the notification (not a grey square), and a cold-start tap.

## Out of scope (don't do)
Payout screens, wallet history, iOS/APNs (the `ios/` folder is left alone), notification preferences or settings screens, app-icon badges, data-only or scheduled local notifications, `flutter_local_notifications`, `onBackgroundMessage`, any backend change. A backend gap goes in Part 3 with a fallback; it is not worked around silently.
