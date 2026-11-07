# Phase 1: the core loop — implementation plan

**Audience:** the coding agent that carries this out, after the user has signed off Part 1.
**Repo:** `/Users/medettegistay/Projects/tiyn_app`. **Backend (read-only):** `/Users/medettegistay/Projects/tiyn`, contract in `docs/api.md`. Do **not** edit the backend in this phase. The backend work for this plan (idempotency on `POST /tasks`, `milestoneId` on dashboard tasks) is done; **P4 still waits until it is deployed to staging.**

**Goal:** one complete loop that works on staging with two real phones.
Parent adds a task for a teen → teen sees it, does it, submits proof → parent reviews and approves → teen sees the reward.

**UX is the driver.** There are no mockups for these screens yet, so Part 1 is the design. The user reviews and changes it *before* any code. The API shapes the details, not the structure: where the API can't support what the UX needs, it is listed in Part 3 as a backend request, with a fallback that needs no backend change.

---

# Part 1 — Design (the user signs this off)

## 1.1 Decisions, with the default I'll use if you say nothing

| # | Question | Default |
|---|---|---|
| D1 | Does a parent see a teen's balance? (`GET /balance` is teen-only today.) | **No** in Phase 1. Parent rows show work status, not money. |
| D2 | Where does the join code live now? | Off the home screen. An "Add teen" action opens a sheet with the code, Copy and Share. Only when **no teen is linked** does the code appear on the page itself, because it is then the one thing to do. |
| D3 | Teen detail structure | Two tabs inside the page: **Tasks** and **Milestones**, one "+" action that creates whichever tab is open. |
| D4 | Is the review step in Phase 1? | **Yes.** Without approve the loop can't be tested end to end. It lives in the existing parent "To check" tab. |
| D5 | Creation is not idempotent on the backend (retry = duplicate). | **Decided:** `POST /tasks` takes a required `Idempotency-Key`, stored in a dedicated keys table with its own expiry (Part 3, B1). The backend side is built; **P4 starts only after it is deployed to staging.** The in-flight button guard stays as a second layer. |
| D6 | Recurring tasks, goals, payouts, push | **Phase 2.** |
| D7 | Currency input | Whole tenge by default ("1 500"), `,` or `.` allowed for tiyn. Shown with `formatMoney`. Max 100 000 ₸ (backend default). |

## 1.2 Screens (360 wide, sketches)

**Parent · Home = "My teens"** (replaces the code screen)
```
┌──────────────────────────────┐
│ My teens             [+ Add] │  ← "+ Add" opens the code sheet
│                              │
│ ┌──────────────────────────┐ │
│ │ (D) Dana              ›  │ │  ← row body opens teen detail
│ │     2 to check          │ │  ← gold chip when > 0
│ │     [ + New task ]       │ │  ← most frequent action, on every row
│ ├──────────────────────────┤ │
│ │ (A) Aibek             ›  │ │
│ │     3 active             │ │
│ │     [ + New task ]       │ │
│ ├──────────────────────────┤ │
│ │ (M) Madina            ›  │ │
│ │     Nothing active       │ │
│ │     [ + New task ]       │ │
│ └──────────────────────────┘ │
│  pull down to refresh        │
├──────────────────────────────┤
│   Home         To check (2)  │  ← count badge on "To check"
└──────────────────────────────┘
```
Status line, in priority order: "N to check" (any `SUBMITTED`), else "N active" (`ASSIGNED`), else "Nothing active". Derived from **two** calls, `GET /tasks?state=SUBMITTED` and `GET /tasks?state=ASSIGNED`, grouped by `teenId`, **not** the full history (which grows without bound). Because history is not loaded, the home cannot tell "no tasks yet" from "everything is finished", hence "Nothing active". Sorted: to-check first, then by name. The `SUBMITTED` call is the same data the "To check" tab and its badge use (one provider, not two requests).
The "+ New task" button opens the create form for that teen (P4 adds it together with the form, so there is no dead button before then).
**Empty (no teens):** the code card is the page (large code, Copy, Share, one line of how it works). That is the only place the code is prominent.

**Parent · Teen detail** (`/parent/home/teen/:id`, keeps the bottom bar)
```
┌──────────────────────────────┐
│ ‹  Dana                  [+] │
│ [ Tasks (3) | Milestones (1)]│  ← segmented control
│ ┌──────────────────────────┐ │
│ │ Wash dishes   1 500 ₸    │ │
│ │ Due today 18:00 [Waiting]│ │  ← state chip
│ └──────────────────────────┘ │
│ ...                          │
└──────────────────────────────┘
```
This is the only screen that loads the full history: `GET /tasks?teenId=<id>`.
Tasks tab: tasks **without** a `milestoneId`. Open first (ordered by deadline), then a collapsed "Finished (n)" group (approved, rejected, cancelled, expired).
Milestones tab: title, reward, progress bar "2 of 5 done" (counted client-side from children by `milestoneId`), deadline. Tap → milestone detail (children list, "+ Add task to this milestone", Cancel milestone).

**Parent · Create task / milestone** (full-screen form, `Close` top-left)
Fields in this order: **Title**, **Reward (₸)**, **Deadline** (date and time pickers, default tomorrow 18:00 local), optional **Description**, and a collapsed row "Add a penalty if it's missed" that reveals **Penalty (₸)**. A milestone has the same fields and no penalty row. The button says "Add task" or "Add milestone". Inline errors under each field, never a dialog.
From the milestone detail, the same form opens with the milestone fixed and the deadline bounded by the milestone's.

**Parent · Task detail:** title, description, reward, penalty, deadline, state chip, decision note if any. Action: "Cancel task" (only `ASSIGNED`/`SUBMITTED`), with a confirm sheet.

**Parent · To check** (existing tab): `SUBMITTED` tasks across all teens, oldest submission first, teen name on each row. The tab icon carries a **count badge** (number of `SUBMITTED` tasks, hidden at 0, "9+" above 9, with a semantics label such as "To check, 2 waiting"). Tap → review screen: task info, proof (photo full-width with tap-to-zoom, or text), attempt number. If a proof image fails to load, refetch the proofs once (`GET /tasks/{id}/proofs`) because the presigned URL expires after 10 minutes, then show a "Could not load the photo · Try again" state if it still fails. Three actions: **Approve** (primary), **Ask to redo** (optional note, optional new deadline), **Reject** (optional note, confirm sheet, says "final").

**Teen · Home** (replaces the placeholder)
```
┌──────────────────────────────┐
│ Hi, Dana                     │
│        ( 12 500 ₸ )          │  ← CoinBadge with real "available"
│   ( ⏳ 1 500 ₸ waiting )     │  ← small chip, pendingAmount, hidden when 0
│                              │
│ Tasks                        │
│ ┌ Wash dishes     1 500 ₸  ┐ │
│ │ Due 18:00        [Do it] │ │
│ Milestones                   │
│ ┌ School term  ▓▓▓░░ 2/5   ┐ │  ← chores with this milestoneId sit under it
│ │  · Read ch. 1   [Approved]│ │
│ │  · Read ch. 2   [Do it]   │ │
└──────────────────────────────┘
```
One call: `GET /dashboard`. Pull to refresh. Empty chores: a friendly line, not a blank page. "Connected to <parents>" moves to a small footer line. **No bottom navigation** in Phase 1: Progress, Goals and Activity are hidden until they exist, so the teen has Home only.
The chip is a short label with an icon ("1 500 ₸ waiting for check"), not a sentence. It is a chip, not a button.
**Grouping:** a chore whose `milestoneId` matches a milestone in the same response is shown under that milestone, not in "Tasks". (The section is called "Tasks", not "Today": the dashboard also returns work due later this week.) `milestoneId` is optional in the model; when the field is missing (older backend) or points to a milestone that is not in the response, the chore stays in the ungrouped list. Nothing is hidden because of a missing field.

**Teen · Milestone** (opens from a milestone card): title, description, reward, deadline, state chip, progress "2 of 5 steps approved", then the **steps** (the chores with this `milestoneId`) as rows with title, reward and state chip; tapping a step opens that task's detail. If the milestone is `ASSIGNED`, the primary action is "Submit milestone", opening the same proof sheet as a task.
```
┌──────────────────────────────┐
│ ‹  School term               │
│ 5 000 ₸ · due 30 Nov [Open]  │
│ ▓▓▓░░  2 of 5 steps approved │
│ Steps                        │
│  Read ch. 1      [Approved]  │
│  Read ch. 2      [Waiting]   │
│  Read ch. 3      [To do]     │
│ ┌──────────────────────────┐ │
│ │     Submit milestone     │ │  ← disabled until every step is APPROVED
│ └──────────────────────────┘ │
│ 3 steps are not approved yet │  ← says why it is disabled
└──────────────────────────────┘
```
**App-side rule (the backend does not enforce it):** the teen can submit a milestone only when it is `ASSIGNED`, it has at least one step, and **all** its steps are `APPROVED`. Otherwise the button is disabled and a line under it says why: "Finish all steps first. N of M approved." (or "This milestone has no steps yet."). The count uses the milestone's `approvedTasks`/`totalTasks` when the dashboard sends them, because the dashboard only returns recent tasks and older approved steps may be missing from the list; if they are absent, it counts the steps it has. The rule is a pure function with unit tests.

**Teen · Task detail + submit:** title, description, reward, deadline, state. If `ASSIGNED`: "Submit proof" → sheet with **Take photo**, **Choose from gallery**, **Write a note** (text proof, max 2000). A redo request shows the parent's note on top. `SUBMITTED`: "Waiting for your parent". `APPROVED`: "+1 500 ₸". `REJECTED`/`EXPIRED`/`CANCELLED`: the reason line and nothing to do.

## 1.3 Rules for every screen
- Loading → skeleton or spinner in place; **never** a blank page. Error → plain message (B7 rules) + "Try again". Empty → a sentence that says what to do next.
- Every button that calls the API shows a busy state and ignores a second tap.
- **No push in Phase 1, so lists refetch themselves:** every list screen (parent home, To check, teen detail, teen home) refetches when the app returns to the foreground and when its tab is selected, silently (the old list stays on screen; a failed refetch shows nothing), the same pattern as B8. One shared helper does this; screens don't each re-implement it.
- Times are shown in the device's zone; the API sends UTC.
- Copy is informal toward the teen ("you"), formal toward the parent, in ru and kk and en. New kk strings get `@@x-review` like the existing ones.
- Never log or persist: task text, proofs, image URLs (the presigned URL lives 10 minutes, don't cache it).
- 360×640 at 1.3× text in ru/kk must not overflow (the B11 harness).

---

# Part 2 — Steps

Rules are the same as Phase 0 and 0.1: one commit per step, analyze + tests + format + codegen + l10n clean before each commit, no push, **no Co-Authored-By**, add packages only with `flutter pub add`, stop and ask if a step needs a backend change. **Run the real pre-commit script and treat any non-zero analyze result as a failure** (Phase 0.1 shipped one by accident).

## P1. Task data layer
`lib/features/tasks/data/`: `task.dart` (freezed + json: id, teenId, parentId, kind, title, description, `Money` reward and penalty, state, deadlineAt, submittedAt, decidedAt, decisionNote, milestoneId, approvedTasks, totalTasks), `task_state.dart` and `task_kind.dart` (enums with `wire` like `Role`; unknown values must fail loudly as `invalid_response`, not silently), `proof.dart`, `task_repository.dart` (list with `teenId`/`state`, get, create, cancel, approve, reject, requestRedo, proofs, submitText, submitPhoto using `postMultipart`; create and both submits take an `IdempotencyKey` from the caller). `milestoneId`, `approvedTasks` and `totalTasks` are optional. Plus `features/tasks/application/` providers.
Tests: JSON round-trip for every field; unknown state throws; money parses; each repository method sends the right path, query, body and `Idempotency-Key`; the key is the same on a retry of the same attempt.
Commit: `feat(tasks): task models and repository`.

## P2. Parent home: teen list
Replace `ParentCodeScreen` content. New `parent_home_screen.dart` (list, status line logic as a pure function `teenStatus(submitted, assigned)` with unit tests), `add_teen_sheet.dart` (code, Copy, Share; reuse existing share message string), empty state with the code card. Data: two calls, `GET /tasks?state=SUBMITTED` and `GET /tasks?state=ASSIGNED`, never the full history. A shared refresh helper (app resume **and** tab selected, see 1.3) refreshes family and both lists. The parent shell drops the Activity placeholder (Home and To check only) and shows the count badge on "To check" from the same `SUBMITTED` provider. Route unchanged (`/parent/home`). No "New task" button yet (P4).
Tests: status priority; grouping; sort; empty state shows the code; sheet shows the code; a failed refresh keeps the list; exactly two task requests with the right `state` query and no full-history request; refetch on resume and on tab select; badge count, hidden at 0, "9+".
Commit: `feat(parent): teen list home with add-teen sheet`.

## P3. Teen detail
Route `/parent/home/teen/:id` (nested under the home branch so the bottom bar stays). Loads the full history with `GET /tasks?teenId=<id>` (the only place that does) and refetches on resume. Segmented Tasks | Milestones, with counts of **open** items (the Finished group is not counted), "Finished" group, state chip widget (`design/widgets/state_chip.dart`, one colour per state, with a text label, never colour only). Milestone progress counted client-side.
Tests: grouping into tasks vs milestones; finished group; progress counts; empty tab text.
Commit: `feat(parent): teen detail with tasks and milestones`.

## P4. Create task / milestone
Form screens per 1.2. Validation mirrors the backend (title 1–200 trimmed, reward > 0 and ≤ 10 000 000 minor, penalty 0..max, deadline in the future, milestone bounds). Map `invalid_title`, `invalid_reward`, `invalid_penalty`, `invalid_deadline`, `invalid_milestone`, `teen_required` to field or form messages in `apiErrorMessage`. In-flight guard (D5).
Add the "+ New task" button on each teen row of parent home and the "+" in teen detail (they open this form).
**Idempotency key:** generate it when the form opens, not per tap, and send it on every attempt. Two kinds of failure, two behaviours:
- **Rejected (422 or any 4xx):** nothing was created. The fields stay editable; the first edit generates a **new** key (the server rejects a changed payload under an old key).
- **Ambiguous (timeout, network error, 5xx):** the task may exist. The fields lock and the main action becomes **"Try again"**, which resends the **same** key and the identical payload. Editing needs an explicit step first: an "Edit details" action with a short warning that the first attempt may already have gone through (editing unlocks the fields and generates a new key, so a duplicate becomes possible). This is a deliberate speed bump.
Tests: each validation; the amount parser; one tap creates exactly one request; server errors land on the right field; deadline default; the header is always present; after a 422 an edit produces a new key; after a timeout/network/5xx the main action is "Try again" with the same key and the fields are locked; "Edit details" unlocks and the next send uses a new key.
Commit: `feat(parent): create task and milestone`.

## P5. Parent task and milestone detail
Detail screens, cancel with confirm, milestone detail with children and "add task to this milestone".
Tests: cancel only offered in the right states; confirm required; list refreshes after cancel.
Commit: `feat(parent): task and milestone detail with cancel`.

## P6. Parent review ("To check")
List of `SUBMITTED`, review screen, proofs (`image` via `Image.network` with the presigned URL, **no disk cache**, loading and failed states; on a load failure refetch the proofs once, since the URL expires after 10 minutes, and only then show "Try again"; text proof as text). The list refetches on resume and on tab select, and the tab badge follows it., Approve / Redo / Reject with their notes.
Tests: a failed image triggers exactly one proofs refetch; actions call the right endpoint; 409 `invalid_transition` and `concurrent_modification` show a plain "This task just changed. Here is the latest." and reload; double-tap sends once.
Commit: `feat(parent): review submitted tasks`.

## P7. Teen home
`dashboard.dart` models (+ tests), `GET /dashboard` controller, screen per 1.2, remove `TeenHomePlaceholder`. Show **available** amount in the badge, not balance. "Waiting for check" is a small chip under the coin. Chores are grouped under their milestone by `milestoneId`, which is **optional** in the model: when it is missing, chores show ungrouped. The teen has **no bottom navigation** (remove `TeenShell` and the Progress, Goals and Activity branches; Home is a plain route). Refetch on resume. Cards are display-only until P8 adds the detail screens. Parent home rows open the teen detail (P3).
Tests: renders balance, pending chip hidden at 0, chores and milestones, grouping by `milestoneId`, ungrouped fallback when the field is missing or the milestone is absent, empty state, error + retry, no navigation bar, refetch on resume.
Commit: `feat(teen): home dashboard`.

## P8. Teen task detail, milestone screen and submit proof
Task detail per 1.2, and the **teen milestone screen** from 1.2 (steps listed, each opens its task; "Submit milestone" enabled only when all steps are `APPROVED`, otherwise disabled with the reason; the rule is a pure function). Home cards become tappable.
`flutter pub add image_picker flutter_image_compress`. Photo: **always re-encode to JPEG on the phone** with `flutter_image_compress` (quality ~85, longest side 2048, EXIF not kept), whatever the source format; **never reject HEIF/WebP** (or any image the picker returns) for its type. The size check (≤ 5 MB) runs **after** encoding; if the result is still too big, re-encode once at a lower quality, then show a plain message. If the file cannot be decoded at all, say so plainly. Idempotency key generated when the sheet opens and reused for retries of the same attempt. Text proof ≤ 2000 with a counter.
Tests: key reuse; a HEIC/WebP/PNG input is sent as `image/jpeg`; the size guard applies to the encoded bytes; text limit; state changes to submitted; error mapping (`deadline_passed`, `unsupported_proof`, `invalid_transition`); milestone submit disabled until all steps are approved, with the reason shown, enabled after.
Commit: `feat(teen): task detail and proof submission`.

## P9. Hardening pass
Extend `test/app/layout_test.dart` to every new screen (including the teen milestone screen and the badge) in ru/kk at 360×640 and 1.3×. Semantics for the chips, rows and actions. Empty, loading and error states each have a test. Fix what you find by wrapping or scrolling, never by shrinking fonts.
Commit: `test: layout and states for phase-1 screens`.

---

# Part 3 — Backend requests this UX will want (don't build now)

Each has a fallback so Phase 1 needs no backend work.

| # | Request | Why | Fallback used now |
|---|---|---|---|
| B1 | **Required `Idempotency-Key` on `POST /tasks` (prerequisite for P4).** Keys live in a generic table owned by the backend `platform` module (`platform.idempotency_keys`), scoped per user (any role), with the operation name, a request fingerprint, the id of the created entity and an expiry (default 24 h, cleaned by a platform `Ticker`). Task creation is its first user; goals, task-series and payouts can adopt it later. Rationale and rejected alternatives: **ADR-0001**, `/Users/medettegistay/Projects/tiyn/docs/adr/0001-platform-idempotency-for-api-requests.md`. A replay with the same fingerprint returns the original task and publishes no event; a different payload is 422 `invalid_idempotency_key`. | A retry after a bad connection creates a duplicate task. | None; P4 waits for it. |
| B2 | Teen `balance` and `pendingAmount` per member in `GET /family` for parents | Only if the user answers D1 "yes". | Not shown. |
| B3 | `approvedTasks`/`totalTasks` on milestones in `GET /tasks` | Avoids counting children in the client. | Count by `milestoneId`. |
| B4 | A parent summary (to-check count, open payouts) | Avoids loading lists for the badge. | Two filtered calls, `?state=SUBMITTED` and `?state=ASSIGNED`, grouped client-side. |
| B5 | Ordering and pagination on lists | Lists grow. | Sort in the client. |
| B6 | `milestoneId` on dashboard chores | Lets the teen home group chores under their milestone. | **Built** (see `docs/api.md`). The app still treats it as optional and shows chores ungrouped when it is missing, until it is on staging. |

---

## Definition of done
- [ ] The plan commit plus 9 step commits; analyze, format and all tests green; codegen and l10n produce no diff.
- [ ] Two-phone run on staging: new parent and new teen → link → create a task → submit a photo → approve → teen sees the balance rise. Written up in the final report, noting each step checked by hand.
- [ ] Every new screen has loading, empty and error states and passes the 360×640 / 1.3× check in ru and kk.

## Out of scope (don't do)
Goals, payouts, recurring tasks, push notifications (lists refetch on foreground and tab select instead), unlinking, profile or account deletion, wallet history, offline cache, pagination, parent-side balances (unless D1 changes), the Progress, Goals and Activity tabs (hidden in Phase 1: the teen has Home only and no nav bar, the parent has Home and To check), any backend change, any visual redesign of the sign-in or join screens.
