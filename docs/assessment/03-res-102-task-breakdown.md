# RES-102 — Task Breakdown and Method Comparison

## Working Scope

Minimum scope: leaving My orders with an active countdown must not trigger `setState() called after dispose()`.

Working assumption for planning: any disposal path of `PickupCountdown` should release its own periodic work. The documented back-navigation flow remains the mandatory acceptance test. If the scope is later limited to back navigation, the extra regression cases remain useful protection rather than a change in product behavior.

## Definition of Done

1. The original failure is captured in a focused baseline test.
2. The selected solution stops periodic callbacks after a countdown is disposed.
3. A mounted countdown keeps updating its visible remaining time.
4. Single and multiple countdown instances can be disposed without framework errors or pending timers.
5. The existing test suite and static analysis pass with Flutter 3.27.0.
6. The diagnosis, rejected alternative, edge cases, and evidence are ready for the final `solutions.md`.

## Work Plan

| ID | Task | Output | Depends on |
| --- | --- | --- | --- |
| T1 | Record the current baseline failure. | Saved test command, error, stack trace, and pending-timer evidence. | Complete |
| T2 | Compare reproduction and regression-test approaches. | Focused widget test selected; manual app run retained as a smoke check. | Complete |
| T3 | Write the focused regression test before changing production code. | Baseline failed with the intended framework error and pending timers. | Complete |
| T4 | Compare implementation approaches. | Widget-state timer cancellation selected. | Complete |
| T5 | Implement the smallest selected change. | Timer cancellation and a default production clock seam. | Complete |
| T6 | Verify behavior and regressions. | Focused tests, suite, analyzer, and Simulator launch passed; manual Orders interaction pending. | Complete with limitation |
| T7 | Document the final diagnosis and commit. | `solutions.md` is updated; ticket commit pending. | In progress |

## T2 — Compare Reproduction and Regression-Test Approaches

| Option | How it works | Strengths | Limits | Decision criteria |
| --- | --- | --- | --- | --- |
| A. Manual app run | Open My orders, leave it, and inspect the debug console. | Tests the real route and user flow. | Slow, timing-sensitive, and difficult to make deterministic. | Use as final confirmation, not the primary regression test. |
| B. Focused widget test | Mount `PickupCountdown`, remove it from the tree, advance fake time. | Fast, deterministic, directly tests the failing lifecycle boundary. | Does not exercise GetX routing or network loading. | Preferred regression-test candidate. |
| C. Route-level widget test | Build OrdersScreen with controlled dependencies, load orders, then pop the route. | Covers the actual screen composition. | More setup and can obscure the timer defect behind repository/GetX setup. | Use only if the focused test cannot represent the failure. |
| D. Integration test | Drive the installed app through My orders and back navigation. | Highest fidelity. | Slower and less deterministic; device automation required. | Optional final evidence, not required for a narrow widget lifecycle bug. |

### T2 Comparison Task

1. Confirm that option B reproduces the framework error and pending timer on the current revision.
2. Confirm that `WidgetTester.pump(Duration)` advances fake time under Flutter 3.27.0.
3. Choose option B if it captures the acceptance-critical failure without route setup.
4. Retain option A as a manual smoke check after the fix.

**Result:** Option B reproduced one and three disposed countdown failures deterministically, so it was selected. A route-pop widget test was also added to cover the navigation lifecycle without adding an integration-test dependency.

## T3 — Regression Test Design

### Required assertions

1. Mount a countdown with a future pickup time.
2. Advance fake time while mounted and verify that its displayed countdown changes.
3. Remove it from the widget tree.
4. Advance fake time by one periodic interval.
5. Verify no framework exception and no pending timer after the eventual fix.
6. Repeat the disposal sequence for multiple countdowns.

### Test-design options

| Option | Description | Trade-off |
| --- | --- | --- |
| Assert `tester.takeException()` | Explicitly reads the latest framework exception. | Precise for the pre-fix baseline; post-fix tests must also ensure no timer remains pending. |
| Let Flutter test fail naturally | Rely on framework exception and pending-timer invariant. | Simple but less targeted diagnostic output. |
| Inject a clock/ticker abstraction | Test countdown values without real `DateTime.now()` or timers. | Stronger long-term design, but broader than the lifecycle fix. |

### T3 Comparison Task

**Result:** The framework’s normal failure and pending-timer invariant provided the baseline failure. Direct `DateTime.now()` prevented a deterministic visible-text assertion, so a narrow injected clock was added with `DateTime.now` as its production default. A real-time wait was rejected as timing-sensitive.

## T4 — Compare Implementation Approaches

| Option | Mechanism | Stops callbacks? | Releases resource? | Scope / risk | Initial assessment |
| --- | --- | ---: | ---: | --- | --- |
| A. Store the `Timer` in widget state and cancel it in `dispose()`. | The creator retains the timer and stops it at terminal widget lifecycle. | Yes | Yes | Small, aligned with ownership. | Strong candidate. |
| B. Check `mounted` before `setState()`. | Skip `setState` if the widget has been disposed. | No | No | Small change but leaves periodic work alive. | Insufficient on its own. |
| C. Cancel inside the callback when pickup opens. | Stop ticking after the terminal countdown state. | Only after pickup opens | Only after pickup opens | Does not cover early navigation away. | Optional behavior, not a RES-102 fix alone. |
| D. Move ticking to `OrdersController`. | One controller-owned ticker updates all countdowns. | Potentially | Potentially | Changes ownership, affects every tile and controller lifecycle. | Too broad for this ticket. |
| E. Shared app-level ticker/service. | One global time source drives multiple countdowns. | Potentially | Potentially | Could help F-1 later, but introduces global lifecycle and performance design. | Out of scope. |

### T4 Comparison Task

Evaluate each option against these non-negotiable criteria:

1. No callback after the disposed owner’s lifecycle ends.
2. No retained periodic timer after disposal.
3. Countdown still updates while mounted.
4. Independent behavior for multiple countdowns.
5. No change to protected backend/data files.
6. Minimal surface area and a regression test that proves the result.

Select an option only after T3 exists. If option A meets every criterion, reject B–E with the table’s evidence instead of combining approaches without a need.

**Result:** Option A met every criterion and was implemented. B only hides `setState`; C misses early navigation; D and E widen ownership beyond RES-102.

## Pre-Execution TDD and Readiness Checklists

### TDD Checklist

- [x] Acceptance criterion: no callback, framework error, or pending timer after countdown disposal.
- [x] Test level: focused widget test, plus a route-pop widget test.
- [x] Deterministic inputs: `WidgetTester.pump(Duration)` for timer ticks and an injected clock for visible countdown time.
- [x] Red baseline: one and three countdown tests failed with `setState() called after dispose()` and pending timers.
- [x] Failure signal: stack trace pointed to `PickupCountdown`’s periodic callback, not test setup.
- [x] Green assertions: mounted label changes; single disposal, multiple disposal, and route pop finish without exceptions or pending timers.

### Execution Readiness Checklist

- [x] Root cause: uncancelled timer created by widget state was reproduced and traced.
- [x] Constraints: Flutter 3.27.0; no changes to simulated backend or asset data.
- [x] Approaches compared: widget-owned cancellation, `mounted` guard, terminal-time cancellation, controller ticker, and shared ticker.
- [x] Decision recorded: cancel the state-owned timer in `dispose()`; reject alternatives for the documented reasons.
- [x] Edge cases planned: mounted updates, one/multiple disposal, route removal, and app backgrounding boundary.
- [x] Expected files and checks listed: countdown widget, focused test, analyzer, full suite, diff check, and manual route smoke flow.
- [x] Commit scope: one RES-102 lifecycle fix with its regression tests and documentation.

## Chosen Implementation — Execution Tasks

These are the concrete tasks after selecting widget-owned timer cancellation. They are intentionally separate from the comparison tasks above.

| ID | Implementation task | Why it exists | Completion evidence | Status |
| --- | --- | --- | --- | --- |
| I1 | Add an optional clock dependency that defaults to `DateTime.now`. | The countdown display needs a controllable source of time in widget tests. | A mounted-countdown test advances the injected clock and observes a new label. | Complete |
| I2 | Keep the `Timer.periodic` reference in `_PickupCountdownState`. | The state cannot cancel a timer it does not retain. | The timer is stored in a private state field. | Complete |
| I3 | Cancel the retained timer in `dispose()` before `super.dispose()`. | Stop future callbacks when the state’s lifecycle ends. | Single-disposal test has no framework error or pending timer. | Complete |
| I4 | Preserve normal mounted behavior. | The lifecycle fix must not turn the countdown into static text. | Controlled-clock widget test confirms the displayed remaining time changes after one tick. | Complete |
| I5 | Cover independent timer ownership for multiple tiles. | Each active order creates its own countdown and timer. | Three-countdown disposal test passes without errors or pending timers. | Complete |
| I6 | Cover route removal. | The ticket’s reported trigger is leaving My orders. | Route push/pop test passes after a tick. | Complete |
| I7 | Run focused tests, analyzer, full suite, and diff check. | Confirm the change is isolated and does not regress existing behavior. | 4 focused tests, 5 full-suite tests, analyzer, and diff check pass. | Complete |

## T5 — Implementation Choices

| Work item | Options | Selection rule |
| --- | --- | --- |
| Timer reference shape | Nullable `Timer?` field; or a `late final Timer` field. | Prefer the shape that safely represents lifecycle creation and disposal with the least state complexity. |
| Disposal order | Cancel before `super.dispose()`; or after it. | Follow Flutter’s guidance that cleanup occurs in `dispose()` and `super.dispose()` ends the override. |
| Terminal pickup behavior | Continue idle ticking; or cancel after “Pickup window is open”. | Do not change this behavior in RES-102 unless it is required to pass the lifecycle test. Record it as a later optimization decision. |

## T6 — Verification Matrix

| Check | Method | Expected result |
| --- | --- | --- |
| Baseline regression test | `flutter test test/<res102_test>.dart` | Fails before the production change. |
| Mounted behavior | Focused widget test with fake time | Visible remaining-time text changes after one tick. |
| Single disposal | Focused widget test | No framework exception and no pending timer. |
| Multiple disposal | Focused widget test | No error and no pending timers for all instances. |
| Manual route smoke check | My orders → back → wait two seconds | No debug error. |
| Static analysis | `flutter analyze` | No issues. |
| Regression suite | `flutter test` | All tests pass. |
| Diff scope | `git diff --check` and review | No protected files or unrelated changes. |

**Result:** Single disposal, multiple disposal, route pop, and visible mounted countdown tests passed (4 focused tests). `flutter test` passed 5 tests, `flutter analyze` reported no issues, and `git diff --check` passed. The fixed app launched on iPhone 17 Pro Simulator. Manual My orders interaction is pending because the environment has no iOS UI automation.

## T7 — Delivery Evidence

Record the following after verification:

- Reproduction command and pre-fix framework error.
- Chosen implementation and why it owns the timer correctly.
- Rejected `mounted`-only approach and why it leaves periodic work alive.
- Single/multiple countdown test results.
- Manual route smoke-check result.
- Analyzer and full test-suite results.

**Recorded in:** [`solutions.md`](../../solutions.md).
