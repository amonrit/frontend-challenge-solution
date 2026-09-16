# RES-106 — Execution Task Breakdown

The selected design is a centralized Bangkok market-time seam while retaining
UTC instants internally. Tasks are intentionally small and will be executed one
at a time after the user advances the workflow.

| ID | Purpose | Files | Dependency | Acceptance assertion | Variants | Status |
| --- | --- | --- | --- | --- | --- | --- |
| C1 | Compare the concrete conversion seam before coding | `lib/model/pickup_window_model.dart`, possible utility file | Phase 3 decision | Fixed UTC+7 arithmetic, IANA package, or injected offset each have an explicit cost/correctness rationale | Fixed offset (selected); IANA package; model-local conversion | Complete in `options.md` |
| T1 | Add a pure Bangkok conversion/date seam and injectable clock | `lib/service/bangkok_time_policy.dart`, `test/bangkok_time_policy_test.dart` | C1 | Tests can supply a fixed `now` and project any UTC instant into Bangkok date/time | Utility class; function callbacks; model-owned helpers | Complete |
| T2 | Apply the seam to pickup labels and `isToday` | `lib/model/pickup_window_model.dart`, `test/res_106_pickup_window_test.dart` | T1 | RED label and same-day-number regression tests turn GREEN; year/month/day all participate | Convert in getters; precompute projections | Complete |
| T3 | Add midnight, month-end, year-end, and device-timezone tests | `test/res_106_pickup_window_test.dart`, `lib/service/bangkok_time_policy.dart`, `lib/model/pickup_window_model.dart` | T1, T2 | Fixed-clock tests cover Bangkok date boundaries and remain deterministic | Table-driven cases; separate named tests | Complete |
| T4 | Audit time-dependent consumers and preserve instant semantics | `lib/feature/home/`, model call sites, focused tests | T2 | Home filter and pickup consumers use the centralized policy; `isOpenNow`/`untilStart` do not regress | Model-only API; explicit consumer helper | Next |
| T5 | Run verification and collect before/after evidence | `docs/assessment/106/`, `solutions.md` | T3, T4 | Focused tests, full suite, analyzer, diff check, and evidence all pass and are recorded | Local commands; simulator smoke check if needed | Pending |

## Execution rules

- Only one `T*` task is executed per workflow turn.
- T1 and T2 preserve the RED-first order: change the smallest seam needed,
  then make the existing assertions GREEN.
- T3 is a comparison task for test organization only; it does not broaden the
  production design.
- T5 is the final verification task; documentation currency is audited in
  Phase 8 after verification.

## Protected files

- `lib/service/fake_api_service.dart`
- Everything under `assets/data/`
- Unrelated working-tree changes such as `ios/Podfile.lock`
