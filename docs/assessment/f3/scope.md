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

- Current phase: optional manual acceptance evidence in progress after the
  Phase 8 documentation currency audit.
- Android-emulator profile evidence confirms one successful first add:
  Chef's Thai Bundle logged `POST /reservations dealId=2 qty=1`, and its cart
  line displayed `Reservation expires in 02:37`.
- The same run confirmed a successful increment: quantity displayed 2, the
  countdown refreshed to `04:38`, and the log recorded
  `POST /reservations dealId=2 qty=2` before `DELETE /reservations/res_1`.
- A first decrement received the configured 409 and visibly retained quantity
  2 and total ฿252. A retry replaced its hold successfully; removing the final
  unit rendered an empty bag and logged `DELETE /reservations/res_3`.
- A subsequent successful checkout logged `POST /checkout items=1`, followed by
  `DELETE /reservations/res_4`, and rendered an empty bag. Its log does not
  reveal the request body, so reservation-id forwarding remains proven by test.
- A fresh hold visibly counted down `03:06` → `01:49` → `00:36` without a
  device-clock change. After real expiry it rendered an empty bag and logged
  `DELETE /reservations/res_5` at 06:18:25.
- A separate near-expiry checkout attempt reached client-side expiry first:
  `res_6` was released at 06:26:28, the bag became empty, and the UI stated
  that the reservation expired. This correct guard prevents a normal manual
  410 submission; the injected controller test covers 410 recovery.
- Next evidence: comparable DevTools rebuild evidence. The collected paths do
  not measure countdown performance.
