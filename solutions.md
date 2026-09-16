# Rescu Assessment Solutions

This is the delivery summary. Investigation questions, research, and task comparisons are kept in [`docs/assessment/`](docs/assessment/) so this file stays focused on completed work and evidence.

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

### Edge Cases and Evidence

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

For the complete requirement questions, evidence, research, and method comparison, see:

- [Assessment scope](docs/assessment/00-assessment-scope.md)
- [RES-102 questions](docs/assessment/01-res-102-questions.md)
- [RES-102 evidence-backed answers](docs/assessment/02-res-102-answers.md)
- [RES-102 task and option comparison](docs/assessment/03-res-102-task-breakdown.md)

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

### Fix and decision

The controller now stores the `Worker` returned by `ever(...)` and disposes it
in `onClose()` before calling `super.onClose()`. This gives the subscription
the same owner and lifetime as the controller that created it.

A mounted/closed guard was rejected because it leaves the subscription alive.
Moving availability refresh to a shared cart-level service was rejected because
it changes ownership and scope beyond this ticket.

### Verification and limits

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

Detailed questions and evidence are kept in:

- [RES-103 scope](docs/assessment/04-res-103-scope.md)
- [RES-103 questions](docs/assessment/05-res-103-questions.md)
- [RES-103 evidence-backed answers](docs/assessment/06-res-103-answers.md)
- [RES-103 options and decision](docs/assessment/07-res-103-options.md)
- [RES-103 TDD readiness and RED evidence](docs/assessment/08-res-103-tdd-readiness.md)
- [RES-103 execution tasks](docs/assessment/09-res-103-execution-tasks.md)

## RES-101 — Search result ordering

Source inspection shows that every keystroke starts an independent search, and
each completion writes to the same `results` and `isLoading` state. No value
identifies the latest query, so completion order can determine what the user
sees. Runtime logs confirmed that an older query can complete after the final
query; the manually observed sequence had identical empty-result states, so a
deterministic controller test supplied the visible overwrite proof.

The selected design is a monotonic request generation in the controller. Every
input change, including clearing the field, invalidates older requests. Query
text comparison was rejected because identical text can belong to different
requests; debounce was rejected as a correctness mechanism because it cannot
invalidate an already-started response.

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

- [RES-101 scope](docs/assessment/10-res-101-scope.md)
- [RES-101 questions](docs/assessment/11-res-101-questions.md)
- [RES-101 evidence-backed answers](docs/assessment/12-res-101-answers.md)
- [RES-101 options and decision](docs/assessment/13-res-101-options.md)
- [RES-101 TDD readiness and RED evidence](docs/assessment/14-res-101-tdd-readiness.md)
- [RES-101 execution tasks](docs/assessment/15-res-101-execution-tasks.md)

## AI Usage Log

## RES-107 — Deep-link details loading (Phase 2)

Source evidence confirms that the in-app URI becomes the `/deal` route with
query parameters, while normal card navigation additionally supplies a
`DealModel` in `Get.arguments`. The details controller currently force-casts
that optional argument before the screen can render. `DealRepo.fetchById` and
the simulated API already provide ID lookup, latency, and a 404 exception; deal
42 exists in the catalog. The baseline full suite passed 9 tests and analyzer
reported no issues on 2026-09-16. Runtime crash reproduction remains pending
for a later verification phase.

The selected design is controller-owned resolution: preserve a valid
`DealModel` argument, otherwise parse the route ID and fetch through
`DealRepo.fetchById`, with explicit loading and error state. Middleware, async
binding resolution, and screen-owned `FutureBuilder` were rejected because they
broaden route plumbing or split state/data ownership.

The first RED test now reproduces the crash deterministically: with
`Get.arguments == null` and route ID 42, `DealDetailsController.onInit()` throws
`type 'Null' is not a subtype of type 'DealModel' in type cast` before the fake
repository can load the deal.

The execution plan is now split into controller input resolution, async-state
comparison, guarded ID loading, observer safety, screen states, regression
coverage, and final verification. The next executable task is T1; no RES-107
production implementation has started.

T1 now treats `Get.arguments` as a runtime value: a `DealModel` keeps the
existing fast path, while other values leave the controller ready to resolve
the parsed route ID. The forced cast is gone; ID fetching and loading/error
rendering remain the next tasks. The existing details-controller regression
tests continue to pass.

- [RES-107 scope](docs/assessment/16-res-107-scope.md)
- [RES-107 questions](docs/assessment/17-res-107-questions.md)
- [RES-107 evidence-backed answers](docs/assessment/18-res-107-answers.md)
- [RES-107 options and decision](docs/assessment/19-res-107-options.md)
- [RES-107 TDD readiness and RED test](docs/assessment/20-res-107-tdd-readiness.md)
- [RES-107 execution task breakdown](docs/assessment/21-res-107-task-breakdown.md)

| Tool | Use | Verification |
| --- | --- | --- |
| Codex | Repository analysis, test design, implementation, and documentation. | Focused widget tests, full test suite, analyzer, and source review. |
| Flutter and Dart API documentation | Confirmed state disposal, timer cancellation, and fake-time test behavior. | Primary documentation and Flutter 3.27.0 runs. |

### Incorrect or Misleading AI Suggestions

1. **Suggestion:** use `tester.pump(const Duration(seconds: 1))` with the existing `DateTime.now()` code to assert that the displayed countdown changes.
   **Why it was incomplete:** pumping advanced the periodic timer but not the production clock; the text stayed `Opens in 00:59`.
   **How it was caught:** the new widget test failed before any change to countdown behavior.
   **Correction:** inject a clock that defaults to `DateTime.now`, then advance the controlled clock and the periodic tick together.

Add one further real example before submission. Do not invent incidents.

## Design Questions

### Q1. GetxController lifecycle vs. widget State lifecycle

A `GetxController` follows its GetX registration and route binding. A widget `State` follows one widget instance in the Flutter tree. RES-102 is a widget-state lifecycle bug: the timer created by `PickupCountdown` must be released when that state is disposed.

### Q2. When does a large Obx hurt performance?

Pending RES-105 investigation and DevTools evidence.

### Q3. How would RES-106 be tested?

Pending RES-106 investigation.

## Time Spent and One More Day

Update honestly as work progresses.

## DevTools Evidence — RES-105

Pending baseline and after-fix profile measurements.
