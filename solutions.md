# Rescu Assessment Solutions

This is the delivery summary. Investigation questions, research, and task comparisons are kept in [`docs/assessment/`](docs/assessment/) so this file stays focused on completed work and evidence. The shared assessment format is documented in [`docs/assessment/README.md`](docs/assessment/README.md).

## Work order

The work was completed in this order. Documentation and verification were
updated alongside each ticket rather than after all implementation work.

1. Baseline checks, repository workflow, and assessment documentation setup.
2. **RES-102** — cancel the pickup countdown timer on widget disposal.
3. **RES-103** — dispose the detail controller's cart observer.
4. **RES-101** — ignore stale search responses with request generations.
5. **RES-107** — resolve deep links by ID and render loading/error states.
6. **RES-104, RES-105, RES-106, F-1, F-2, F-3** — not started in this
   submission; retained as follow-up work from the assignment.

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
error state; that behavior was outside RES-101.

**Final diagnosis:** independent Futures shared the same observable state, so
completion order could override input order. **Fix:** each input event advances
an integer generation; only the matching latest generation may mutate
post-await state. **Rejected alternatives:** query equality fails for repeated
identical input; debounce does not invalidate work already in flight; a
cancellable stream refactor exceeds the existing Future-based repository
contract. **Edge cases covered:** late success after a newer query, late
success after clear, and stale loading ownership. Stale errors are also ignored
by the same generation gate, though the UI currently logs errors rather than
rendering an error state.

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

### References

For the complete requirement questions, evidence, research, and method comparison, see:

- [Assessment scope](docs/assessment/assessment-scope.md)
- [RES-102 questions](docs/assessment/102/questions.md)
- [RES-102 evidence-backed answers](docs/assessment/102/answers.md)
- [RES-102 task and option comparison](docs/assessment/102/task-breakdown.md)


## RES-103 — Requests pile up while browsing

**Status:** Complete for the documented back-navigation flow.

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

A mounted/closed guard was rejected because it leaves the subscription alive.
Moving availability refresh to a shared cart-level service was rejected because
it changes ownership and scope beyond this ticket.

### Verification and evidence

| Check | Result |
| --- | --- |
| RED controller test | After `onClose()`, a second cart mutation produced a second repository call: expected 1, actual 2. |
| Focused GREEN tests | 2 passed: closed controller stays silent; a separate live controller still refreshes. |
| Full suite | 7 passed. |
| Static analysis | `flutter analyze`: no issues. |
| Manual comparison | After closing deals 1–3, adding deal 4 logged exactly `GET /deals/4`; no request for deals 1–3. |

The fix prevents future callbacks after cleanup. It does not cancel an
availability request that began before `onClose()`; no runtime evidence showed
that an in-flight response caused a visible error, so cancellation was kept out
of this focused ticket.

### Limitations or follow-up

An in-flight availability request is allowed to finish after route closure;
cancelling that request was outside the ticket and was not observed to cause a
user-visible error.

### References

Detailed questions and evidence are kept in:

- [RES-103 scope](docs/assessment/103/scope.md)
- [RES-103 questions](docs/assessment/103/questions.md)
- [RES-103 evidence-backed answers](docs/assessment/103/answers.md)
- [RES-103 options and decision](docs/assessment/103/options.md)
- [RES-103 TDD readiness and RED evidence](docs/assessment/103/tdd-readiness.md)
- [RES-103 execution tasks](docs/assessment/103/task-breakdown.md)


## RES-104 — Home pagination and refresh consistency

**Status:** Assessment complete; implementation not started.

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

Full before/after and runtime checks remain for T5.

T3 adds lifecycle guards and `finally` cleanup for refresh/load-more. A closed
controller no longer accepts late responses, while only the current request
round completes the shared refresh indicator. The focused suite now includes a
late-refresh-after-close test and passes 2 tests. Failure-edge expansion is
covered by T4; full before/after checks remain for T5.

T4 expands the deterministic suite to 6 tests: overlapping refreshes, stale
load-more failure, wrong response page, final-page no-op, stale append, and
late response after close. All focused tests pass. The same delayed repository
seam will be reused for T5's before/after comparison.

### References

- `PROBLEM.md` RES-104 requirements
- [RES-104 scope](docs/assessment/104/scope.md)
- [RES-104 questions](docs/assessment/104/questions.md)
- [RES-104 evidence-backed answers](docs/assessment/104/answers.md)
- [RES-104 options and trade-offs](docs/assessment/104/options.md)
- [RES-104 TDD readiness](docs/assessment/104/tdd-readiness.md)
- [RES-104 execution tasks](docs/assessment/104/task-breakdown.md)

## RES-105 — Home feed performance

**Status:** Not started in this submission.

### Requirement
Reduce unnecessary rebuilds and image memory use, with comparable DevTools evidence.

### Rejected alternatives

No approach was selected because implementation was not started.

### Verification and evidence

No before/after DevTools measurements were produced for this ticket.

### Limitations or follow-up
No implementation or before/after DevTools evidence was produced for this ticket.

### References

- `PROBLEM.md` RES-105 requirements

## RES-106 — Pickup time and today filter

**Status:** Not started in this submission.

### Requirement
Use the required Bangkok timezone and compare complete calendar dates for pickup and today filtering.

### Rejected alternatives

No approach was selected because implementation was not started.

### Verification and evidence

No tests or runtime evidence were produced for this ticket.

### Limitations or follow-up
No implementation or evidence was produced for this ticket.

### References

- `PROBLEM.md` RES-106 requirements

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

T6 completed the final checks: the full Flutter suite passed 13 tests, analyzer
reported no issues, and `git diff --check` passed. On an iPhone 17 Pro Simulator,
opening `rescu://open/deal?id=42&source=push` reached the details page for
“Mystery Japanese Basket”, matching catalog deal 42. The runtime screenshot is
stored at `docs/assessment/107/evidence/res-107-deal-42-runtime.png`.

### Rejected alternatives

Middleware resolution, async binding resolution, and screen-owned
`FutureBuilder` were rejected because they broaden route plumbing or split
repository and state ownership.

### Limitations or follow-up

Android intent verification and dedicated widget tests for loading/error
rendering remain follow-up coverage. The controller paths and iPhone Simulator
deal-42 flow are verified.

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
| Codex | Repository analysis, test design, implementation, and documentation. | Focused controller/deep-link tests, full test suite, analyzer, runtime checks, and source review. |
| Flutter 3.27.0 and Dart CLI | Ran focused/full tests, analyzer, and formatter using the pinned toolchain. | 13 full-suite tests passed; analyzer reported no issues. |
| `xcrun simctl` and `cliclick` | Opened the deep link and confirmed the loaded deal on iPhone 17 Pro Simulator. | Runtime screenshot matches catalog deal 42. |

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

## Design Questions

### Q1. GetxController lifecycle vs. widget State lifecycle

A `GetxController` follows its GetX registration and route binding. A widget `State` follows one widget instance in the Flutter tree. RES-102 is a widget-state lifecycle bug: the timer created by `PickupCountdown` must be released when that state is disposed.

### Q2. When does a large Obx hurt performance?

Pending RES-105 investigation and DevTools evidence.

### Q3. How would RES-106 be tested?

Pending RES-106 investigation.

## Time Spent and One More Day

Approximately **5–6 hours of active work** were spent in this submission,
including repository discovery, evidence collection, TDD planning, four ticket
implementations, focused and full verification, simulator validation, and
documentation. The wall-clock window is longer because work was performed in
separate review and testing sessions.

With one additional day, I would finish RES-104 and RES-106 first because they
are correctness and data-consistency risks, then capture the required
before/after DevTools evidence and address RES-105. If time remained, I would
implement F-1 end to end before starting F-2 or F-3, keeping each feature
fully tested rather than leaving several partial implementations.

## DevTools Evidence — RES-105

Pending baseline and after-fix profile measurements.
