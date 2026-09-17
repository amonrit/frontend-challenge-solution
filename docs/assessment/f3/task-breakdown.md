# F-3 — Stock Reservations: Execution Task Breakdown

The selected design is split so that an optimistic mutation is made safe before
quantity, expiry, checkout, and UI paths build on it. Each task has its own
acceptance assertion and can be reviewed independently.

| ID | Purpose | Files | Dependency | Acceptance assertion | Variants | Status |
| --- | --- | --- | --- | --- | --- | --- |
| C1 | Compare state ownership, replacement, expiry, and test seams | `options.md` | Phase 2 evidence | CartService ownership, reserve-before-release, explicit expiry removal, and a narrow gateway are selected | Route controller; second service; release-first; auto-re-reserve; fake-backend latency | Complete |
| E1 | Add reservation gateway and optimistic first add | Gateway adapter, CartService, `cart_reservation_test.dart` | Initial RED | Line appears immediately; controlled 409 removes exactly that optimistic line and recounts bag | Gateway interface; inject concrete repo; test-only callback | Complete — RED test GREEN; 14 affected tests and analyzer pass |
| E2 | Prove stale first-add completion safety | Focused race test | E1 | Delayed reserve success after remove and re-add releases its stale hold and cannot change the replacement line | Item identity; generation counter; cancellation token | Complete — existing item-identity guard passes the remove/re-add race test |
| E3 | Replace holds for increment/decrement and release obsolete ids | CartService, gateway, quantity/release tests | E1, E2 | Replacement reserve succeeds before old hold is released; failure retains previous confirmed line; a per-line generation rejects an older replacement completion | Release-first; replacement-first; one hold per increment | Complete — increment/decrement rollback, pending serialization, and remove-release tests pass |
| E4 | Apply reservation expiry and countdown state | CartService, leaf countdown widget, expiry tests | E1, E2 | Server `expiresAt` drives line removal and notice at zero; no timer is created per line | Existing app clock; separate reservation clock; per-line timer | Complete — controlled expiry/release and countdown tests pass using the existing shared clock |
| E5 | Make add and cart controls communicate pending/rollback/expiry state | Details controller, cart screen, notice host, widget tests | E1–E4 | Add feedback is truthful, same-line mutation is serialized, remaining time is visible, and failures use clear language | Snackbar-only; inline line status; controller-local state | Complete — pending/countdown placement and reservation-expiry notice test pass |
| E6 | Validate checkout holds and recover from 410 | Cart controller, CartService, checkout tests | E1–E4 | Pending/expired lines cannot submit; 410 applies the selected conservative recovery; 502 preserves confirmed lines | Targeted invalidation if backend id exists; clear all request lines; automatic re-reserve | Complete — deterministic 410 clear and 502 retain tests pass |
| E7 | Verify rebuild scope and integrated reservation flows | Focused/widget/integration tests, F-3 docs, profile evidence | E1–E6 | Controlled tests cover add/rollback/races/release/expiry/410; profile/manual evidence states exact device and limitations | Emulator functional flow; physical-device DevTools run | Complete — full 75-test suite, analyzer, and diff check pass; Android profile run confirms add, countdown display, replacement-before-release, 409 rollback, release on removal, successful checkout cleanup, and real expiry release; 410/manual performance evidence remains incomplete |

## Execution safeguards

1. The gateway is a narrow client-side abstraction. It delegates to the
   existing `OrderRepo` and never changes the fake backend or asset data.
2. `CartService` owns the operation generation. UI code may request a mutation
   but must not independently commit or roll back a cart line.
3. A release is side-effect cleanup, not a reason to restore a removed line.
4. The existing app clock is the only periodic tick source. Cart-screen list
   state must not read it; only countdown leaves may subscribe.
5. The 410 recovery remains conservative until the backend contract provides a
   failing reservation id.
6. Every task runs its focused tests before any broader suite; no real
   five-minute wait or mutation-counter sequence is accepted as race evidence.

## Protected files

- `lib/service/fake_api_service.dart`
- Everything under `assets/data/`
- Unrelated iOS, lockfile, and DevTools working-tree changes
