# F-3 — Stock Reservations: Scope

## Requested outcome

Make bag changes reserve deal stock through the existing reservation API while
keeping the interface responsive. A successful hold lasts five minutes. The
bag must show time remaining, release or adjust holds when quantity changes,
submit reservation ids at checkout, and present a clear recovery path for a
410 expired reservation.

The expiry behavior during an active session or checkout is deliberately
underspecified. It requires an explicit product decision, implementation, and
justification in `solutions.md` after evidence and option comparison.

## Constraints

- Use Flutter 3.27.0 and Java 17; do not upgrade Flutter or packages.
- Do not modify `lib/service/fake_api_service.dart` or any file in
  `assets/data/`.
- Preserve the existing GetX dependency and route structure unless evidence
  supports a scoped change.
- Use the existing `OrderRepo.reserve`, `releaseReservation`, and checkout
  contract; do not add a backend.
- Preserve unrelated iOS and DevTools working-tree changes.
- Keep UI feedback understandable and technical errors in `LogService`.
- Make time, repository behavior, and asynchronous completion controllable in
  tests where a deterministic seam is needed.

## In scope

- Optimistic add-to-bag reservation and failure rollback.
- Reservation identity, quantity, and expiry state on each cart line.
- Reservation countdown rendering and expiry behavior selected during design.
- Release or adjustment when a cart line is removed or its quantity changes.
- Checkout reservation-id forwarding and 410 expired-reservation recovery.
- Unit, widget, and relevant integration/manual verification of reservation
  lifecycle behavior.

## Out of scope

- Backend, catalog-data, package, or Flutter-version changes.
- Cross-device reservation persistence beyond the existing backend contract.
- Payment gateway redesign or retry semantics unrelated to reservations.
- F-1 expiration and F-2 impression behavior, except preserving their existing
  cart interactions.

## Workflow state

- Current phase: Phase 6 — E5 reservation feedback, notices, and countdown
  placement complete.
- Next phase: Phase 6 — execute E6 only: checkout validation and 410 recovery.
- No F-3 diagnosis, implementation decision, test, production-code change, or
  runtime reservation claim has been made.
