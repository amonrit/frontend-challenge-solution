# RES-103 — Execution Tasks

These tasks follow the selected controller-owned Worker cleanup design. Execute
only one task per user-approved `next`.

| ID | Task | Files | Dependency | Acceptance assertion | Status |
| --- | --- | --- | --- | --- | --- |
| E1 | Retain the Worker created by `ever(...)` and release it in the controller lifecycle hook. | `lib/feature/deal/deal_details_controller.dart` | RED test in `test/deal_details_controller_test.dart` | After `onClose()`, a cart change does not increment `fetchByIdCalls`. | Complete; GREEN verification pending E2 |
| E2 | Run and record the focused GREEN test after E1. | `test/deal_details_controller_test.dart`, assessment evidence | E1 | `flutter test test/deal_details_controller_test.dart` passes. | Complete: 1 passed |
| E3 | Add a multi-controller regression test. | `test/deal_details_controller_test.dart` | E2 | Closing controller A does not stop live controller B; cart change fetches only B. | Complete: 2 focused tests passed |
| E4 | Run targeted and project verification. | tests, `solutions.md` | E3 | Focused test, full suite, analyzer, and diff check pass. | Complete: focused 2, full 7, analyzer clean |
| E5 | Repeat the manual request-count flow. | `solutions.md`, assessment evidence | E4 | After deals 1–3 close and deal 4 adds to bag, only `GET /deals/4` appears. | Complete: only `/deals/4` logged |

## E1 implementation variants

| Variant | How it works | Decision |
| --- | --- | --- |
| Nullable `Worker?` field | Assign the `ever(...)` result in `onInit()`, call `?.dispose()` in `onClose()`, then call `super.onClose()`. | Selected: represents lifecycle state safely and keeps the owner explicit. |
| `late final Worker` field | Assign exactly once in `onInit()`, dispose in `onClose()`. | Viable, but it makes partially initialized controller tests and future error paths less flexible. |
| Call `ever(...)` with a self-disposing callback | Dispose only after the first cart change. | Rejected: it breaks live availability refresh after subsequent cart changes. |

## E3 test variants

| Variant | How it works | Decision |
| --- | --- | --- |
| Two real controllers with two counting repositories | Create A and B, close A, mutate cart, assert only B fetches. | Selected: exercises separate Worker ownership directly. |
| Inspect a Worker `disposed` property | Expose or reflect the Worker for test inspection. | Rejected: couples the test to private implementation detail instead of user-visible request behavior. |
| Route-level widget test only | Push/pop GetX detail routes and inspect calls. | Useful verification follow-up, but slower and harder to isolate than the focused controller test. |

## E4 verification commands

```sh
/Users/amonrit/fvm/versions/3.27.0/bin/flutter test test/deal_details_controller_test.dart
/Users/amonrit/fvm/versions/3.27.0/bin/flutter test
/Users/amonrit/fvm/versions/3.27.0/bin/flutter analyze
git diff --check
```

## Stop conditions

- If E1 does not make the focused test GREEN, inspect the Worker lifecycle and
  test seam before trying a different implementation.
- If E3 fails, do not weaken the assertion; determine whether cleanup
  accidentally affects a live controller.
- If manual verification still logs a request for a closed deal, return to the
  lifecycle evidence rather than masking the callback.

## E4 results

| Check | Result |
| --- | --- |
| Focused controller test | 2 passed |
| Full project suite | 7 passed |
| Static analysis | No issues found |
| Diff check | Passed; `ios/Podfile.lock` remains an unrelated uncommitted user change and was not included in RES-103 commits. |

## E5 manual result

On the fixed app, deals 1, 2, and 3 were opened and closed. Deal 4 remained
open and **Add to bag** was tapped. The log contained exactly:

```text
re-checking availability for deal 4
GET /deals/4
```

No refresh callback or request was logged for deals 1–3. This is the intended
contrast with the pre-fix run, where the same cart change produced four
requests for deals 1–4.
