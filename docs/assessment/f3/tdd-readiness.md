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
