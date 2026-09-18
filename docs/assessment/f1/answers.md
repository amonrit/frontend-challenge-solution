# F-1 — Live Flash-Sale Countdowns: Evidence-Backed Answers

## Pre-implementation source evidence

The findings below are retained as the investigation snapshot that informed the
selected design. Delivered behavior and current verification status are
summarized in [`solutions.md`](../../../solutions.md) and the later records in
[`tdd-readiness.md`](tdd-readiness.md).

| Question area | Answer | Evidence |
| --- | --- | --- |
| Required surfaces | The assignment requires live countdowns in the flash rail, Home cards, and deal details. | `PROBLEM.md:117-132` |
| Current rail state | Each flash-rail card renders the static `Ends soon` text. | `lib/feature/home/widget/flash_deals_section.dart:86-99` |
| Current Home-card state | `DealCard` renders a static `FLASH SALE` badge when `deal.isFlashSale` is true. Search also uses this shared card. | `lib/feature/shared_widget/deal_card.dart:34-52`; `lib/feature/search/search_screen.dart:39-44` |
| Current detail state | The loaded details view always enables `Add to bag` and has no flash countdown or expiry branch. | `lib/feature/deal/deal_details_screen.dart:164-175` |
| Flash data | `DealModel` parses a non-null `flashSaleEndsAt` using `DateTime.parse`; `isFlashSale` is only a non-null check. A malformed string would throw during model creation. | `lib/model/deal_model.dart:61-67` |
| Fake API time source | The protected fake API generates flash end instants from its own current UTC clock plus catalog minutes. This is a test backend behavior, not a production server-time contract. | `lib/service/fake_api_service.dart:275-290` |
| Existing cart identity | Cart entries are keyed by `deal.id`; `remove(dealId)` removes every matching entry, so it removes the whole quantity line. | `lib/service/cart_service.dart:15-27,42-55` |
| Current cart expiry protection | `CartService.add` checks quantity only. Neither it nor the detail button checks flash expiry. | `lib/service/cart_service.dart:15-27`; `deal_details_controller.dart:113-120`; `deal_details_screen.dart:164-175` |
| Existing user notice | Adding from details already uses a bottom `Get.snackbar`, providing an established in-app notice mechanism. | `lib/feature/deal/deal_details_controller.dart:113-120` |
| Existing deterministic timer seam | `PickupCountdown` accepts a `now` function, owns a periodic timer, and cancels it in `dispose`; its widget tests advance both a controlled clock and the periodic tick. | `lib/feature/order/widget/pickup_countdown.dart:8-65`; `test/pickup_countdown_test.dart:38-48` |
| Existing lifecycle gap for F-1 | There is no flash-specific timer, shared ticker, app-lifecycle observer, expiry worker, or cart-removal notice in source. | Search of `lib/feature/home/`, `lib/feature/shared_widget/`, `lib/feature/deal/`, and `lib/service/cart_service.dart` on 2026-09-17 |
| 100+ test data seam | Tests can create `DealModel` fixtures directly; no protected catalog edit is necessary. The existing Home lazy-list test already constructs a large feed in code. | `test/home_feed_list_test.dart`; protected-file constraint in `PROBLEM.md` |

## Confirmed requirement interpretation

- A deal is a flash deal when its model contains a non-null end instant, but a
  non-null instant is not currently equivalent to an active sale.
- At expiry, the assignment explicitly requires `Expired`, disabled addition,
  automatic cart removal, and a visible notice.
- The performance requirement applies to 100 or more visible countdowns and
  forbids rebuilding cards or the Home list for each one-second tick.
- The existing shared `DealCard` means a card countdown change will also affect
  Search. Whether Search must show the countdown is not explicitly required,
  so the later design decision must document that scope.

## Follow-up limits

- No current source establishes a production server-clock contract, a required
  background/resume policy, or the rounding rule at a second boundary.
- Android profile-mode observation confirms active countdown text changes in
  the rail, Home card, and details screen. No runtime reproduction has yet
  observed a countdown reaching expiry, cart removal, or duplicate-notice
  behavior.
- No DevTools baseline for 100+ countdowns has been captured. The RES-105
  physical-device limitation still applies: USB Flutter DevTools evidence is
  unavailable with the current charge-only cable.
- Timer ownership and the exact cart-expiry race policy remain design decisions
  for the options phase.
