# RES-102 — TDD Readiness

## Acceptance criteria

- A mounted countdown updates its visible remaining time every second.
- Disposing one or multiple countdowns prevents framework errors and pending
  periodic timers on later ticks.
- Removing the Orders route leaves no countdown callback owned by removed
  widgets.

## Deterministic test seam

- Use `WidgetTester.pump(Duration)` to advance periodic timer ticks.
- Inject a clock for visible countdown text; direct `DateTime.now()` does not
  advance when fake time is pumped.

## RED and GREEN signals

- RED: `setState() called after dispose()` and pending periodic-timer errors
  after a disposed widget is pumped.
- GREEN: mounted text changes; one, three, and route-pop disposal tests finish
  without framework exceptions or pending timers.

## Files and checks

- Production: `lib/feature/order/widget/pickup_countdown.dart`
- Tests: `test/pickup_countdown_test.dart`
- Command: `/Users/amonrit/fvm/versions/3.27.0/bin/flutter test test/pickup_countdown_test.dart`
- Protected: `lib/service/fake_api_service.dart`, `assets/data/`

## Result

The RED reproduction and GREEN regression tests are documented in `answers.md`
and `task-breakdown.md`; the focused suite passed 4 tests.
