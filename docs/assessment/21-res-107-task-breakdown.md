# RES-107 — Execution Task Breakdown

Execute one task per user-approved `next`. Comparison tasks are planning gates;
they do not change production code.

| ID | Task | Files | Dependency | Acceptance assertion | Status |
| --- | --- | --- | --- | --- | --- |
| C1 | Compare route-resolution ownership and record the selected controller path. | `19-res-107-options.md` | Phase 3 | The chosen owner and rejected alternatives are explicit. | Complete in Phase 3 |
| T1 | Make details input model-or-ID aware without a forced cast. | `lib/feature/deal/deal_details_controller.dart` | RED test | A model argument remains valid; a missing argument proceeds to ID resolution. | Complete; controller regression check passed |
| C2 | Compare async state representations for loading, loaded, and error. | `21-res-107-task-breakdown.md`, `solutions.md` | T1 design | Select a state shape that keeps screen rendering and lifecycle ownership clear. | Complete; separate Rx state selected |
| T2 | Implement ID parsing and guarded repository loading. | `lib/feature/deal/deal_details_controller.dart` | T1, C2 | Valid ID 42 calls `fetchById`; invalid/missing input and failures become state, not crashes. | Complete; focused deep-link and controller tests passed |
| T3 | Preserve the model-argument fast path and initialize dependent observers safely. | `lib/feature/deal/deal_details_controller.dart` | T2 | Card navigation does not make an unnecessary initial fetch; cart observer starts only with a loaded model. | Next |
| T4 | Render loading and error states while retaining the existing loaded page. | `lib/feature/deal/deal_details_screen.dart` | T2 | Deep link shows loading, then details or an understandable retryable error. | Blocked by T2 |
| T5 | Add regression coverage for valid ID, normal argument, invalid ID, and failure paths. | `test/deal_details_deep_link_test.dart`, `test/deal_details_controller_test.dart` | T2–T4 | Focused tests prove all acceptance paths and no late state mutation after close. | Blocked by T2–T4 |
| T6 | Run project checks and manual deep-link verification. | tests, `solutions.md`, assessment evidence | T5 | Focused/full tests, analyzer, diff check, and deal-42 simulator flow pass. | Blocked by T5 |

## C1 — Route-resolution alternatives

| Option | Summary | Decision |
| --- | --- | --- |
| Controller resolver | Controller accepts a model argument or loads by route ID. | Selected: smallest change aligned with current ownership. |
| Route middleware | Middleware asynchronously resolves and rewrites route arguments. | Rejected: broad route plumbing and unclear loading lifecycle. |
| Binding/factory resolver | Binding creates an async resolver/controller combination. | Rejected: adds an abstraction to a simple dependency registration point. |
| Screen `FutureBuilder` | Screen parses route and owns the fetch. | Rejected: moves data access into UI and splits state ownership. |

## C2 — Async-state alternatives

| Option | Summary | Decision |
| --- | --- | --- |
| Separate Rx state | `Rxn<DealModel>`, `isLoading`, and `errorMessage` are owned by the controller. | Selected: matches existing GetX observables and keeps screen branches explicit. |
| Single sealed async state | One `AsyncState<DealModel>` value represents loading/data/error. | Rejected for this scope: introduces a new abstraction not used elsewhere. |
| `FutureBuilder` state | A Future is passed to the screen and rendered there. | Rejected: duplicates route/data ownership and complicates controller cleanup. |

## C2 decision details

Use three controller-owned pieces of state: nullable loaded deal, boolean
`isLoading`, and nullable user-facing `errorMessage`. The intended transitions
are:

```text
route input → loading → loaded(deal)
                  └──→ error(message)
```

The model-argument fast path starts directly at `loaded`. A valid ID starts at
`loading`; invalid input can enter `error` without a repository call. A retry
clears the previous error and returns to `loading`. The controller owns these
transitions so the screen only renders state and does not own repository work.

## T1 implementation variants

| Option | Summary | Decision |
| --- | --- | --- |
| Nullable model plus route resolver | Replace the forced cast with a nullable model and resolve the ID in the controller lifecycle. | Selected path; preserves the current model argument fast path. |
| Always fetch by ID | Ignore any supplied model and fetch for every route. | Rejected: adds latency and changes existing card behavior. |
| Require middleware-normalized arguments | Keep the cast and guarantee middleware always injects a model. | Rejected: deep-link failures remain coupled to route plumbing. |

## Verification sequencing

1. T1 removes the cast boundary while retaining normal arguments.
2. C2 confirms the observable state contract before T2.
3. T2–T4 implement loading, failure, and loaded rendering in dependency order.
4. T5 expands the focused regression suite only after the implementation is
   green for the original RED case.
5. T6 performs final automated and runtime checks without changing the API or
   protected files.

## T2 implementation evidence

- Parsed `id` from GetX parameters, with a fallback to the current route query
  for direct deep-link entry points.
- Valid IDs enter `isLoading`, call `DealRepo.fetchById`, and initialize the
  loaded deal through the existing setup path.
- Missing or non-numeric IDs set an error state without a repository call;
  repository failures are logged and mapped to the same retryable state.
- Completion and error updates are guarded after `onClose` so a late response
  cannot mutate a disposed controller.
- Focused deep-link and controller tests passed (3 tests).
