# F-2 — Deal Impression Tracking: Execution Task Breakdown

The selected design is delivered in small steps so that qualification,
deduplication, delivery, and rendering remain independently reviewable.

| ID | Purpose | Files | Dependency | Acceptance assertion | Variants | Status |
| --- | --- | --- | --- | --- | --- | --- |
| C1 | Compare observation, timer, and batch ownership | `options.md` | Phase 2 evidence | App-scoped analytics ownership with detector wrappers and shared deadlines is selected | Widget timer; route controller; manual geometry; app service | Complete |
| E1 | Add deterministic visibility qualification | `AnalyticsService`, `analytics_service_impression_test.dart` | Initial RED | An observation at `>=0.5` produces no event before one second and exactly one required event at the controlled deadline | Service-owned deadline timer; test-only explicit due check | Complete — initial qualification RED is GREEN |
| E2 | Add cancellation and session deduplication | `AnalyticsService`, focused service tests | E1 | Below-threshold, disposal, and repeated/cross-source callbacks cannot emit; first qualifying source/position for a deal is retained once | Remove observation API; generation token; map replacement | **Next executable task** |
| E3 | Add FIFO batch ownership and delivery | `AnalyticsService`, sender/timer tests | E1, E2 | Exactly one batch sends at ten events or first-unsent +15 seconds; events arriving in flight remain for the next send | Inline sender; injected sender interface; retry queue | Pending |
| E4 | Define delivery failure, pause, and disposal behavior | `AnalyticsService`, lifecycle/failure tests | E3 | Failed batch is retained and retries once on the controlled delay; pause clears only qualification intervals; service disposal releases all timers | Retry immediately; bounded delay; drop after log | Pending |
| E5 | Add reusable detector wrapper and source/position call sites | New shared tracker widget, `DealCard`, Home feed, flash rail, Search, widget tests | E1, E2 | Each surface forwards its required source/position with a unique observation key; wrapper disposal ends observation without rebuilding its parent list | Wrap cards directly; adapter per surface; sliver detector | Pending |
| E6 | Make delivery state observable if needed | `AnalyticsService`, Analytics debug screen, widget/service tests | E3, E4 | Debug output can distinguish locally recorded events from pending/in-flight/failed delivery without changing required event payload | Keep existing list only; add summary state; add delivery log | Pending |
| E7 | Run final functional and performance verification | F-2 docs, integration test, profile evidence | E1–E6 | Targeted/full tests, analyzer, cross-screen flow, batch threshold checks, and comparable profile evidence meet acceptance criteria | Android emulator functional flow; physical-device DevTools profile run | Pending |

## Execution safeguards

1. `AnalyticsService` remains the sole app-session owner for deduplication and
   queue state; widgets must not call the batch sender.
2. A detector key identifies one rendered observation, while deduplication uses
   only deal id. Keys must include source and stable list position/identity.
3. E1–E4 inject time, timers, and sender behavior; no test depends on real
   one- or fifteen-second waits.
4. E5 wraps only cards and must not introduce an `Obx` around a scrollable list
   or a repeating timer per card.
5. E7 records profile claims only from comparable profile-mode measurements.

## Protected files

- `lib/service/fake_api_service.dart`
- Everything under `assets/data/`
- Unrelated iOS, lockfile, and DevTools working-tree changes
