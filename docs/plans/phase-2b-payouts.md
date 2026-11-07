# Phase 2b: payouts — implementation plan

**Audience:** the coding agent that carries this out, after the user has signed off Part 1.
**Repo:** `/Users/medettegistay/Projects/tiyn_app`, branch `feat/payouts` off `main` (which already has Phase 2a, PR #2). **Backend (read-only):** `/Users/medettegistay/Projects/tiyn`. Contract: `docs/api.md` §"Payouts" and §"Teen home screen" (`openPayout`, with `expiresAt`). Product rules: `docs/use-cases.md` UC-08 and UC-09. Trust model: `docs/modules.md` §"Ledger & Wallet". Do **not** edit the backend in this phase.

**Goal:** a teen asks a linked parent for cash, the parent gets a high-priority push, opens a bank app (or the fallback), sends the money, comes back, confirms, and the teen's balance and home update on their own. Either side can also end the request: the teen cancels, the parent declines.

**What the backend already does** (read from `ledger/wallet`, not only from api.md):
- A request debits nothing. It lowers `availableAmount` at once, so **the teen's coin drops by the requested amount while the request is open**. The home card has to say the money is held, or it looks like a loss.
- `fulfil` is the only debit. It checks `amount <= balance − locked` under the wallet lock and fails with 422 `insufficient_funds` otherwise. That check ignores the request itself, so a penalty **or** a goal saving made after the request can break it.
- `fulfil` on a payout that is already `FULFILLED` returns it unchanged and writes no second debit (`wasOpen`). Retrying "I sent it" after a timeout is safe without a key. On a `CANCELLED` payout it is 409 `invalid_transition`.
- `fulfil`, `decline` and `cancel` need no `Idempotency-Key`; only `POST /payouts` does.
- The payout list has no names, only `teenId` / `parentId`. Names come from `GET /family`, which both roles already load.

---

# Part 1 — Design (the user signs this off)

## 1.1 Decisions

**Decided by the user** (taken as given, not reopened):

| # | Decision |
|---|---|
| A1 | The client validates amount against `availableAmount` and the minimum, but the server's 422 is the truth. |
| A2 | Parent choice: no step with one linked parent, a picker with several. |
| A3 | `Idempotency-Key` is generated once per form and reused on retry (Phase 0 §6.2). |
| A4 | Clear copy for `payout_already_open`, `insufficient_funds`, `amount_too_small`. A negative balance (penalty debt) explains why the button is disabled. |
| A5 | The teen's home shows `openPayout`: amount, parent, time until expiry from `expiresAt`. Cancel sits behind a confirmation. |
| A6 | The parent gets requests by the `PAYOUT_REQUESTED` push and by `GET /payouts?state=REQUESTED`. |
| A7 | Fulfil goes through a `BankLauncher` interface with a fake for tests. **Several banks (Kaspi, Freedom, Forte, others as verified)**, each a registry entry. Every bank's deep link is **unverified**; the package/store fallback ships either way (1.5). |
| A8 | **Never mark a payout fulfilled because a bank app opened.** The parent returns and confirms in a separate step ("I sent it" → `POST /payouts/{id}/fulfil`), and the confirmation names the amount. |
| A9 | `insufficient_funds` on fulfil is handled: the parent sees why and can decline. |
| A10 | The parent can decline. |
| A11 | Rules from earlier phases hold (1.7). |

**Choices I made that you can change.** If you say nothing, the default applies.

| # | Question | Default |
|---|---|---|
| C1 | **Where the parent's request list lives.** | **A section at the top of the To check tab**, above the proofs. Reasons: (1) the tab is already "things waiting for me", which is what a request is; (2) a teen has at most one open request, so the list is short, usually 0–2 rows, and a whole tab would be empty most days; (3) the badge already means "needs your attention", so it becomes proofs + requests with no new concept; (4) a payout moves money and expires, so it sits **above** proofs; (5) one place to look, which is how the push and the badge both point. Cost: the tab's name ("To check") fits a payout less well. Default is to keep the label and route (`/parent/review`) and let the section headers say "Payout requests" / "Proofs"; renaming the tab ("Waiting for you") touches Phase 1 strings and tests, so I would do it only on your word. A separate tab costs a third nav item that is mostly empty, and splits the badge. |
| C2 | **Where the minimum comes from.** The API exposes no minimum; `api.md` only says the default is `10000` minor (100 KZT, `LEDGER_MIN_PAYOUT_AMOUNT`). | A constant `kMinPayout = Money.kzt(10000)` in `app/config.dart`, used for the inline hint and to disable Send. **Part 3 B1** asks for the real value. If the server's 422 `amount_too_small` arrives anyway (the server's minimum is higher), the copy has **no number** ("That is below the smallest amount you can cash out."): the constant could be stale, and the error carries no value. |
| C3 | **Amount input.** | Same parser and field rules as the Phase 1 reward field (`Money.parseTenge`, whole tenge by default, `,` or `.` for tiyn). No "cash out everything" shortcut (not asked for). |
| C4 | **Entry point on teen home.** | A "Cash out" button under the coin and pending chip. When `openPayout` exists it is **replaced** by the open-request card. |
| C5 | **When the button is disabled, and what it says.** | In this order: (a) `openPayout` present → no button, the card shows. (b) `balance < 0` → disabled, "You owe {debt} for a missed task. New rewards pay it off first, then you can cash out." (`debt = −balance`.) (c) `available < kMinPayout` → disabled, "You need at least {min} available to cash out." plus, only when `locked > 0`, "Money set aside for goals is not included." (d) otherwise enabled. Balance is checked before available because `locked` can exceed a reduced balance, and the debt copy would then be wrong. |
| C6 | **Parent preselection with several parents.** | **None.** The teen must choose, so a request never goes to the wrong parent by default. Send stays disabled until one is picked. |
| C7 | **After a 409 `payout_already_open`.** | Message on the form, silent dashboard refresh (the card appears behind it), and the main button becomes "Back to home". It does not retry. |
| C8 | **Expiry label.** | Coarse and computed from `expiresAt` minus the device clock: "6 days left", "5 hours left", "Less than an hour left". Once `expiresAt` has passed (the ticker runs about once a minute) it says "Expires any moment", never a negative. No ticking timer; it recomputes on every build and the home refetches on resume. The client never derives the expiry from `requestedAt`. |
| C9 | **`openPayout.expiresAt` is required in the model.** | The backend has it built and it is deployed to staging before this phase is finished (T2). A missing or malformed `expiresAt` makes `OpenPayout` fail the dashboard loudly (`invalid_response`), like an unknown task state. This is a deliberate difference from `milestoneId` in Phase 1, which stayed optional while the backend was behind. |
| C10 | **Teen outcome screen.** | One small read-only screen, `/teen/home/payout/:id`, loaded with `GET /payouts/{id}`. It is where `PAYOUT_FULFILLED / DECLINED / EXPIRED / UNLINKED` taps land ("{parent} sent it", "{parent} declined", "It expired", "You are no longer linked"). Without it a tap from a closed app would show only a changed coin. It is **not** a history: it shows one payout. If the payout is still `REQUESTED` it shows the same card, with Cancel. |
| C11 | **"I sent it" is always available**, even if no bank app was ever opened. | Payouts can be settled in cash (api.md: "hands over the cash"). Opening a bank app is a convenience, not a prerequisite. |
| C12 | **Copied amount format.** | Digits only, no grouping, no currency: `5000`, or `5000,50` if there are tiyn. Whether each bank's field accepts a pasted comma is part of the T1 check. |
| C13 | **Bank launch mechanism.** `url_launcher` cannot open an app by package. | **No new package.** A small native method channel in `MainActivity` (`kz.tiyn.app/banks`), the same pattern as `NotificationSettingsOpener` (2a D1): launch intent by package → `market://details?id=` → `https://play.google.com/store/apps/details?id=` → report `unavailable`. If T1 finds a scheme worth using, P9 adds it on the same channel (an `ACTION_VIEW`), still without a package. **I will stop and ask before adding any package.** |
| C14 | **Parent screen after returning from the bank.** | Nothing is persisted about "I opened a bank". If Android kills our process meanwhile, the parent comes back to home and finds the request still in the To check list (the server holds it). On resume the payout silently refetches, because the teen may have cancelled while the parent was in the bank app. |
| C15 | **Parent home rows.** | Unchanged. No "asked for X" chip on teen rows (not requested; the To check badge and section carry it). |

## 1.2 How it fits together

```
core/bank/                           (the only place that knows how a bank app is opened)
  bank.dart                          Bank{id, displayName, androidPackage}, kaspi registry entry
  bank_launcher.dart                 interface + BankLaunchResult{opened, storeOpened, unavailable}
  method_channel_bank_launcher.dart  real implementation (channel kz.tiyn.app/banks)
  no_bank_launcher.dart              no-op: the default in tests and providers
  bank_providers.dart                bankLauncherProvider (default no-op; main wires the real one)

features/payouts/
  data/         payout.dart, payout_state.dart, cancel_reason.dart, payout_repository.dart
  application/  payout_providers.dart       requestedPayoutsProvider, payoutDetailProvider(id)
                request_payout_controller.dart   key lifecycle, submit, error mapping
                cash_out_rule.dart          PURE: balance + available + locked + open? -> CashOutState
                payout_problem.dart         PURE: ApiException -> PayoutProblem enum (teen/parent)
                expiry_label.dart           PURE: (expiresAt, now) -> ExpiryLabel
  presentation/ request_payout_screen.dart, open_payout_card.dart, teen_payout_screen.dart,
                parent_payout_screen.dart, payout_requests_section.dart, pay_with_bank_panel.dart,
                confirm_sent_sheet.dart
```
`features/payouts` may import `features/family` (names, parents) and `features/auth`. Teen home embeds `CashOutButton` / `OpenPayoutCard` and the To check tab embeds `PayoutRequestsSection`, both from `features/payouts/presentation`: the same UI-composition exception 2a took for `NotifyCards`. `core/` imports nothing from `features/`. Nothing outside `core/bank` calls the platform channel.

**Model additions.** `Dashboard` gains `OpenPayout? openPayout` (`id, parentId, amount, requestedAt, expiresAt`, all required when the object is present). `Payout` is the full `PayoutResponse`. `PayoutState` and `CancelReason` are enums with a `wire` name that **fail loudly** on an unknown value, like `TaskState`.

**Lists use the Phase 1 pattern:** `requestedPayoutsProvider` is `GET /payouts?state=REQUESTED` with a silent `refresh()` (old data stays, failures are swallowed), sorted **oldest request first** (soonest to expire). The API promises no order.

## 1.3 Teen flow

**Request form** (full-screen, outside the shell like the create-task form, so it covers nothing it needs):
```
┌──────────────────────────────┐
│ ✕  Cash out                  │
│ Available    12 500 ₸        │
│ Amount (₸)  [_____________]  │  ← inline error under the field
│ Smallest cash-out: 100 ₸     │
│ Ask                          │
│  ( ) Aigerim   ( ) Dauren    │  ← only with 2+ parents; with one: "To: Aigerim", no choice
│ [        Send request      ] │
└──────────────────────────────┘
```
- Client checks, in this order: not a number → invalid; `≤ 0`; `< kMinPayout` (C2); `> available`. Send is disabled until valid and, with several parents, until one is chosen (C6).
- **Key lifecycle** is the Phase 1 P4 rule, because the same two failure kinds exist:
  - **Rejected (any 4xx):** nothing was created. Fields stay editable and the first edit of the amount or the parent makes a **new** key (the server rejects a changed payload under an old key, 422 `invalid_idempotency_key`).
  - **Ambiguous (timeout, network, 5xx):** the request may exist. Fields lock, the main action becomes "Try again" with the **same** key and the identical payload. "Edit details" unlocks with a short warning and makes a new key. If the first attempt did land, the same-key retry returns the original payout; a different key would hit 409 `payout_already_open`, which is handled by C7.
- **Success:** await a dashboard refresh, then pop home (the card replaces the button; if the refresh fails the pop still happens and the next refetch shows the card; a second request would hit C7). A snackbar says "Request sent to {parent}".

**Error copy** (English drafts; ru and kk are written in the step, kk gets `@@x-review`). Each lands inline on the form, never in a dialog:

| Code | Copy | Extra |
|---|---|---|
| `amount_too_small` (422) | "That is below the smallest amount you can cash out." (no number, C2) | refetch nothing |
| `insufficient_funds` (422) | "You don't have that much available any more. Money already held for a request or saved for a goal is not available." | silent dashboard refresh, then re-validate against the new `available`; the helper line shows the new number |
| `payout_already_open` (409) | "You already have a cash-out request open. Wait for your parent to answer, or cancel it first." | C7 |
| `invalid_amount` (422) | "Enter an amount greater than zero." | |
| `parent_required` (422) | "Choose who to ask." | |
| `forbidden` (403) | "You are no longer linked to this parent." | silent family refresh |
| network / timeout / 5xx | the existing connection copy | ambiguous branch above |

**Open request card on home** (replaces the button, C4):
```
┌──────────────────────────────┐
│ Waiting for Aigerim          │
│ 5 000 ₸ held for this request│  ← explains why the coin dropped
│ 6 days left                  │  ← C8, from expiresAt
│ [ Cancel request ]           │
└──────────────────────────────┘
```
Cancel opens a confirmation sheet that names the amount ("Cancel your 5 000 ₸ request to Aigerim?"), then `POST /payouts/{id}/cancel`, then a dashboard refresh. 409 `invalid_transition` means it was answered meanwhile: say "This request just changed. Here is the latest." and refresh; nothing else. The card is not a link: on home it carries Cancel inline, and the outcome screen (C10) is reached only from a push.

**When the request is answered,** the `PAYOUT_*` push refreshes the dashboard and the card disappears and the coin updates with no pull-to-refresh. The outcome screen (C10) explains it if the teen taps the push.

## 1.4 Parent flow

**To check tab (C1):**
```
┌──────────────────────────────┐
│ To check                     │
│ Payout requests (1)          │
│ ┌──────────────────────────┐ │
│ │ Dana asks for 5 000 ₸    │ │  ← tap opens the payout screen
│ │ 2 hours ago · 6 days left│ │
│ └──────────────────────────┘ │
│ Proofs (2)                   │
│ ...existing rows...          │
└──────────────────────────────┘
```
- The two sections load independently, so one failing does not blank the other: each has its own loading, error ("Try again") and empty state. The whole-tab empty sentence shows only when **both** are empty and loaded.
- The tab badge becomes proofs + requests, with the existing "N waiting" semantics label.
- The section refetches on resume and on tab select through `RefreshOnForeground`, as the proofs do.

**Payout screen** (`/parent/review/payout/:id`, inside the review branch so back lands on the To check list, as 2a A10 did for reviews). It watches `payoutDetailProvider(id)`:
```
┌──────────────────────────────┐
│ ‹  Payout request            │
│ Dana asks for                │
│ 5 000 ₸           (large)    │
│ 2 hours ago · 6 days left    │
│                              │
│ 1  Send it                   │
│    [ Open Kaspi ]            │
│    [ Copy amount 5000 ]      │  ← always shown, not only as a fallback
│    Pick Dana in Kaspi and    │
│    enter 5 000 ₸.            │
│ 2  Then confirm              │
│    [ I sent it ]             │  ← opens the confirmation sheet
│    [ Decline ]               │
└──────────────────────────────┘
```
- **Confirmation sheet** for "I sent it": "Confirm you sent 5 000 ₸ to Dana? Tiyn cannot see the transfer. Confirming takes 5 000 ₸ off Dana's balance." Buttons: "Yes, I sent it" / "Not yet". Only the first calls `POST /payouts/{id}/fulfil`.
- **Decline** has its own confirmation ("Decline Dana's 5 000 ₸ request?"), then `POST /payouts/{id}/decline`. No reason field (the API takes none).
- **After success** (fulfil or decline) the screen pops to the list, the requests list refreshes and a snackbar confirms.
- **Errors on the payout screen:**

| Case | What the parent sees |
|---|---|
| `insufficient_funds` on fulfil (A9) | A card above the buttons: "Dana's balance no longer covers 5 000 ₸. A missed-task penalty or a goal saving took part of it. You can decline this request, and Dana can ask again for a smaller amount." "I sent it" is hidden, **Decline stays**. No balance number is shown (parents do not see balances; Phase 1 D1). |
| 409 `invalid_transition` (fulfil or decline) | Reload the payout and show the outcome panel for its real state: "Dana cancelled this request", "It expired", "You already confirmed this", "You are no longer linked". If the state is `FULFILLED`, say so as success. |
| 403 `forbidden` | "You are no longer linked to Dana." with a back action. |
| 404 on load | "This request is no longer available." with a back action. |
| timeout / network / 5xx on fulfil | Keep the screen, show the connection error, the button becomes "Try again". It is safe: a repeat on an already `FULFILLED` payout writes no second debit. After an ambiguous failure the payout is reloaded first, so a request that actually went through shows as done instead of asking again. |

- A non-`REQUESTED` payout shows the read-only outcome panel and none of the actions.
- A request past `expiresAt` but still `REQUESTED` is still actionable (the server allows it until the ticker cancels). The label says "Expires any moment".

## 1.5 Fulfil through a bank app (A7, A8, C11–C14)

```
abstract interface class BankLauncher {
  Future<BankLaunchResult> open(Bank bank);   // opened | storeOpened | unavailable
}
```
`Bank` is a registry entry (`id`, `displayName`, `androidPackage`). **A bank enters the registry only once T1 has verified its package id on a real phone** (UC-09: "only banks with a working, low-effort integration are added"); its deep link is a separate, optional finding. With one bank in the registry the screen shows a single "Open {bank}" button; with several it shows a short list of banks (name only, order = registry order, Kaspi first). The app does not remember the last bank used (nothing persisted, C14). Adding a bank later is one registry entry plus one `<queries>` line.

**What ships regardless of T1 (the fallback chain):**
1. Launch the installed app by package (`getLaunchIntentForPackage`) → `opened`.
2. Not installed → `market://details?id=<package>` → `storeOpened`.
3. No Play Store handler → `https://play.google.com/store/apps/details?id=<package>` → `storeOpened`; nothing at all → `unavailable`, and the screen says "Could not open Kaspi. Open it yourself, then come back and confirm."
4. In every case the amount and the **Copy amount** button are on the screen (not only on failure), because with no verified prefill the parent has to type the amount into Kaspi.

**Android 11+ package visibility.** `getLaunchIntentForPackage` returns `null` for an installed app we cannot see. The manifest's existing `<queries>` block gets `<package android:name="kz.kaspi.mobile"/>`. A resource test (in the style of `notification_resources_test.dart`) asserts every `Bank.androidPackage` in the registry is declared there, so adding a bank without the declaration fails CI. Starting the Play Store intent needs no declaration. If P9 adds a scheme, its `<intent><action VIEW/><data scheme=…/></intent>` goes in the same block.

**Not in this phase:** recipient prefill. Bank transfers go to a phone number and we hold none for the teen (and should not ask for one for an unverified feature). The parent picks the teen in the bank app by the name our screen shows.

**Hard rule:** nothing in `BankLauncher`, its result, an app resume, or the lifecycle calls fulfil. Only the confirmation sheet's "Yes, I sent it" does, and a test pins it.

## 1.6 Push: routing and refresh (replaces 2a's placeholder rows)

`push_location.dart` currently returns early to the role home whenever `taskId` is null. That is wrong for payouts, which carry `payoutId`, so the function is restructured (task types read `taskId`, payout types read `payoutId`). `PushPayload.payoutId` already exists.

**Routing** (the PAYOUT_* rows of 2a §1.5 become real):

| Type | Role | Location |
|---|---|---|
| `PAYOUT_REQUESTED`, `PAYOUT_CANCELLED_BY_TEEN` | parent | `Routes.parentPayout(payoutId)` → `/parent/review/payout/:id` |
| `PAYOUT_FULFILLED`, `PAYOUT_DECLINED`, `PAYOUT_EXPIRED`, `PAYOUT_UNLINKED` | teen | `Routes.teenPayout(payoutId)` → `/teen/home/payout/:id` |
| `PENALTY_APPLIED`, `FAMILY_*` | either | role home (unchanged) |
| any `PAYOUT_*` for the **other** role, a missing or blank `payoutId`, unknown type | either | role home. Never throws. |

`PAYOUT_CANCELLED_BY_TEEN` lands on the payout screen, which then shows "Dana cancelled this request" instead of an unexplained disappearance; back goes to the list.

**Refresh rows** (all use the silent `refresh()`; never `ref.invalidate`, per 2a §1.6). `RefreshTarget` gains `requestedPayouts` and `payoutDetail`.

| Push | Refresh |
|---|---|
| parent `PAYOUT_REQUESTED`, `PAYOUT_CANCELLED_BY_TEEN` | requested payouts, that payout's detail if open |
| parent `FAMILY_UNLINKED` | family, role lists, **requested payouts** (an unlink cancels the open payout) |
| parent unknown type | role lists **plus** requested payouts |
| teen `PAYOUT_FULFILLED`, `PAYOUT_DECLINED`, `PAYOUT_EXPIRED`, `PAYOUT_UNLINKED` | dashboard, that payout's detail if open |
| teen `PENALTY_APPLIED` | dashboard (unchanged; it can also invalidate a parent's pending fulfil, which the fulfil error path covers) |

`PayoutDetail` refreshes only if its provider exists (`ref.exists`), as `taskDetail` does. Foreground banners work as in 2a with no change.

## 1.7 Rules for this phase
- No new user-visible strings outside the ARB files; ru, kk and en, new kk strings get the `@@x-review` treatment.
- **Never log** amounts, names, or ids from payloads, in app code or tests' debug output. `BankLauncher` logs the result enum only. Error logging is the error class only.
- Every new screen and sheet has loading, empty and error states, and passes 360×640 at 1.3× text in ru and kk with no overflow. Fix by wrapping or scrolling, never by shrinking fonts.
- Every button that calls the API shows a busy state and ignores a second tap.
- Nothing outside `core/bank` touches the bank platform channel (a test checks it).

---

# Part 2 — Steps

Rules are the same as Phase 0, 0.1, 1 and 2a: one commit per step, **`flutter analyze --fatal-infos`, `dart format`, all tests, codegen and l10n clean before each commit**, no push, **no Co-Authored-By**, add packages only with `flutter pub add` and **only after asking** (this plan needs none), and stop and ask if a step needs a backend change.

## P0. This plan
Commit: `docs: phase-2b payouts plan`. **Stop for sign-off.**

## P1. Payout data layer
`features/payouts/data/`: `payout.dart` (freezed: id, teenId, parentId, `Money` amount, state, requestedAt, expiresAt, resolvedAt?, cancelReason?), `payout_state.dart`, `cancel_reason.dart` (enums with `wire`, unknown fails as `invalid_response`), `payout_repository.dart` (`create` with `IdempotencyKey`, `list({state})`, `get`, `fulfil`, `decline`, `cancel`). `OpenPayout` added to `Dashboard` (C9). `application/`: `payout_providers.dart`, `payout_problem.dart` (pure code → problem mapping, teen and parent variants), `expiry_label.dart`, `cash_out_rule.dart`, `kMinPayout` in `app/config.dart`.
Tests: JSON round-trip including a `CANCELLED` payout with a reason; unknown state and reason throw; each repository method sends the right path, query and body, and `create` carries the key and fulfil/decline/cancel carry none; `OpenPayout` parses with `expiresAt`; a missing or malformed `expiresAt`, or any malformed `openPayout`, fails the dashboard; `cash_out_rule` over every branch of C5 (open payout, debt, below minimum with and without `locked`, `locked > balance`, enabled); `expiry_label` for days, hours, under an hour, exactly now, past, with a fixed clock; `payout_problem` for every code in the table.
Commit: `feat(payouts): payout models, repository and rules`.

## P2. Teen: request a cash-out
`request_payout_controller.dart`, `request_payout_screen.dart`, the route (outside the shell), the "Cash out" button and its disabled explanations on teen home. Strings in ru, kk, en.
Tests: client validation order (not a number, zero, below minimum, above available); one tap sends exactly one request; **one parent → no picker and the right `parentId`; two parents → picker, nothing preselected, Send disabled until chosen**; the header is always present; after a 4xx an edit of the amount or parent makes a new key, an unrelated tap does not; after timeout/network/5xx the action is "Try again" with the same key and locked fields; "Edit details" unlocks and the next send uses a new key; each row of the error table lands inline with its copy, including `payout_already_open` → "Back to home" and `insufficient_funds` → refreshed available shown; debt copy when `balance < 0`; below-minimum copy; goals line only when `locked > 0`; success refreshes the dashboard before popping.
Commit: `feat(teen): request a cash-out`.

## P3. Teen: open request and outcome
`open_payout_card.dart` on home, cancel with confirmation, `teen_payout_screen.dart` (C10), route `/teen/home/payout/:id`. The card shows amount, parent, expiry label and the "held" line.
Tests: card shows from `dashboard.openPayout` and replaces the button; countdown label from `expiresAt`; Cancel needs the confirmation, names the amount and calls cancel once; 409 `invalid_transition` shows the "just changed" text and refreshes; the card disappears when a refreshed dashboard has no `openPayout`; the outcome screen for `FULFILLED`, each `CancelReason` and `REQUESTED`; 404/403 on load → "no longer available" with a back action.
Commit: `feat(teen): open payout request and outcome`.

## P4. Parent: requests on the To check tab
`payout_requests_section.dart`, `requestedPayoutsProvider` wiring, the section in `ReviewListScreen`, the badge in `ParentShell`, `RefreshOnForeground` on the section. Names from `familyNamesProvider`; a payout whose teen is not in the family list shows a neutral label, never crashes.
Tests: the section appears above proofs; oldest request first; sections load and fail independently; whole-tab empty only when both are empty; the badge is proofs + requests, hidden at 0, "9+"; refetch on resume and on tab select; exactly one `GET /payouts?state=REQUESTED`.
Commit: `feat(parent): payout requests on the To check tab`.

## P5. Parent: payout screen, decline and confirm
`parent_payout_screen.dart`, `confirm_sent_sheet.dart`, route `/parent/review/payout/:id`. The bank panel is a stub here (a disabled bank button is **not** shipped; this step ships the amount, the copy button, "I sent it" and "Decline"; P6 adds the bank button or list).
Tests: "I sent it" opens the sheet and **nothing is sent until "Yes, I sent it"**; the sheet names the amount; fulfil called once on a double tap; success pops and refreshes the list; decline needs its confirmation and calls decline once; every row of the parent error table (A9 `insufficient_funds` hides "I sent it" and keeps Decline; `invalid_transition` reloads and shows the real outcome; `forbidden`; 404; ambiguous failure reloads then offers "Try again"); a non-`REQUESTED` payout shows no actions; silent refetch on resume.
Commit: `feat(parent): confirm or decline a payout request`.

## P6. Bank launcher and the fallback
`core/bank/*` (registry with every bank T1 verified), `fake_bank_launcher.dart`, the `MainActivity` channel `kz.tiyn.app/banks`, one `<queries><package …/></queries>` line per registry bank, the bank button or short bank list and result messages on the payout screen, `bankLauncherProvider` wired in `main`.
Tests: each result (`opened`, `storeOpened`, `unavailable`) shows the right text and keeps the amount and copy visible; **opening a bank never calls fulfil, with or without a resume afterwards**; Copy puts the C12 string on the clipboard; the resource test (every registry package declared in `<queries>`); no import of the bank channel outside `core/bank`. With one bank the single button shows, with several the list shows and each row launches its own package. Native behaviour is checked in T1/T4.
Commit: `feat(payouts): open a bank app with a store fallback`.

## P7. Push routing and refresh
`push_location.dart` restructured and extended per 1.6, `RefreshTarget.requestedPayouts` / `payoutDetail` and their rows, the `Routes.parentPayout` / `teenPayout` helpers, update the 2a doc comments that say "Phase 2b remaps".
Tests: **every `PushType`** in the right role, the wrong role, with a missing and a blank `payoutId` (the table test must still cover all of `PushType.values`); the pure function never throws on garbage; a cold-start `PAYOUT_REQUESTED` goes through splash and lands on the payout screen with back to the To check list; a warm tap; each refresh row calls the right silent refresh and does not set the family loading; **a `PAYOUT_FULFILLED` push updates the teen's coin and removes the card with no pull-to-refresh; a `PAYOUT_REQUESTED` push adds the row and the badge with no pull-to-refresh**.
Commit: `feat(push): route and refresh payout pushes`.

## P8. Hardening
Extend `test/app/layout_test.dart` for the request form (one parent and several), disabled button explanations, open-request card, teen outcome screen, the requests section, the parent payout screen in each state, both confirmation sheets and the insufficient-funds card, in ru and kk at 360×640 and 1.3×. Semantics for the card, rows, step headings, sheet actions and the badge label. Loading, empty and error state tests for each screen.
Commit: `test: layout and states for payout screens`.

## P9. (Conditional, per bank) Deep links
**Only for banks where T1 found a scheme or intent link that lands on the bank's transfer page** (no prefill is expected or needed: the parent types the amount and picks the teen there, using the copy button). Add it to that bank's registry entry, try it first on the same channel, fall back to the P6 chain if it does not resolve; declare the scheme in `<queries>`; amount prefill is not built unless a bank documents it; the amount stays with the copy button. Banks without a working link keep the fallback. If T1 finds none, this step is dropped.
Commit: `feat(payouts): bank deep links`.

---

# Human tasks

| # | Task | Needed by |
|---|---|---|
| T1 | **Verify every bank on a real phone (UC-09: all unverified). One row per bank: Kaspi, Freedom, Forte, and any other you want in the list.** For each: (a) get its package id from its Play Store URL (`?id=`; no install needed) or, if installed, with `adb shell pm list packages \| grep -i <name>` (or from its Play Store URL `?id=`). (b) List what it registers: `adb shell dumpsys package <package>` (intent filters with `Scheme:` / `Authority:`), or pull the APK (`adb shell pm path <package>`, `adb pull`) and read `<data android:scheme>` in its manifest with `apkanalyzer manifest print`; also `adb shell pm get-app-links <package>` for https app links. Only exported activities count. (c) Try each scheme: `adb shell am start -a android.intent.action.VIEW -d "<link>" <package>`: does the app open, to which screen, does it ask to log in first? (d) Prefill: the manifest shows schemes and paths but **not parameter names**, so an amount or recipient parameter can only come from the bank's own documentation or a link it generates itself (for example a payment link shown in its UI). Do not guess parameters. (e) Does the amount field accept a pasted `5000,50`, or only `.`? Record package id, working link (or "none"), and prefill (or "none") per bank in a table in the final report. I can write a script that runs (a)–(c) for a list of banks against a connected phone, if you want it (it would be a new file, so I am asking first). | P6 (package ids), P9 (links), C12 |
| T2 | Deploy the backend with `expiresAt` on `openPayout` to staging **before P2** (C9: the model requires it). | P1 tests use a fixture, but P2–P3 on-device runs need it |
| T3 | Two phones on staging: a teen account and a parent account linked, the verified bank apps installed on the parent's phone, plus the staging teen with a positive balance (approve a task first). | Definition of done |
| T4 | A phone or emulator **without** the bank apps, to see the store fallback. | Definition of done |

---

# Part 3 — Backend requests

None blocks this phase. Each has a fallback.

| # | Request | Why | Fallback used now |
|---|---|---|---|
| B1 | Expose the minimum payout amount (for example `minPayoutAmount` in `GET /balance` and `dashboard.balance`). | The client validates against it (A1). | `kMinPayout` constant of 100 ₸; the 422 `amount_too_small` copy has no number (C2). |
| B2 | `expiresAt` on `dashboard.openPayout`: **built; you deploy it to staging before P2** (T2). | The countdown (A5). | None: the field is required (C9). |
| B3 | `teenDisplayName` / `parentDisplayName` on `PayoutResponse`. | Today names come from `GET /family`. | Join by id with the already-loaded family. A payout whose person is missing gets a neutral label. Low priority. |
| B4 | Document the errors of `fulfil`, `decline` and `cancel` in `api.md`. Verified in code: `fulfil` fails 422 `insufficient_funds` when `amount > balance − locked` (a penalty **or** a goal saving after the request can cause it), a repeat on a `FULFILLED` payout is a harmless no-op, `invalid_transition` on a `CANCELLED` one. | Today the table lists errors for the whole group. | Handled as read from code (1.4). |
| B5 | A parent summary (open payout count) | Avoids a list call for the badge. Same as Phase 1 B4. | One `GET /payouts?state=REQUESTED`. |

Not requested: the teen's phone number for recipient prefill (PII we do not hold, for a feature that may not exist); a bank field on the payout (UC-09: "not recorded in the MVP").

---

## Definition of done
- [ ] The plan commit plus 8 step commits (9 if T1 enables P9); analyze with `--fatal-infos`, format and all tests green; codegen and l10n produce no diff.
- [ ] Every test named in the steps exists. In particular: key reuse and renewal; one-vs-several parents; every error-table row; **opening a bank never fulfils**; the fulfil confirmation names the amount; `insufficient_funds` on fulfil; the full push routing table including payout types; the manifest `<queries>` check.
- [ ] Every new screen has loading, empty and error states and passes the 360×640 / 1.3× check in ru and kk.
- [ ] **Two-phone staging run (T3), written up in the final report with what was seen on each step:**
  1. **Happy path.** The teen requests an amount. The parent's locked phone shows the high-priority push; tapping it opens the payout screen. The parent taps a bank (it opens, or the T4 fallback shows on a phone without it), sends the money, returns, taps "I sent it" and confirms in the sheet. The teen's open-request card disappears and the coin and balance update **with no pull-to-refresh**, and the push banner or notification says it was paid.
  2. **Decline.** Request, then the parent declines. The teen's card disappears, the push opens the outcome screen with "declined", and the coin returns to the full balance.
  3. **Cancel.** The teen requests, then cancels behind the confirmation. The parent's row and badge disappear with no pull-to-refresh, and the parent's `PAYOUT_CANCELLED_BY_TEEN` push opens a screen that says the teen cancelled.
  4. **A request the teen can't afford.** (a) With balance below the minimum the Cash out button is disabled with the reason. (b) With a penalty making the balance negative (let a task with a penalty expire), the debt copy shows. (c) **A request that becomes unaffordable:** the teen requests, then a task with a penalty expires (or a goal is funded) before the parent confirms; the parent's "I sent it" shows the insufficient-funds card, "I sent it" is gone, and Decline works.
  5. **Bank checks:** the T1 table is in the report (package id, link, prefill per bank), each registry bank opened on the parent's phone, and the store fallback was seen on a phone without the bank apps (T4).
  Expiry cannot be waited out on staging (7 days); the countdown copy is covered by tests with a fixed clock, and the run notes whether `LEDGER_PAYOUT_EXPIRY` could be lowered on staging to see an `EXPIRED` push.

## Out of scope (don't do)
Goals, wallet history, recurring tasks, parent-side teen balances, payout history screens beyond the two single-payout screens above, a bank outside the T1 table, remembering the last bank used, iOS (the `ios/` folder is left alone), recipient prefill, recording which bank was used, notification preferences, a tab rename, and any backend change. A backend gap goes in Part 3 with a fallback; it is not worked around silently.

## Pending after this phase
- **iOS banks.** Add `iosScheme` and an App Store id to `Bank`; a Swift handler on the `kz.tiyn.app/banks` channel (`canOpenURL`/`open`, App Store fallback); each scheme under `LSApplicationQueriesSchemes` in `Info.plist`, with a test like `bank_resources_test` for it. Freedom's `bankffinlink` is verified on Android only; every scheme needs checking on a real iPhone. `url_launcher` with schemes is the cross-platform alternative (new package, needs approval).
- **Other iOS work** from Phase 2a: APNs and iOS Firebase config, the iOS side of `PushMessaging`, the notification-settings opener, Google sign-in setup.
- **More Android banks.** Kaspi and Forte package ids are unverified; each needs a registry entry and a `<queries>` line.
- **Freedom transfer-page link.** Freedom is a single-activity app and documents no deep link: `bankffinlink://` only reaches the passcode screen, and the Transfers page has no separate Android screen (checked on a device). Ask Freedom for an official link to the Transfers screen that survives login. If they give one, add it as P9 with today's behavior (open the app, amount on the clipboard) as the fallback.
- **List pagination.** The backend now returns `{items, nextCursor}` from `GET /tasks`, `/payouts`, `/goals` and `/task-series`. Handled in a separate PR: accept both shapes until the backend deploys, then follow `nextCursor`.
