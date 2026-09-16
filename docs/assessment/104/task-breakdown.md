# RES-104 — Execution Task Breakdown

Execute one task per user-approved `next`. Comparison tasks are planning gates;
they do not change production code.

| ID | Purpose | Files | Dependency | Acceptance assertion | Variants | Status |
| --- | --- | --- | --- | --- | --- | --- |
| C1 | Compare where request-round identity and page acceptance should live. | `options.md`, `home_controller.dart` | Phase 3 decision | The selected invariant is explicit before implementation. | Controller generation; repository request object; serialized queue | Complete in Phase 3 |
| T1 | Add a generation/round counter and refresh snapshot ownership. | `lib/feature/home/home_controller.dart` | RED test, C1 | Every refresh invalidates earlier page responses; refresh captures its round. | Increment on refresh; immutable load-session object | Complete; RED is GREEN |
| T2 | Guard load-more acceptance and page advancement. | `lib/feature/home/home_controller.dart` | T1 | A page-2 response is appended only for the current round and expected page; `_page` advances only when accepted. | Generation plus expected page; compare response page; both checks | Complete; focused GREEN passed |
| T3 | Keep refresh/load completion state safe for stale callbacks and close. | `lib/feature/home/home_controller.dart` | T1–T2 | Stale/late callbacks cannot mutate feed or disposed controller; refresh indicators complete predictably. | Per-request completion guard; controller closed guard | Next |
| T4 | Expand regression coverage for overlap and failure edges. | `test/home_controller_test.dart` | T1–T3 | Tests cover stale refresh/load-more, repeated refresh, failed stale request, and final page state. | Controller unit tests with delayed repository; widget test only if indicator behavior needs it | Planned |
| T5 | Run before/after measurements and final checks. | `solutions.md`, `docs/assessment/104/`, tests | T4 | Same deterministic completion order shows `[3, 4]` before and `[3]` after; full checks pass. | Focused + full suite; analyzer; diff check; runtime log if available | Planned |

## C1 — Generation placement comparison

| Variant | Correctness | Lifecycle | Performance | Testability | Decision |
| --- | --- | --- | --- | --- | --- |
| Controller generation counter | Directly guards the shared list/page state and fits existing ownership. | No new long-lived object. | Stale network work may finish but cannot mutate UI. | Delayed repository can assert generation/page acceptance. | Selected |
| Repository request object | Encapsulates request metadata but moves UI-round policy into data access. | Extra object lifetime and API surface. | Same network cost. | Requires repository contract changes in tests and production. | Rejected for scope |
| Serialized queue | Prevents overlap by construction. | Queue must be closed and can retain obsolete work. | New refresh may wait behind slow page load. | Timing and queue flushing are harder to assert. | Rejected as primary design |

## Implementation invariant

For every feed response, acceptance must require:

```text
response.round == currentRound
AND response.page == expected page for that round
AND controller is still alive
```

Only an accepted response may replace/append `deals`, update `_page` or
`_totalPages`, and complete its active refresh/load indicator. This invariant is
the basis for the GREEN test and the after measurement.

## Verification sequencing

1. T1–T3 implement the smallest controller change that satisfies the RED test.
2. T4 adds edge coverage without changing the selected invariant.
3. T5 repeats the exact before trace, then runs full automated and relevant
   runtime checks.
