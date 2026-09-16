# RES-106 — Evidence-Backed Answers

This phase records pre-change facts from source, catalog/API contract, and
baseline commands. No RES-106 production code or regression test has been
added yet.

## API contract and current behavior

| Question | Evidence-backed answer | Evidence |
| --- | --- | --- |
| 2.2 | `DateTime.parse` preserves the UTC instant when the API string ends in `Z`; the model test confirms `pickupWindow.start.isUtc == true`. | `lib/model/pickup_window_model.dart`; `test/model_test.dart` |
| 3.1 | The simulated market is Asia/Bangkok at UTC+7, and the fake API converts market wall-clock hours to UTC strings before returning them. | `lib/service/fake_api_service.dart` (read-only) |
| 3.3 | Pickup formatting is performed directly by `PickupWindowModel.label`; cards, map, and details screen all consume model-derived values. | `pickup_window_model.dart`; `deal_card.dart`; `map_screen.dart`; `deal_details_screen.dart` |
| 3.4 | `isToday`, `isOpenNow`, and `untilStart` call `DateTime.now()` directly and do not receive an injected clock or timezone policy. | `pickup_window_model.dart` |
| 3.5 | Home's Pickup today filter delegates to `deal.pickupWindow.isToday`. | `lib/feature/home/home_controller.dart` |
| 4.1 | The current `label` formats the parsed instant's fields as `HH:mm` without converting it to Bangkok local time. | `pickup_window_model.dart` |
| 4.2 | The current `isToday` compares only `start.day` with the device-local `DateTime.now().day`; month and year are ignored. | `pickup_window_model.dart` |
| 4.3 | The current `isOpenNow` compares device-local `DateTime.now()` with the parsed start/end values, so the comparison domain is implicit rather than an explicit market timezone. | `pickup_window_model.dart` |

## Before measurement

### Deterministic UTC conversion trace

For an API value such as `2026-01-01T10:30:00.000Z`, the current model keeps
the UTC wall-clock fields and `label` displays `10:30`. The Bangkok market
instant is `17:30` on the same local date (UTC+7), so the expected display is
`17:30`. This is a source-derived calculation before any code change.

### Date-filter boundary trace

If `start` is `2026-01-15T17:00:00.000Z` and the device-local `now` is on
`2026-02-15`, the current `isToday` comparison sees equal day numbers (`15`)
and returns true even though the month differs. The same issue applies across
years. A fixed-clock test must compare the complete Bangkok calendar date.

## Baseline commands

| Check | Before result | Command |
| --- | --- | --- |
| Full test suite | 19 tests passed | `/Users/amonrit/fvm/versions/3.27.0/bin/flutter test` |
| Static analysis | No issues | `/Users/amonrit/fvm/versions/3.27.0/bin/flutter analyze` |
| RES-106 focused regression | Not available; no test exists before Phase 4 | `test/res_106_pickup_window_test.dart` |
| Runtime display/filter measurement | Not run manually | Unit evidence uses the deterministic policy seam |

## Protected files and unresolved questions

- `lib/service/fake_api_service.dart` and `assets/data/` remain read-only.
- The dependency list contains `intl` but no timezone database package; the
  allowed implementation choices need to account for that constraint.
- The device timezone at evidence collection was `+07`, but this does not prove
  behavior on devices configured to another timezone.
- Invalid/missing timestamps and historical timezone-rule changes are not
  represented in the current catalog and require an explicit decision in the
  options phase.

## Follow-up evidence resolved

1. The options phase compared fixed UTC+7, IANA timezone, model normalization,
   and widget-level conversion; fixed UTC+7 was selected for the current
   Bangkok-only scope.
2. `BangkokTimePolicy` provides the fixed-clock seam, with tests for normal
   conversion, midnight, month-end, year-end, and local-timezone independence.
3. The focused suite passes after implementation; no manual runtime claim is
   made because a separate runtime measurement was not performed.
