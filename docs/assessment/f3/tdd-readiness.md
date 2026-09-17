# F-3 — Stock Reservations: TDD Readiness

## Acceptance criteria

1. Add creates a visible cart line immediately, requests a reservation, and
   retains the line with its returned hold only when the request succeeds.
2. A 409 reserve failure rolls back exactly the optimistic mutation that made
   the request, recounts the bag, and leads to a clear user-facing notice.
3. A delayed result from an invalidated operation cannot restore a removed,
   expired, or superseded line.
4. A quantity replacement reserves the new quantity before releasing the prior
   reservation; failure preserves the previously confirmed quantity and hold.
5. Every confirmed line shows remaining time from the server `expiresAt`;
   expiry removes the line, stops its checkout eligibility, and does not cause
   a per-line periodic timer or whole-cart rebuild.
6. Remove, replacement, flash-sale expiry, and post-checkout cleanup release
   obsolete holds best-effort without resurrecting local state on failure.
7. Checkout sends confirmed reservation ids, blocks pending/locally expired
   lines, preserves confirmed lines for non-410 failure, and applies the
   selected conservative recovery on 410.

## Deterministic test seam

| Concern | Controlled input | GREEN assertion |
| --- | --- | --- |
| Reserve success/409/delay | Narrow injected `ReservationGateway` with `Completer` results | Optimistic state commits or rolls back only for its current generation |
| Replace/remove race | Controlled old/new reserve completions and release calls | A stale success cannot change a newer or removed line |
| Five-minute expiry | Injected clock backed by the existing app-scoped clock value | One line expires at its server instant without real waiting |
| Checkout 410/502 | Controlled checkout gateway result | 410 follows selected recovery; 502 preserves confirmed lines |
| Countdown render scope | Widget test with controlled clock Rx updates | Countdown text changes without rebuilding the cart list or card shell |

## Initial RED test

`test/cart_reservation_test.dart` begins an add through an injected controlled
reservation gateway. Before its future resolves, it expects the line to be in
the bag. It then completes the reserve with a 409 and expects the exact line
and bag count to roll back.

### Expected RED signal

Before F-3, there is no `ReservationGateway` seam and `CartService` does not
accept one. The test must fail to compile before it can exercise the local-only
cart mutation, proving the selected reservation boundary is absent.

### Recorded RED result

On 2026-09-17, `fvm flutter test test/cart_reservation_test.dart` failed at
compile time for the intended boundary: `reservation_gateway.dart` does not
exist, `ReservationGateway` is not a type, and `CartService` has no
`reservationGateway` named constructor parameter. The current `CartService`
therefore cannot receive a controlled reserve result, so no implementation was
changed to obtain this RED result.

### GREEN assertion

After the first execution task, the same test will show immediate local state,
then an empty cart and zero count after the controlled 409. The test must not
use fake-backend latency, mutation-counter ordering, or a real timer.

### E1 recorded GREEN

`ReservationGateway` now isolates CartService from the concrete repository and
`OrderReservationGateway` adapts it to the existing `OrderRepo`. Production
bootstrap injects that adapter into the permanent CartService. A first add
inserts its line before awaiting `reserve`; a controlled 409 removes that same
line and recounts the bag. The initial RED test is GREEN. On a successful
reserve, the returned hold is attached to the existing line. If that line was
removed while waiting, the late hold is released instead of being reinserted.

On 2026-09-17, the focused F-3/E1 and affected cart/deal command passed 14
tests, and `fvm flutter analyze` reported no issues. Quantity replacement,
full operation-generation coverage, expiry UI, and checkout behavior remain
later tasks; E1 deliberately rejects a second add to the same line rather than
silently increase an unheld quantity.

### E2 recorded existing GREEN

The E2 test starts one optimistic add, removes its line, starts a replacement
add for the same deal, then resolves the first reserve last. It passed without
new production code: E1 already checks the exact `CartItemModel` identity
before attaching a hold and releases a late successful hold for a removed
object. The replacement line remains untouched and receives only its own
reservation. This is a valid existing GREEN result, not evidence that a
generation counter is unnecessary for every mutation. E3 still needs a
per-line generation because replacement changes quantity while retaining the
same line object.

### E3 recorded RED and GREEN

The increment tests were RED against E1: a second add logged that quantity
replacement was unavailable, left quantity at one, and never created a second
controlled reserve request. CartService now makes the requested quantity
optimistic, marks the line pending, reserves the replacement quantity, then
attaches that hold before releasing the prior id. A 409 restores the prior
quantity and hold. Matching decrement and remove-release tests are GREEN.

During E3, a same-line rapid-tap test exposed a second race: with available
stock above two, two replacement requests were started and the test observed
three reserve futures instead of two. CartService now rejects same-line
increment/decrement while a reservation change is pending and keeps a
per-line operation generation for replacement invalidation. The focused
reservation plus flash-expiry command passed 9 tests, and `fvm flutter
analyze` reported no issues on 2026-09-17.

### E4 recorded RED and GREEN

The expiry RED failed because neither `ReservationCountdown` nor
`reservationExpiryNotices` existed. CartService now reuses the app-scoped
FlashSaleClockService tick to remove a confirmed line at its server UTC
`expiresAt`, release its hold best-effort, and queue a reservation-expiry
notice. `ReservationCountdown` is a leaf `Obx` over that same clock; it
formats the remaining duration and switches to `Reservation expired` at zero.
The focused reservation, expiry, countdown, and flash-cart command passed 11
tests; analyzer passed. Cart-screen placement and notice presentation remain
E5 work.

## Edge and failure cases

- Existing line increment, a duplicate rapid tap, and a quantity limit.
- Remove, clear, flash expiry, and replacement while reserve is pending.
- Reserve success after invalidation; release failure after local removal.
- UTC expiry boundary, resume after expiry, and a countdown at zero.
- Checkout with missing, pending, expired, unknown, or mismatched local hold.
- Multi-line checkout 410 without a backend-provided failing reservation id.

## Execution boundary

- Protected files: `lib/service/fake_api_service.dart` and `assets/data/`.
- Expected production files: reservation gateway adapter, CartService and cart
  model state, cart/details UI, checkout controller, and focused tests.
- RED command: `fvm flutter test test/cart_reservation_test.dart`.
- Later checks: focused tests, full suite, analyzer, diff check, Cart/Details
  manual flows, and profile-mode countdown/rebuild evidence.
