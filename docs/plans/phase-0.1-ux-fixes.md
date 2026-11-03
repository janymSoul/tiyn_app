# Phase 0.1: UX fixes — implementation plan

**Audience:** the coding agent that carries this out.
**Comes from:** the review of Phase 0 (the 12 commits ending `6d8090b`).
**Repos:**
- **Part A:** backend `/Users/medettegistay/Projects/tiyn` (Java, Spring Boot). Read its `AGENTS.md` first and follow it.
- **Part B:** app `/Users/medettegistay/Projects/tiyn_app` (Flutter, Android first).

The phase builds **no new product screens**. It fixes dead ends, the irreversible role mistake, the join-code input, misleading or technical messages, and small visual defects.

---

## 0. Rules (same as Phase 0, plus two)

1. Work in step order. One commit per step. Before each commit: app → `flutter analyze --fatal-infos` + `flutter test` + `dart format --set-exit-if-changed lib test`; backend → `./mvnw spotless:apply && ./mvnw verify` (needs Docker running).
2. **Do not push.** No remote changes. In the backend, work on a branch `feat/role-required` off `main`.
3. Commit messages are short and conventional-ish. **No `Co-Authored-By` trailer.**
4. Add packages with `flutter pub add`. Don't hand-write versions.
5. **Russian and Kazakh copy:** change only the strings named in this plan. **Don't** rename the tabs («На проверке», «Активность») or the role names («Подросток»). Those wording decisions belong to the native-speaker review. New strings get ru and kk versions. Kazakh stays marked as needing review.
6. Never log tokens, Google ID tokens, emails, names or join codes.
7. **Stop and ask** if a step needs a change not described here, or if the backend change (Part A) turns out to need more than the files listed.
8. **New:** for every widget you change, check a text scale of 1.3 at 360×640 in `ru` and `kk` (step B11 adds tests).
9. **New:** one fallback-to-Russian rule from Phase 0 stays. Don't add a language picker.

---

# Part A — Backend: `role_required` for new accounts

## Why

Today the app asks every user "I am a…" before sign-in, and the backend uses the answer **only for a brand-new account**. Returning users answer a question that does nothing. A new user who leaves the default can lock themselves into the wrong role forever; roles can't change, and there's no account deletion.

**New contract:** the client calls `POST /auth/google` **without** `role` first.
- The account exists → `200`, exactly as today.
- The account is new → `422 {"error":"role_required"}`, and **nothing is created**. The client then asks for the role and calls again with the **same `idToken`** plus `role`. Google ID tokens stay valid for about an hour, and the backend's JWKS check has no single-use rule, so resending the same token works.

A present but unknown role (`"ADMIN"`) is still `422 invalid_role`.

## A1. Code (`kz.tiyn.identity.account`)

1. `error/IdentityError.java`: add `ROLE_REQUIRED` (wire code `role_required`; `code()` already lower-cases).
2. `error/IdentityExceptionHandler.java`: map `ROLE_REQUIRED` to `HttpStatus.UNPROCESSABLE_ENTITY`, next to `INVALID_ROLE`.
3. `AccountService.parseRole`: when `raw` is `null` **or blank**, throw `ROLE_REQUIRED`. Any other unknown value still throws `INVALID_ROLE`.
4. Nothing else changes. The existing-account path already returns before `parseRole`, so a missing role for an existing account is already a `200`. Check this by reading `signInOnce`. Don't refactor it.
5. Make sure the new-account path throws **inside** the transaction before `users.insert`, so no row is written. It does today; keep it that way.

## A2. Tests (`src/test/java/kz/tiyn/identity/IdentityFlowTests.java`)

1. In `signInErrorsUseTheDocumentedCodes`, the case that sends `role = null` for a new subject must now expect `role_required` (still 422). Keep the `"ADMIN"` → `invalid_role` case.
2. New test: **new account, no role** → 422 `role_required`; then **the same token** with `"PARENT"` → 200, the user has role `PARENT`, and a `joinCode` is present. Because an existing account keeps its stored role and ignores the request's role, getting `PARENT` back with a fresh join code proves the first call created no account. Use the class's existing helpers (`signInRaw`, `tokenFor`, `uniqueSub`); don't add test infrastructure.
3. New test: **existing account, no role** → 200 with the stored role (sign in once with `"PARENT"`, then again without a role).
4. New test: **blank role** (`"  "`) for a new account → `role_required`.

## A3. Docs

`docs/api.md`, section `POST /auth/google`:
- `role` becomes "**optional**; required only when the account doesn't exist yet".
- Add the client flow: call without `role` → on `422 role_required` ask the user → call again with the same `idToken` and `role`.
- Add `422 role_required` to the error list.
- Update `docs/use-cases.md` UC-01 step 1 in one sentence the same way.

## A4. Done when

`./mvnw spotless:apply && ./mvnw verify` is green, including `ModularityTests`. There's one commit on `feat/role-required`: `feat(identity): role_required for new accounts without a role`.

> **For the user:** merge the PR, let CI publish the image, and run `deploy/staging/deploy.sh` **before** testing Part B against staging. Part B's tests use fakes, so Part B can be written in parallel.

---

# Part B — App

## B1. Staging shares the prod app ID (MVP decision)

**Decision (the user's, for the MVP):** the `staging` flavor uses `kz.tiyn.app`, the same ID as `prod`, with no suffix. `dev` keeps `kz.tiyn.app.dev`. The consequences are accepted: staging and prod can't be installed side by side, and staging builds must never be uploaded to Google Play. Only `prod` goes to Play, and only once a prod backend exists. Revisit this before the first public release.

1. Keep the uncommitted removal of `applicationIdSuffix = ".staging"` in `android/app/build.gradle.kts`, and commit it.
2. Commit the `GOOGLE_SERVER_CLIENT_ID` values already set in `env/dev.json` and `env/staging.json` (web client IDs aren't secret).
3. Update the flavor table in `README.md` (and in `docs/plans/phase-0-foundation.md` step 3, if it's quoted anywhere else) so staging shows `kz.tiyn.app`, with one line saying it's shared with prod for the MVP.
4. Commit: `build(android): staging shares the prod app id for the MVP`.

## B2. Two-step sign-in (needs the new backend contract)

### Target flow

**Step 1 — Welcome** (route `/sign-in`): the existing navy hero (coin, "tiyn", tagline). The bottom sheet holds only **"Continue with Google"** and a short line under it: «Войдите через аккаунт Google» / "Sign in with your Google account" (ru and kk; see the string table). **No role cards here.**

**Step 2 — Role** (same route; the sheet swaps its content with an `AnimatedSwitcher`). Shown **only** after the backend answers `role_required`:
- Title: "Who are you?" / «Кто вы?» / «Сіз кімсіз?»
- One line: "Google account: {email}" / «Аккаунт Google: {email}» / «Google аккаунты: {email}». The email comes from the Google account the user just picked, is shown locally only and is never logged or sent anywhere new. It helps a parent notice they picked the child's account, or the other way round.
- The two existing role cards. **Neither is selected at first.**
- The permanence note (the existing `signInRoleNote`), shown **above** the button in `Palette.warn` weight 500, not muted. This is the irreversible moment.
- A "Continue" button, **disabled until a role is picked**, busy while sending.
- A text button: "Use a different Google account" / «Другой аккаунт Google» / «Басқа Google аккаунты». It signs out of Google locally and goes back to step 1.

Returning users go: tap "Continue with Google" → pick an account → home. They never see the role step.

### Code

1. `features/auth/data/google_identity.dart`: `idToken()` becomes `Future<GoogleCredential> signIn()` returning `({String idToken, String email})`. Keep `signOut()`. Update `FakeGoogleIdentity` in `test/helpers/fakes.dart`.
2. `features/auth/data/auth_repository.dart`:
   ```dart
   sealed class SignInOutcome {}
   final class SignedIn extends SignInOutcome { SignedIn(this.user); final User user; }
   final class RoleRequired extends SignInOutcome {}

   Future<GoogleCredential> googleSignIn();
   Future<SignInOutcome> signIn({required String idToken, Role? role});
   ```
   - The body sends `role` **only when it isn't null**. Never send `"role": null`.
   - `ApiException` with `statusCode == 422 && code == 'role_required'` → `RoleRequired()`. Every other error is rethrown.
   - Remove `signInWithGoogle` / `signInWithIdToken`.
3. New `features/auth/application/sign_in_controller.dart` (`NotifierProvider.autoDispose`):
   ```dart
   sealed class SignInState {}
   final class Welcome extends SignInState { Welcome({this.error}); final Object? error; }
   final class Authenticating extends SignInState {}
   final class ChoosingRole extends SignInState {
     ChoosingRole({required this.credential, this.selected, this.sending = false, this.error});
     final GoogleCredential credential; final Role? selected; final bool sending; final Object? error;
   }
   ```
   Methods:
   - `continueWithGoogle()`: `Authenticating` → `googleSignIn()` → `signIn(idToken)`. `SignedIn` → `ref.read(authControllerProvider.notifier).signedIn(user)`. `RoleRequired` → `ChoosingRole(credential)`. **Google cancelled → `Welcome()` with no error.** Other errors → `Welcome(error: e)`.
   - `selectRole(Role)` (ignored while `sending`).
   - `confirmRole()`: `sending: true` → `signIn(idToken, role)` → `signedIn(user)`. `ApiException` `invalid_identity` (the ID token expired while the user was deciding) → Google sign-out locally → `Welcome(error: e)`, which shows «Вход истёк, войдите снова» (new string `signInExpired`). Other errors → stay on `ChoosingRole` with `error`, so the selection is kept.
   - `useAnotherAccount()`: Google sign-out locally → `Welcome()`.
4. `AuthController`: remove `signIn(Role)`; add `void signedIn(User user) => state = AsyncData(user);`. Auth no longer goes through `AsyncLoading` during sign-in, so the sign-in screen owns all its own busy and error UI. Keep the redirect rule that leaves `/sign-in` alone while auth is pending; it's harmless.
5. Rewrite `sign_in_screen.dart` to render from `SignInState`. Keep the hero, colors and sizes. The cards and button components stay; only their arrangement changes.

### Tests
- `test/features/auth/sign_in_controller_test.dart`: existing account → `signedIn` called and no role step; new account → `ChoosingRole` with the email; `confirmRole` sends `role` and the same `idToken`; the first call's body has **no `role` key**; cancelling → `Welcome` without error; `invalid_identity` on confirm → `Welcome` with error and Google signed out; a network error on confirm keeps `selected`; `useAnotherAccount` → `Welcome`.
- Widget tests: the Welcome sheet has no role cards; on the role step "Continue" is disabled until a card is tapped; the email is shown.
- Update `app_flow_test.dart` and the layout tests to the new screens.

Commit: `feat(auth): ask for a role only for new accounts`.

## B3. Escape hatches

1. **Join screen:** add a `TextButton` "Sign out" at the bottom of the scroll view (below the info banner). It calls `authControllerProvider.notifier.signOut()`. Below it, in `bodySmall` muted text: "Wrong account? Sign out and use another Google account." / «Не тот аккаунт? Выйди и войди через другой аккаунт Google.» / «Аккаунт қате ме? Шығып, басқа Google аккаунтымен кір.» (informal: the reader is a teen).
2. **Splash error:** under "Try again", add a `TextButton` "Sign out" (white text on navy). Show it only when a token exists, i.e. the error came after sign-in (auth error from `/me`, or family error). `SplashScreen` gets an optional `onSignOut`; the router passes it.
3. Tests: the sign-out button exists on both and calls sign-out.

Commit: `fix: sign-out escape on join and splash error`.

## B4. No fake balance; CoinBadge fits any amount

1. `TeenHomePlaceholder`: the `CoinBadge` shows the `₸` glyph (like sign-in), **not** `formatMoney(Money.zero)`. Showing "0 ₸" to a teen who has money is wrong data. The real balance arrives with the Phase 1 dashboard.
2. `CoinBadge`: wrap the text in `FittedBox(fit: BoxFit.scaleDown)` inside a `Padding` of `size * 0.14` so long amounts shrink to fit inside the circle. Add a widget test: `CoinBadge(size: 180, glyph: '1 234 567 ₸')` renders without overflow and the text stays inside the circle's bounds.

Commit: `fix(teen): no placeholder balance; coin badge fits long amounts`.

## B5. Join-code input

The code alphabet is fixed by the backend: `ABCDEFGHJKLMNPQRSTUVWXYZ23456789` (no I, O, 0 or 1), exactly 6 characters, case-insensitive.

1. New `features/family/presentation/join_code_formatter.dart` (`TextInputFormatter`), a pure function, unit tested:
   1. Upper-case the input.
   2. **Map Cyrillic look-alikes to Latin**: `А→A В→B С→C Е→E Н→H К→K М→M Р→P Т→T Х→X У→Y` (upper case; lower case is already upper-cased by step 1). Most phones in Kazakhstan type in the Russian layout, and these letters look identical.
   3. **Paste:** if the new text is more than one character longer than the old (a paste), search it for the **last** run of exactly 6 alphabet characters bounded by non-alphabet characters or the ends (`(?<![A-Z0-9])[A-HJ-NP-Z2-9]{6}(?![A-Z0-9])` on the upper-cased, mapped text). If found, the field becomes that code. For example, "Join me on Tiyn. My family code is SXVPUR" → `SXVPUR`, and «Мой семейный код: SXVPUR» → `SXVPUR`. If nothing is found, fall through to step 4.
   4. Drop every character outside the alphabet (spaces, dashes, I, O, 0, 1, other letters). Keep at most 6.
   5. Keep the cursor at the end.
2. Text field settings: `inputFormatters: [JoinCodeFormatter()]`, `autocorrect: false`, `enableSuggestions: false`, `keyboardType: TextInputType.visiblePassword`, `textCapitalization: TextCapitalization.characters`, `autofillHints: const []`. Remove `maxLength` and `counterText` (the formatter limits length).
3. **"Connect" is disabled until there are 6 characters.** When the 6th character arrives (typed or pasted), **submit automatically** once. Don't auto-submit again for the same text after an error; the user edits or taps the button.
4. Remove the "too short" check and the `joinCodeTooShort` string (it can't happen now).
5. Unit tests for the formatter: plain typing; lower case; Cyrillic `СХВРУР`-style input → `CXBPYP`; spaces and dashes (`SX-VP UR`); I, O, 0 and 1 dropped; English and Russian share messages pasted; a paste with no code; more than 6 characters typed.
6. Widget test: pasting the English share message fills `SXVPUR` and triggers exactly one join call.

Commit: `feat(family): forgiving join-code input with paste and auto-submit`.

## B6. Copy fixes (only these)

| Key | en | ru | kk |
|---|---|---|---|
| `joinSubtitle` | Ask your mom or dad for the 6-character code from their Tiyn app. | Попроси маму или папу код из 6 символов из их приложения Tiyn. | (unchanged — «6 таңбалы» is already right) |
| `joinTitle` | (unchanged) | **Введи** код родителя | (unchanged — already informal) |

Commit: `fix(l10n): join copy — 6-character code, informal title`.

## B7. Errors in plain words

1. Delete `parentTeensLoadFailedCode`. The parent screen shows `apiErrorMessage(l10n, e)` followed by a new short line `pullToRetry` ("Pull down to try again." / «Потяните вниз, чтобы повторить.» / «Қайталау үшін төмен тартыңыз.»).
2. `errorUnknown` loses its `{code}` placeholder: "Something went wrong. Try again." / «Что-то пошло не так. Попробуйте ещё раз.» / «Бірдеңе дұрыс болмады. Қайталап көріңіз.» In `kDebugMode` only, `apiErrorMessage` adds ` (code)` at the end so developers still see it.
3. `apiErrorMessage` for a non-`ApiException` returns the same generic `errorUnknown`.
4. `JoinTeenScreen._join`: catch non-`ApiException` errors too and show `errorUnknown`. Today they vanish silently.
5. Tests: update the message tests; add one that asserts no `_`-style code appears in release mode. Use a flag the function takes, defaulting to `kDebugMode`, so the test can pass `false`.

Commit: `fix: user-facing errors without internal codes`.

## B8. Parent sees a newly linked teen without pulling

1. Make `ParentCodeScreen` a `ConsumerStatefulWidget`. Hold an `AppLifecycleListener(onResume: …)` that calls `familyControllerProvider.notifier.refresh()`, and dispose it in `dispose`.
2. `FamilyController.refresh()` keeps the current list visible while refreshing (no jump to the spinner). It already assigns the guarded result directly; keep that, and add a test that a failed background refresh **keeps the previous data** and doesn't show the error card when data was already there. If `AsyncValue.guard` replaces the data with an error, use `AsyncValue.guard` and then, on error with previous data, keep `state` as it was and surface nothing.
3. Test: simulate a resume and verify one refetch.

Commit: `feat(family): refresh linked teens when the app resumes`.

## B9. Native launch screen matches the splash

1. Add `android/app/src/main/res/values/colors.xml` with `<color name="launch_navy">#10213A</color>`.
2. `drawable/launch_background.xml` and `drawable-v21/launch_background.xml`: replace `@android:color/white` with `@color/launch_navy`.
3. `values/styles.xml` and `values-night/styles.xml`: `NormalTheme` `windowBackground` → `@color/launch_navy`, so there's no white frame between the native screen and Flutter's first frame.
4. Add `values-v31/styles.xml` (and `values-night-v31/`), copying `LaunchTheme` with `<item name="android:windowSplashScreenBackground">@color/launch_navy</item>`. Android 12+ ignores `windowBackground` for the system splash.
5. Build `dev` and check by eye on the emulator (API 34+) and, if available, an API 30 image: no white flash on cold start.

Commit: `fix(android): navy launch screen, no white flash`.

## B10. Small UI fixes

1. **Role cards** (`_RoleCard`): wrap in `Material(color: Colors.white, shape: RoundedRectangleBorder(...with the border...))` + `InkWell`, so the ripple shows. Use `Semantics(inMutuallyExclusiveGroup: true, checked: selected, button: true, label: '$title. $subtitle')`, and wrap the visual texts in `ExcludeSemantics` so the screen reader doesn't read them twice.
2. **Google logo:** replace the hand-drawn "G" letter in `_GoogleG` with the logo file `assets/images/google_g.png` (already in place: 225×225, white background, no transparency). Declare `assets/images/` under `flutter: assets:` in `pubspec.yaml`. Keep `_GoogleG`'s 24 px white circle, and inside it render `Image.asset('assets/images/google_g.png', width: 18, height: 18, filterQuality: FilterQuality.medium)`, centred. The image's white background blends into the circle. Wrap it in `ExcludeSemantics`, because the button label already says "Continue with Google". Don't draw or recolour the logo.
3. **Goals tab icon:** `Icons.track_changes` (the mockup's target), with `selectedIcon` versions for all tabs where a filled variant exists (`Icons.home`, `Icons.receipt_long`).

Commit: `fix(ui): role card ripple and semantics, tab icons`.

## B11. Layout tests for every screen

Extend the overflow test (360×640, text scale 1.3, `ru` and `kk`) to cover: sign-in Welcome, sign-in role step (with a long email such as `aigerim.nurlanovna.example@gmail.com`), the join screen with an error shown, the parent home with 3 teens and with the error card, the splash error with sign-out, and both shells. Fix any overflow you find by wrapping or scrolling, never by shrinking font sizes.

Commit: `test: overflow checks for all phase-0 screens in ru/kk at 1.3x`.

---

## Definition of done

- [ ] Backend: one commit on `feat/role-required`; `./mvnw verify` green; `docs/api.md` updated.
- [ ] App: 11 commits; analyze, format and tests green; codegen and l10n produce no diff.
- [ ] Nobody can create an account without actively choosing a role, and returning users never see the role question.
- [ ] Every screen reachable while signed in has a way to sign out.
- [ ] No placeholder money amount shown anywhere.
- [ ] Pasting the share message (en or ru) into the join field connects in one step; Cyrillic look-alike letters work.
- [ ] No internal error code visible in a release build.
- [ ] No white flash on cold start (checked by eye).
- [ ] Final report: what was done, deviations and why, which human prerequisites are still open (staging deploy of Part A), and a manual check on staging of: new teen sign-up → role step → join with a pasted code; returning parent → straight to home.

## Out of scope (don't do)

- Renaming tabs or roles in ru/kk (left for native review).
- Session-ended screen, push notifications, app links for the join code (Phase 1).
- Real teen balance or dashboard (Phase 1).
- Display-name entry at sign-up.
- Moving sign-out into Settings.
