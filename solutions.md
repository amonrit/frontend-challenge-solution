# Rescu Assessment Solutions

This is the delivery summary. Investigation questions, research, and task comparisons are kept in [`docs/assessment/`](docs/assessment/) so this file stays focused on completed work and evidence.

## RES-102 — Crash after leaving My orders

**Status:** Automated verification complete. The fixed app launches on the iPhone Simulator; a manual My orders route smoke check remains pending because this environment has no iOS UI automation.

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
| My orders → back → wait | Pending manual smoke check. |

For the complete requirement questions, evidence, research, and method comparison, see:

- [Assessment scope](docs/assessment/00-assessment-scope.md)
- [RES-102 questions](docs/assessment/01-res-102-questions.md)
- [RES-102 evidence-backed answers](docs/assessment/02-res-102-answers.md)
- [RES-102 task and option comparison](docs/assessment/03-res-102-task-breakdown.md)

## AI Usage Log

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
