# RES-106 — TDD Readiness

## Acceptance criteria

- A UTC pickup instant is displayed in Bangkok market time (UTC+7).
- `isToday` compares year, month, and day in the Bangkok market date.
- Boundary cases remain correct across midnight, month changes, and year changes.

## Test level and deterministic inputs

- Unit tests for `PickupWindowModel`.
- Fixed UTC instant `2026-01-01T10:30:00Z` must display as `17:30` in Bangkok.
- A pickup date with the same numeric day in the following month must not be
  classified as today.
- The implementation task must add an injectable Bangkok clock for fully fixed
  midnight and year-boundary cases; the current RED test records the existing
  day-only defect without changing production code.

## Expected RED signal

The focused test should fail because the current label formats the UTC value as
`10:30 – 14:00`, and `isToday` compares only `start.day`.

## Post-change GREEN assertion

The same focused tests pass with `17:30 – 21:00` and `isToday == false`; added
clock-controlled boundary tests must also pass.

## Edge and failure cases

- UTC timestamps that cross Bangkok midnight.
- Month-end and year-end transitions with the same numeric day.
- `isOpenNow` and `untilStart` must continue comparing instants correctly.
- Device timezone must not change the market-date result.

## Files and commands

- Test: `test/res_106_pickup_window_test.dart`
- Production seam: `lib/service/bangkok_time_policy.dart`, integrated by
  `lib/model/pickup_window_model.dart`.
- Protected: `lib/service/fake_api_service.dart`, `assets/data/`.
- Command: `/Users/amonrit/fvm/versions/3.27.0/bin/flutter test test/res_106_pickup_window_test.dart`

## RED result

Focused run on 2026-09-16 failed as intended, before any production change:

- `formats an API UTC instant in Bangkok market time`: expected
  `17:30 – 21:00`, actual `10:30 – 14:00`.
- `isToday compares the complete calendar date`: expected `false`, actual
  `true` for the same numeric day in the following month.

T3 added four fixed-clock boundary tests. The initial run correctly exposed the
missing model clock delegation; after that targeted correction, all six
`res_106_pickup_window_test.dart` tests pass.
