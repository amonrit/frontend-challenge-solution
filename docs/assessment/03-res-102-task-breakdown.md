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
| T2 | Compare reproduction and regression-test approaches. | Chosen test level and reason. | T1 |
| T3 | Write the focused regression test before changing production code. | A test that fails on the current implementation for the intended reason. | T2 |
| T4 | Compare implementation approaches. | Decision table and selected approach. | T1, T3 |
| T5 | Implement the smallest selected change. | Production change limited to RES-102 scope. | T4 |
| T6 | Verify behavior and regressions. | Targeted test, full suite, analyzer, and manual route result. | T5 |
| T7 | Document the final diagnosis and commit. | `solutions.md` content and one logical ticket commit. | T6 |

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

**Current evidence:** Option B already reproduced one and three disposed countdown failures deterministically. T2 is ready to select option B once T3 writes the permanent test.

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

Compare the first two assertion styles on the baseline. Choose the style that produces a stable failure message and still fails if a timer survives disposal. Do not introduce a clock/ticker abstraction unless testing the existing widget proves impossible.

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

## T7 — Delivery Evidence

Record the following after verification:

- Reproduction command and pre-fix framework error.
- Chosen implementation and why it owns the timer correctly.
- Rejected `mounted`-only approach and why it leaves periodic work alive.
- Single/multiple countdown test results.
- Manual route smoke-check result.
- Analyzer and full test-suite results.
