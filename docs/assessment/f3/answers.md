# F-3 — Stock Reservations: Evidence-Backed Answers

## Evidence timing

The source findings below record the pre-implementation investigation that
informed the selected design. They remain historical evidence; the delivered
implementation and current verification state are summarized in
[`solutions.md`](../../../solutions.md) and the later records in
[`tdd-readiness.md`](tdd-readiness.md).

## Evidence record

| Questions | Answer supported by evidence | Evidence |
| --- | --- | --- |
| 1–6 | The assignment requires immediate optimistic add feedback followed by rollback and a clear message on reservation failure. It does not define a reserving visual state, per-line interaction locking, the winner of rapid taps, or partial reservation behavior. The current `CartService.add` changes local quantity synchronously and returns `bool`; the details controller immediately shows an "Added to bag" snackbar. | `PROBLEM.md` F-3; `cart_service.dart`; `deal_details_controller.dart` |
| 7, 31 | `CartService` is a permanent app-scoped `GetxService`; `CartController` is route-lazy and therefore cannot own session reservation state. `OrderRepo` is lazy/fenix and currently has no dependency on CartService, so injecting the repo into CartService would not form a direct cycle. | `main.dart`; `cart_binding.dart`; `cart_service.dart`; `order_repo.dart` |
| 8–10 | A cart line has a nullable `reservation` field but no pending-operation identity or state. Current local methods mutate by deal id and have no protection against delayed reservation completion after a remove, decrement, clear, or second add. | `cart_item_model.dart`; `cart_service.dart` |
| 11–13 | The existing flash-sale clock refreshes from wall time on resume. The cart subscribes to it only for flash-sale expiry; its removal path deletes lines without releasing any reservation. The reservation lifecycle during backgrounding and app close is not defined by the assignment or current code. | `flash_sale_clock_service.dart`; `cart_service.dart`; `PROBLEM.md` F-3 |
| 14–18 | `OrderRepo` exposes `reserve(dealId, quantity)` and `releaseReservation(id)` only; there is no adjustment API. A successful reserve returns `id`, `dealId`, `quantity`, and UTC `expiresAt`, with a five-minute server hold. Release removes the id after simulated latency and has no specified failure path. Checkout does not remove reservation records after success in the fake backend. The required release/re-reserve and clear policy remains a client design choice. | `order_repo.dart`; `reservation_model.dart`; read-only `fake_api_service.dart:124–161, 164–216` |
| 19 | The cart screen leaves increment/decrement enabled while checkout is in progress; only its Checkout button is disabled. Current checkout snapshots `cartService.items.toList()` and clears the cart after a success, so line mutation during the request is possible today. | `cart_screen.dart`; `cart_controller.dart` |
| 20–26 | `expiresAt` is an ISO-8601 UTC instant from the backend. `ReservationModel.isExpired` compares it with `DateTime.now().toUtc()`, which is not injectable. Checkout returns 410 for unknown or expired supplied reservation ids; it does so on the first failing item and its message does not identify a cart line. A 502 may occur before reservation validation. The assignment explicitly delegates the in-app/mid-checkout expiry behavior to the candidate, so removal/retry/re-reserve and checkout guards are not yet selected. | `reservation_model.dart`; read-only `fake_api_service.dart:164–187`; `PROBLEM.md` F-3 |
| 27–28 | Reserve has 350–1100 ms simulated latency, increments the shared mutation counter, and returns 409 on every third mutation attempt or when requested quantity exceeds catalog stock. Checkout has 500–1400 ms latency and returns 502 on the same periodic counter condition. It validates a supplied reservation id exists and is unexpired, but the shown backend does not validate that its deal id or quantity matches the checkout item. Checkout decreases catalog quantity and creates an order after validation. | read-only `fake_api_service.dart:124–216` |
| 29–30 | The model already carries one optional reservation per cart line. Current add, decrement, remove, clear, flash-expiry, details add, cart-screen increment/decrement, and checkout use local-only cart APIs, with checkout merely forwarding the nullable id. | `cart_item_model.dart`; `cart_service.dart`; `deal_details_controller.dart`; `cart_screen.dart`; `cart_controller.dart`; `order_repo.dart` |
| 32 | `LogService` is already used for cart rejections and checkout failures; the cart has an Rx line list/count and flash-expiry notices, but it has no reservation or error-state observability. | `cart_service.dart`; `cart_controller.dart`; `log_service.dart` |
| 33–36 | The flash-sale clock already offers injectable `now` and periodic timer construction, and existing cart tests use it with a controlled clock. Repository behavior is concrete `OrderRepo` today; it has no interface/fake seam. Existing focused cart tests cover flash expiry and bootstrap only, so reservation races, rollback, expiry, and checkout status still require new deterministic seams and tests. | `flash_sale_clock_service.dart`; `cart_flash_expiry_test.dart`; `app_dependencies_test.dart`; `order_repo.dart` |
| 37–38 | No reservation flow or performance measurement exists yet. The assignment requires rollback, release/adjustment, expiry, and 410 verification; it also requires each bag line to show remaining time. Any countdown performance claim must therefore wait for the selected design and comparable profile-mode evidence. | `PROBLEM.md` F-3; current `test/` and `integration_test/` inventory |

## Safe baseline check

On 2026-09-17, `fvm flutter test test/cart_flash_expiry_test.dart
test/app_dependencies_test.dart` passed all 3 tests. This confirms the
existing flash-expiry cart behavior and permanent dependency bootstrap before
F-3 changes; it is not reservation evidence.

## Follow-up limits

- No reserve, release, checkout-410, or expiration runtime flow has been run.
- The fake backend is read-only, so its deterministic periodic failure pattern
  cannot be changed for tests. A client-side repository seam is needed before
  deterministic failure and race tests can be written.
- The deliberately underspecified expiry policy has not been selected. It must
  be compared in Phase 3 before implementation.
- Backend validation of reservation-to-deal/quantity correspondence cannot be
  assumed from the shown contract; the client must preserve its own mapping.
