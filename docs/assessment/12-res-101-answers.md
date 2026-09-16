# RES-101 — Evidence-Backed Answers

This document records facts supported by source inspection, read-only test
runs, and the runtime request log.

## Required outcome and current behavior

| Question | Evidence-backed answer | Evidence |
| --- | --- | --- |
| 1.1 | Search results must match the current input after fast typing; an older response must not replace newer results. | `PROBLEM.md`, RES-101. |
| 1.3 | Clearing input currently clears `results` and sets `hasSearched` to false, but it does not identify or invalidate an already-running request. | `search_deals_controller.dart`. |
| 1.4 | `isLoading` is a single shared boolean, so any overlapping request can set it to false even if a newer request has not completed. | `search_deals_controller.dart`. |
| 1.5 | Errors are logged only; an older failed request still reaches the shared `isLoading = false` assignment after the catch. | `search_deals_controller.dart`. |
| 4.5 | The existing Search UI distinguishes prompt, loading, no-results, and list states through `hasSearched`, `isLoading`, and `results`; a fix must preserve those states for the latest query. | `search_screen.dart`. |

## Async ordering and ownership facts

| Question | Evidence-backed answer | Evidence |
| --- | --- | --- |
| 3.1 | Every TextField `onChanged` call invokes `onQueryChanged`, which starts `_search` without awaiting or cancelling an earlier invocation. | `search_screen.dart`; `search_deals_controller.dart`. |
| 3.2 | The controller has no request identifier, latest-query value, generation counter, or cancellation handle. | `search_deals_controller.dart`. |
| 3.4 | `DealRepo.search` delegates to the simulated API and returns only a Future; no cancellation contract is exposed through this repository method. | `deal_repo.dart`. |
| 3.5 | Every overlapping `_search` invocation assigns its own `found` list to the same `results` observable after awaiting. Completion order therefore controls the visible state. | `search_deals_controller.dart`. |
| 3.6 | An older completion can set `isLoading` false while a newer request is still awaiting, because each invocation writes the shared boolean independently. | `search_deals_controller.dart`. |
| 2.2 | The simulated API deliberately makes broader, shorter queries slower: delay is `180 + max(0, 1200 - trimmedLength * 280) + random(0..299)` ms. | `fake_api_service.dart` (read only). |
| 2.4 | A prefix sequence is likely to overlap because each character starts a request and shorter prefixes have longer simulated delays. Runtime reproduction is still required before treating this as observed behavior. | Source timing contract; `PROBLEM.md`. |

## Test and baseline evidence

| Check | Result | Evidence |
| --- | --- | --- |
| Existing full suite | 7 tests passed before RES-101 changes. | `/Users/amonrit/fvm/versions/3.27.0/bin/flutter test`, 2026-09-16. |
| Deterministic test seam | A test `DealRepo` can expose independently completable Futures for each query, allowing a newer response to complete before an older response. | Constructor injection in `SearchDealsController`; `DealRepo.search` API. |
| Expected RED signal | Complete the newer query first, then the older query; current code will assign the older list last. | Source behavior; focused reproduction test not yet written. |

## Runtime evidence still needed

- A manual simulator run confirmed out-of-order completion. During rapid input,
  the final `bakersushi` response logged at `17:23:21.304`, then older
  `baker`, `bakersu`, `bakersus`, and `bakersush` responses logged later. The
  current controller assigns each completion to `results`, so the later older
  response is eligible to overwrite the latest one. The screen showed
  `No deals found` for this particular sequence, so it did not provide a
  visually distinct wrong-result example.
- A deterministic focused test with distinct result lists is still needed to
  prove the visible overwrite without relying on simulated latency.
- Clear-input behavior while an older search remains in flight.
- Search-route closure behavior while a request is in flight.

## Scope decision still needed

Whether to add debounce for request-volume reduction after correctness is fixed.
Debounce cannot be the correctness mechanism because a delayed older response
may still complete after a newer request.
