# Rescu Assessment Solutions

This is the delivery summary. Investigation questions, research, and task comparisons are kept in [`docs/assessment/`](docs/assessment/) so this file stays focused on completed work and evidence. The shared assessment format is documented in [`docs/assessment/README.md`](docs/assessment/README.md).

The rerun baseline/current results and Android route coverage for every
RES-101 to RES-107 ticket are summarized in the
[regression evidence matrix](docs/assessment/regression-matrix.md).

Each completed ticket below follows the same summary format: status, diagnosis
or requirement, fix or implementation, rejected alternatives, verification and
evidence, limitations, and references.

## RES-101 — Search result ordering

**Status:** Complete. Automated and simulator verification passed.

### Diagnosis

Source inspection shows that every keystroke starts an independent search, and
each completion writes to the same `results` and `isLoading` state. No value
identifies the latest query, so completion order can determine what the user
sees. Runtime logs confirmed that an older query can complete after the final
query; the manually observed sequence had identical empty-result states, so a
deterministic controller test supplied the visible overwrite proof.

### Fix

The selected design is a monotonic request generation in the controller. Every
input change, including clearing the field, invalidates older requests. Query
text comparison was rejected because identical text can belong to different
requests; debounce was rejected as a correctness mechanism because it cannot
invalidate an already-started response.

### Verification and evidence

The focused RED test now reproduces the visible overwrite deterministically:
`bakery` completes first, then older `sushi` completes and replaces it in the
current controller. E1 now increments a request generation for every input
event, including clear, and gates post-await result/loading mutations against
the latest generation. The original deterministic test is GREEN: after the
latest `bakery` result arrives, a later completion from the older `sushi`
request is ignored. The clear-input regression is also GREEN: a `sushi`
response completing after the input is cleared cannot restore results,
`hasSearched`, or `isLoading`.

Automated verification on 2026-09-16 passed: the focused RES-101 suite (2
tests), the full suite (9 tests), `flutter analyze`, and `git diff --check`.
The manual E5 comparison also passed on an iPhone 17 Pro simulator. An
AppleScript-driven `sushi` then `bakery` sequence settled on Bakery deals and
did not revert to Sushi; a `sushi` then clear sequence remained in the empty
search state after the former request had time to complete. The deterministic
controller tests remain the primary proof because the fake API timing is not a
stable UI-level oracle.

### Rejected alternatives

Query equality, debounce-only protection, and a stream cancellation refactor
were rejected for the reasons recorded above and in the linked options document.

### Limitations or follow-up

The UI currently logs stale search errors rather than rendering a user-facing
error state; that behavior was outside RES-101. Edge cases covered are late
success after a newer query, late success after clear, and stale loading
ownership. Stale errors are ignored by the same generation gate.

### References

- [RES-101 scope](docs/assessment/101/scope.md)
- [RES-101 questions](docs/assessment/101/questions.md)
- [RES-101 evidence-backed answers](docs/assessment/101/answers.md)
- [RES-101 options and decision](docs/assessment/101/options.md)
- [RES-101 TDD readiness and RED evidence](docs/assessment/101/tdd-readiness.md)
- [RES-101 execution tasks](docs/assessment/101/task-breakdown.md)


## RES-102 — Crash after leaving My orders

**Status:** Complete. Automated verification and manual My orders route smoke test passed.

### Diagnosis

`PickupCountdown` created a periodic timer but never cancelled it. After the widget was removed, the timer retained its callback and called `setState()` on disposed state.

### Fix

The widget state keeps its own timer reference and cancels it in `dispose()` before `super.dispose()`. The widget also accepts a clock that defaults to `DateTime.now`, making its visible countdown deterministic in tests without changing production behavior.

### Rejected Alternatives

- A `mounted` check avoids the exception but leaves the periodic timer alive.
- Cancelling only when pickup opens does not cover leaving My orders earlier.
- Moving time updates to a controller or global service expands this focused widget-lifecycle ticket.

### Testable Time Decision

The first visible-countdown test used `DateTime.now()` directly. `tester.pump(Duration)` fired the periodic callback but did not advance that clock, so the displayed text stayed at `Opens in 00:59`. The test was invalid, not the feature.

| Option | Decision |
| --- | --- |
| Wait for real seconds | Rejected: slow and timing-sensitive. |
| Assert only that a callback occurs | Rejected: does not prove the displayed value changes. |
| Inject a clock that defaults to `DateTime.now` in production | Selected: makes display-time tests deterministic without changing production behavior. |

### Verification and evidence

| Case | Result |
| --- | --- |
| One disposed countdown | Regression test passes without framework error or pending timer. |
| Mounted countdown | Controlled-clock test proves the visible remaining time changes after one tick. |
| Three disposed countdowns | Regression test passes without framework error or pending timers. |
| Countdown route pushed then popped | Route-level widget test passes without framework error or pending timer. |
| Focused tests | `flutter test test/pickup_countdown_test.dart`: 4 passed. |
| Full test suite | `flutter test`: 5 passed. |
| Static analysis | `flutter analyze`: no issues. |
| Fixed app launch | Home screen launched on iPhone 17 Pro Simulator. |
| My orders → back → wait one minute | Passed by user: returned to Home, waited one minute, and observed no crash or post-disposal timer error. |

### Limitations or follow-up

No known RES-102 limitation remains for the documented route-pop scenario.
The focused/full counts in this section are historical measurements from the
RES-102 verification point; the later project-wide suite count is recorded at
the later ticket's measurement point and does not replace this history.

### References

For the complete requirement questions, evidence, research, and method comparison, see:

- [Assessment scope](docs/assessment/assessment-scope.md)
- [RES-102 scope](docs/assessment/102/scope.md)
- [RES-102 questions](docs/assessment/102/questions.md)
- [RES-102 evidence-backed answers](docs/assessment/102/answers.md)
- [RES-102 options and decision](docs/assessment/102/options.md)
- [RES-102 TDD readiness](docs/assessment/102/tdd-readiness.md)
- [RES-102 task and option comparison](docs/assessment/102/task-breakdown.md)


## RES-103 — Requests pile up while browsing

**Status:** Complete for the documented back-navigation flow and a late
availability response after route closure.

### Diagnosis

Every `DealDetailsController` created an `ever(cartService.itemCount, ...)`
observer but discarded its GetX `Worker`. When a detail route closed, that
observer remained subscribed. The next cart change therefore invoked
`fetchById` once for every detail controller opened earlier in the session.

The pre-fix manual reproduction opened deals 1–3 and closed them, then opened
deal 4 and added it to the bag. One cart change logged four requests:
`GET /deals/3`, `/deals/4`, `/deals/2`, and `/deals/1`.

### Fix

The controller now stores the `Worker` returned by `ever(...)` and disposes it
in `onClose()` before calling `super.onClose()`. This gives the subscription
the same owner and lifetime as the controller that created it.

Disposing the Worker stops future callbacks, but it cannot cancel a
`fetchById` future that has already begun. `_recheckAvailability()` therefore
checks `_isClosed` after its `await` and discards a late result. This retains
the small controller-owned lifecycle boundary without adding cancellation
support that the repository API does not expose.

A mounted/closed guard was rejected because it leaves the subscription alive.
Moving availability refresh to a shared cart-level service was rejected because
it changes ownership and scope beyond this ticket.

### Verification and evidence

| Check | Result |
| --- | --- |
| RED controller test | After `onClose()`, a second cart mutation produced a second repository call: expected 1, actual 2. |
| Focused GREEN tests | 4 passed: closed controller stays silent; a separate live controller still refreshes; a late response cannot mutate closed controller state. |
| Historical full suite at original RES-103 fix | 7 passed. |
| Current full suite | 34 passed on 2026-09-17. |
| Static analysis | `flutter analyze`: no issues on 2026-09-17. |
| Manual comparison | After closing deals 1–3, adding deal 4 logged exactly `GET /deals/4`; no request for deals 1–3. |
| Android integration | Passed on the Android emulator: opened the first Home deal and returned to Home three times without a route-lifecycle failure. |
| Late-response before/after | The new deterministic test failed at baseline with `Expected: <5>; Actual: <0>`, then passed after the closed guard was added. |

The integration test validates real app startup and repeated navigation. The
delayed-repository unit test owns the precise late-response assertion; an
end-to-end test alone cannot reliably force that completion order.

### Limitations or follow-up

An in-flight availability request is allowed to finish after route closure,
but its successful result is ignored. The repository has no cancellation API,
so actively aborting transport work remains outside this ticket.

### References

Detailed questions and evidence are kept in:

- [RES-103 scope](docs/assessment/103/scope.md)
- [RES-103 questions](docs/assessment/103/questions.md)
- [RES-103 evidence-backed answers](docs/assessment/103/answers.md)
- [RES-103 options and decision](docs/assessment/103/options.md)
- [RES-103 TDD readiness and RED evidence](docs/assessment/103/tdd-readiness.md)
- [RES-103 execution tasks](docs/assessment/103/task-breakdown.md)
- [RES-103 Android navigation integration test](integration_test/deal_navigation_test.dart)


## RES-104 — Home pagination and refresh consistency

**Status:** Complete. Automated before/after verification passed.

### Requirement
Prevent refresh and pagination responses from overwriting one another or duplicating feed items.

### Diagnosis

Pre-change source evidence identifies shared mutable page/list state across
independent async completions as the bottleneck. A refresh can replace page 1
while an older page-2 request is still allowed to append afterward.

### Implementation

Selected monotonic request-round and page tokens. T1 adds a controller round
counter: each refresh advances the round, and refresh/load-more completions from
older rounds no longer mutate the feed. The remaining expected-page invariant
is now enforced by T2: load-more captures `requestedPage` before awaiting and
advances `_page` only when both round and response page match.

### Rejected alternatives

Serializing all operations was rejected because a slow obsolete request delays
refresh. A stream cancellation refactor was rejected because the repository
returns Futures and cancellation may not stop the backend. ID deduplication
alone was rejected because it cannot restore ordering or identify stale rounds.

### Verification and evidence

Before measurement is recorded in the answers document. T1's after measurement
uses the identical deterministic completion order: the focused test changed
from `[3, 4]` before the guard to `[3]` after the guard.

Phase 4 added a delayed repository test seam. The first run exposed a missing
Flutter binding in the test setup; initializing `TestWidgetsFlutterBinding`
fixed the seam. The intended RED run then produced `Expected: [3], Actual:
[3, 4]`, proving that an older page-2 response is appended after refresh.

T2 repeats the same completion order after the page guard and keeps the focused
GREEN test passing. A response with the wrong page is ignored without changing
the feed or pagination metadata.

### Limitations or follow-up

A separate manual Home overlap run was not claimed; the deterministic injected
repository is the primary race evidence. A production-like request logger could
be added as follow-up evidence if needed.

T3 added lifecycle guards and `finally` cleanup for refresh/load-more. A closed
controller no longer accepts late responses, while only the current request
round completes the shared refresh indicator. The focused suite now includes a
late-refresh-after-close test and passes 2 tests. Failure-edge expansion is
covered by T4.

T4 expands the deterministic suite to 6 tests: overlapping refreshes, stale
load-more failure, wrong response page, final-page no-op, stale append, and
late response after close. All focused tests pass. The same delayed repository
seam was reused for T5's before/after comparison.

T5 reran the identical controlled completion order and recorded the change from
`[3, 4]` before the guard to `[3]` after it. The focused RES-104 suite passed 6
tests, the full project suite passed 19 tests, analyzer reported no issues, and
`git diff --check` passed. A separate manual Home overlap run was not claimed;
the deterministic injected repository is the primary race evidence.

### References

- `PROBLEM.md` RES-104 requirements
- [RES-104 scope](docs/assessment/104/scope.md)
- [RES-104 questions](docs/assessment/104/questions.md)
- [RES-104 evidence-backed answers](docs/assessment/104/answers.md)
- [RES-104 options and trade-offs](docs/assessment/104/options.md)
- [RES-104 TDD readiness](docs/assessment/104/tdd-readiness.md)
- [RES-104 execution tasks](docs/assessment/104/task-breakdown.md)

## RES-105 — Home feed performance

**Status:** Partial. Implementation and Android before/after timeline capture are complete; repeatable physical-device frame and memory evidence remain.

### Requirement
Reduce unnecessary rebuilds and image memory use, with comparable DevTools evidence.

### Diagnosis

Source evidence identifies three candidate contributors: the entire Home screen
is inside one scroll-sensitive `Obx`, the main feed eagerly maps all loaded
deals into a `ListView(children: ...)`, and the shared cached-image wrapper has
no decode-size hints. These are confirmed code facts; frame and memory impact
still require a profile-mode trace.

### Implementation

The selected plan is to split reactive boundaries, use lazy feed construction,
and pass display-sized image decode hints. T1 moved scroll observation into
separate app-bar and FAB `Obx` wrappers; the body observer reads feed state but
does not depend on scroll offset. T2 replaced the main feed's eager
`children + map` with
`ListView.builder`, preserving the flash rail, header/filter, footer, and
existing refresher callbacks. T3 added display-sized `memCacheWidth` and
`memCacheHeight` hints using layout constraints and device pixel ratio, while
leaving unconstrained dimensions unset.

### Rejected alternatives

- A widget-local reactive listener was deferred to keep the existing GetX state
  pattern until measurements justify a broader change.
- A full sliver rewrite was rejected as unnecessary scope and higher refresher
  integration risk.
- Backend or asset resizing was rejected because those files are protected.

### Verification and evidence

The Phase 2 baseline has 28 passing tests, a clean analyzer, and Flutter 3.27.0
with DevTools 2.40.2. Android profile-mode before/after Flutter VM timeline
measurements are now recorded in the profile baseline document. The host-GPU
emulator's raster timing varied substantially across repeat runs, so no
performance improvement is claimed. After T1,
`flutter analyze` passed with no issues and the existing Home controller suite
passed 6 tests. After T2, the same analyzer and Home regression suite passed;
after T3, the image sizing test passed and analyzer reported no issues. T4
compared the source-level before/after behavior and recorded that no Android
profile trace was possible in this environment; runtime performance impact
remains unmeasured. T5 integrated verification on 2026-09-17 passed: image
sizing (1), Home regression (6), full suite (29), analyzer, and diff check.
Follow-up widget coverage now includes both lazy construction and a direct
scroll-rebuild scope test; the full suite is re-run after this change. A Pixel
6 / API 35 emulator ran both revisions in profile mode using host GPU. Its
raster timing varied substantially between repeats, so the capture is evidence
of the comparison method rather than a measured improvement claim.

### Limitations or follow-up
The implementation has before/after timeline data and a physical Android
Perfetto capture, but no analyzed repeatable frame or memory improvement
measurement. The Flutter VM Service was unavailable over wireless debugging,
so DevTools frame and memory views could not be collected. No measured jank,
memory, or image-cache improvement is claimed.
`test/home_feed_list_test.dart` directly verifies lazy construction for a
100-deal feed, while `test/home_screen_rebuild_scope_test.dart` verifies that
scroll state does not rebuild `HomeFeedList`. Image sizing tests and source
review cover the remaining structural changes.

### References

- `PROBLEM.md` RES-105 requirements
- [RES-105 scope](docs/assessment/105/scope.md)
- [RES-105 evidence-backed answers](docs/assessment/105/answers.md)
- [RES-105 options and trade-offs](docs/assessment/105/options.md)
- [RES-105 TDD readiness and RED result](docs/assessment/105/tdd-readiness.md)
- [RES-105 execution task breakdown](docs/assessment/105/task-breakdown.md)
- [RES-105 profile baseline record](docs/assessment/105/profile-baseline.md)

## RES-106 — Pickup time and today filter

**Status:** Implementation complete; verification passed. Documentation audit complete.

### Requirement
Use the required Bangkok timezone and compare complete calendar dates for pickup and today filtering.

### Diagnosis

The API supplies UTC instants, but the model currently formats those instants
directly and derives `isToday` from only the numeric day. That creates a wrong
displayed pickup time and false matches across month or year boundaries. The
device timezone is also an implicit input, so the result can differ from the
Bangkok market date.

### Implementation

The selected approach is a centralized Bangkok market-time conversion seam with
a fixed UTC+7 offset. T1 added `BangkokTimePolicy`, which keeps API values as
UTC instants, projects values into Bangkok time, compares complete market dates,
and accepts an injectable clock. T2 applies the policy to `PickupWindowModel`
label formatting and complete-date `isToday` comparison. Other time-dependent
behavior remains under review in later tasks.

### Rejected alternatives

- An IANA timezone package was deferred because this product currently has one
  fixed-offset market and no daylight-saving or multi-market requirement.
- Storing converted local values in the model was rejected because it blurs the
  distinction between an instant and a wall-clock representation.
- Converting independently in widgets and filters was rejected because policy
  would be duplicated and could drift between screens.

### Verification and evidence

The evidence phase recorded the current direct-UTC label and day-only
comparison, plus a baseline of 19 passing tests and a clean analyzer run. The
new focused RED run failed for the intended reasons: `10:30 – 14:00` instead of
`17:30 – 21:00`, and `isToday == true` for a same-day-number date in the next
month. After implementation, T1's three policy tests, T2's two focused model
tests, and T3's four boundary cases pass. Full verification is recorded below.

### Limitations or follow-up
T3 added fixed-clock coverage for Bangkok midnight, month-end, year-end, and
device-timezone independence. The first run exposed that `isToday` still used
the system clock directly; the model now delegates to the policy's injected
clock, and all six focused RES-106 tests pass. T4 audited card, map, details,
and Home filtering: they read model properties and contain no duplicate
timezone arithmetic. `isOpenNow` and `untilStart` remain instant comparisons
and were left unchanged. T5 verification on 2026-09-17 passed: focused RES-106
tests (6), full Flutter suite (28), analyzer, and `git diff --check`. A later
integration regression test covers the Home `Pickup today` filter with a fixed
Bangkok clock; the Home suite now passes 7 tests and the full suite passes 30.
Manual runtime display measurement was not performed; the recorded evidence is
unit and source based.

### References

- `PROBLEM.md` RES-106 requirements
- [RES-106 scope](docs/assessment/106/scope.md)
- [RES-106 questions](docs/assessment/106/questions.md)
- [RES-106 evidence-backed answers](docs/assessment/106/answers.md)
- [RES-106 options and trade-offs](docs/assessment/106/options.md)
- [RES-106 TDD readiness and RED result](docs/assessment/106/tdd-readiness.md)
- [RES-106 execution task breakdown](docs/assessment/106/task-breakdown.md)

## RES-107 — Deep-link details loading (Complete)

**Status:** Complete. Automated verification and iPhone Simulator deep-link
verification passed.

### Diagnosis

Source evidence confirms that the in-app URI becomes the `/deal` route with
query parameters, while normal card navigation additionally supplies a
`DealModel` in `Get.arguments`. The details controller currently force-casts
that optional argument before the screen can render. `DealRepo.fetchById` and
the simulated API already provide ID lookup, latency, and a 404 exception; deal
42 exists in the catalog. The baseline full suite passed 9 tests and analyzer
reported no issues on 2026-09-16. Final verification later passed 13 tests and
included a real simulator deep-link flow.

### Fix

The selected design is controller-owned resolution: preserve a valid
`DealModel` argument, otherwise parse the route ID and fetch through
`DealRepo.fetchById`, with explicit loading and error state. Middleware, async
binding resolution, and screen-owned `FutureBuilder` were rejected because they
broaden route plumbing or split state/data ownership.

### Verification and evidence

The first RED test now reproduces the crash deterministically: with
`Get.arguments == null` and route ID 42, `DealDetailsController.onInit()` throws
`type 'Null' is not a subtype of type 'DealModel' in type cast` before the fake
repository can load the deal.

The execution plan was split into controller input resolution, async-state
comparison, guarded ID loading, observer safety, screen states, regression
coverage, and final verification. All listed execution tasks are complete.

T1 treated `Get.arguments` as a runtime value: a `DealModel` keeps the existing
fast path, while other values resolve the parsed route ID. The forced cast was
removed.

C2 selected separate GetX observables for nullable loaded deal, loading, and a
user-facing error message. This keeps the existing architecture and makes the
screen's loading/loaded/error branches explicit; a new sealed async abstraction
or screen-owned `FutureBuilder` would add ownership and lifecycle complexity.

T2 implements the controller loading boundary. It reads the route ID from GetX
parameters and falls back to the current route query for direct deep-link entry.
A valid ID sets `isLoading`, calls `DealRepo.fetchById`, and reuses the
loaded-deal initialization path. Missing or invalid IDs and repository errors
become retryable `errorMessage` state instead of cast or async exceptions. A
closed-controller guard prevents late responses from mutating disposed state.
The focused deep-link and controller regression tests passed at that stage
(3 tests); later T5 expanded the final focused suite to 6 tests.

T3 keeps the normal card-navigation fast path: a supplied `DealModel` is used
immediately and does not trigger an initial repository fetch. The cart `ever`
worker is created only after a loaded deal exists, and any previous worker is
disposed before re-initialization to prevent duplicate availability requests.
The controller close and multi-controller regression tests remain green; the
focused controller/deep-link suite passed 4 tests at that stage and 6 after T5.

T4 updates `DealDetailsScreen` to observe loading, error, and loaded state
before reading the controller's deal. Direct links therefore show a progress
indicator while fetching, invalid or failed links show a retryable message, and
normal model navigation keeps the existing details layout. Retry remains
controller-owned so the screen does not perform repository work. Focused
controller/deep-link checks pass. Dedicated widget rendering tests remain a
follow-up limitation; the runtime simulator check covers the loaded page.

T5 adds regression coverage for valid route ID loading, normal model arguments,
invalid IDs, repository failures, and observer cleanup. The focused suite now
passes 6 tests. Failure coverage verifies that loading ends with no exposed deal
and a retryable user-facing message; full analyzer and runtime verification are
reserved for T6.

T6 completed the initial checks: the full Flutter suite passed 13 tests,
analyzer reported no issues, and `git diff --check` passed. On an iPhone 17 Pro
Simulator, opening `rescu://open/deal?id=42&source=push` reached the details
page for “Mystery Japanese Basket”, matching catalog deal 42. The runtime
screenshot is stored at `docs/assessment/107/evidence/res-107-deal-42-runtime.png`.

Later Android verification established that an `adb shell` command must escape
`&` for the device shell. With `\&source=push`, a cold start on Pixel 6 / API
35 loaded deal 42 and logged `deal_details_view` with `source: push`. While
adding coverage for routes where GetX parameters are unavailable, a RED
regression test found that `id` had a current-URI fallback but `source` did
not. The controller now uses one helper for both values. The full integrated
suite subsequently passed 32 tests.

### Rejected alternatives

Middleware resolution, async binding resolution, and screen-owned
`FutureBuilder` were rejected because they broaden route plumbing or split
repository and state ownership.

### Limitations or follow-up

Dedicated widget tests for loading/error rendering and repeated deep-link
navigation remain follow-up coverage. The controller paths and both iPhone and
Android deal-42 flows are verified.

### References

- [RES-107 scope](docs/assessment/107/scope.md)
- [RES-107 questions](docs/assessment/107/questions.md)
- [RES-107 evidence-backed answers](docs/assessment/107/answers.md)
- [RES-107 options and decision](docs/assessment/107/options.md)
- [RES-107 TDD readiness and RED test](docs/assessment/107/tdd-readiness.md)
- [RES-107 execution task breakdown](docs/assessment/107/task-breakdown.md)


## F-1 — Live flash-sale countdowns

**Status:** Not started in this submission.

### Requirement
Display live countdowns, expiration behavior, and cart removal for expired flash-sale deals.

### Rejected alternatives

No approach was selected because implementation was not started.

### Verification and evidence

No implementation or performance evidence was produced for this feature.

### Limitations or follow-up
No implementation or performance evidence was produced for this feature.

### References

- `PROBLEM.md` F-1 requirements

## F-2 — Deal impression tracking

**Status:** Not started in this submission.

### Requirement
Track qualifying card visibility with session deduplication and batched analytics delivery.

### Rejected alternatives

No approach was selected because implementation was not started.

### Verification and evidence

No implementation or analytics evidence was produced for this feature.

### Limitations or follow-up
No implementation or analytics evidence was produced for this feature.

### References

- `PROBLEM.md` F-2 requirements

## F-3 — Stock reservations

**Status:** Not started in this submission.

### Requirement
Reserve stock optimistically when adding to cart and release or expire reservations safely.

### Rejected alternatives

No approach was selected because implementation was not started.

### Verification and evidence

No implementation or reservation evidence was produced for this feature.

### Limitations or follow-up
No implementation or reservation evidence was produced for this feature.

### References

- `PROBLEM.md` F-3 requirements

## AI Usage Log

I used AI as a reasoning and implementation assistant, while keeping evidence
and final decisions under my control. Each proposed diagnosis was checked
against source code, a deterministic test, or a simulator run before it was
accepted.

| Tool | Use | Verification |
| --- | --- | --- |
| Codex | Inspected source, formed hypotheses, proposed alternatives, wrote focused tests, implementation changes, and assessment documentation. | Every accepted change was checked against source, a RED/GREEN test, runtime observation, or a review of the diff. |
| Git worktrees | Re-ran each RES-101 to RES-107 RED test against its historical pre-fix commit without changing `main`. | The resulting baseline failures and current GREEN results are recorded in the [regression evidence matrix](docs/assessment/regression-matrix.md). |
| Flutter 3.27.0 and Dart CLI | Ran focused/current suites, analyzer, formatter, and Android integration tests using the pinned toolchain. | Current unit/widget suite: 34 passed; analyzer: no issues; Android regression suite: 7 passed. |
| Android emulator and Flutter integration binding | Exercised startup, bindings, routing, fake API wiring, countdown disposal, Home filtering, and simulated deep-link flow. | `integration_test/res_101_107_smoke_test.dart` passed seven independently launched ticket flows. |

### Incorrect or Misleading AI Suggestions

1. **Suggestion:** use `tester.pump(const Duration(seconds: 1))` with the existing `DateTime.now()` code to assert that the displayed countdown changes.
   **Why it was incomplete:** pumping advanced the periodic timer but not the production clock; the text stayed `Opens in 00:59`.
   **How it was caught:** the new widget test failed before any change to countdown behavior.
   **Correction:** inject a clock that defaults to `DateTime.now`, then advance the controlled clock and the periodic tick together.

2. **Suggestion:** rely on `Get.parameters['id']` alone in the controller test
   seam after assigning `Get.rootController.routing.current`.
   **Why it was misleading:** the focused test showed that this direct routing
   setup left `Get.parameters['id']` null, so the valid deep-link case became an
   invalid-ID state.
   **How it was caught:** the RED-to-GREEN test still had `requestedId == null`
   after the first implementation.
   **Correction:** keep GetX parameters as the production path and add a
   current-route query fallback for direct deep-link entry and deterministic
   tests.

3. **Suggestion:** treat a route-level integration test as the main proof for
   the RES-101, RES-103, or RES-104 race condition.
   **Why it was misleading:** real fake-API timing can vary, so an integration
   pass does not guarantee that an old request completed after a newer one.
   **How it was caught:** controlled `Completer` tests reproduced the exact
   stale order deterministically, while the Android flow only verified that
   routes and wiring work together.
   **Correction:** retain Android integration tests as complementary coverage;
   use controller tests with controlled futures as the acceptance proof for
   ordering and lifecycle races.

4. **Suggestion:** interpret one Android-emulator timeline run as a before/after
   performance result for RES-105.
   **Why it was misleading:** the AVD's rendering configuration and raster
   timing were not repeatable enough to make a causal frame-time or memory
   claim.
   **How it was caught:** repeated captures changed materially under the same
   scripted flow.
   **Correction:** document the traces and their limitation, keep widget tests
   for rebuild/lazy-construction mechanisms, and reserve a performance claim
   for a repeatable physical-device measurement.

## Design Questions

### Q1. GetxController lifecycle vs. widget State lifecycle

A `GetxController` follows its GetX registration and route binding. A widget `State` follows one widget instance in the Flutter tree. RES-102 is a widget-state lifecycle bug: the timer created by `PickupCountdown` must be released when that state is disposed.

### Q2. When does a large Obx hurt performance?

A large `Obx` rebuilds every descendant that depends on the same observable
set, so a high-frequency value such as scroll offset can refresh stable feed
cards, images, and controls unnecessarily. Scope each observer around the
smallest subtree that reads the changing value: RES-105 keeps scroll-dependent
app-bar/FAB observers separate from the feed observer. The exact frame-time
benefit remains unmeasured without a comparable profile device.

### Q3. How would RES-106 be tested?

Parse fixed UTC instants, inject a fixed Bangkok clock, and assert labels and
complete year/month/day comparisons across midnight, month-end, and year-end.
RES-106 added `BangkokTimePolicy` so tests do not depend on the host timezone or
wall clock; its focused boundary suite passes.

## Time Spent and One More Day

Approximately **18–22 hours of active work** were spent across source review,
baseline capture, TDD planning, implementation for RES-101 to RES-107,
historical RED reruns in isolated worktrees, focused/full verification, Android
integration testing, and documentation. This excludes waiting for emulator
boot, Gradle builds, dependency resolution, and review pauses.

With one additional day, I would first capture repeatable before/after DevTools
traces on a physical mid-range Android device for RES-105. I would then finish
F-1 end to end: one shared ticker for countdown text, expiration-driven cart
removal, focused tests for 100+ countdowns, and an Android integration flow.
Only after that proof is complete would I start F-2 or F-3.

## DevTools Evidence — RES-105

Android profile-mode before/after timeline traces were captured on a Pixel 6 /
API 35 AVD using host GPU. The reproducibility contract and both results are
recorded in [profile-baseline.md](docs/assessment/105/profile-baseline.md).
The AVD's raster timing was not repeatable enough to claim an improvement; a
physical mid-range Android repeat with memory/image-cache evidence remains the
final performance follow-up.
