# F-1 — Live Flash-Sale Countdowns: TDD Readiness

## Acceptance criteria

1. A flash deal shows a live `mm:ss` countdown below one hour and `hh:mm:ss`
   at or above one hour in the rail, Home card, and details view.
2. At `flashSaleEndsAt <= now`, every required surface shows `Expired`; the
   deal cannot be added to the bag.
3. Expiry removes every quantity of an existing flash deal from the cart and
   creates exactly one visible notice per deal expiry transition.
4. One shared clock tick supports 100 or more visible countdowns. Per-second
   updates rebuild countdown text only; cards, the rail, and Home feed do not
   rebuild on every tick.
5. Clock/timer and lifecycle observers are disposed correctly, and app resume
   processes elapsed expiry immediately.

## Deterministic test seams

| Concern | Test level and controlled input | GREEN assertion |
| --- | --- | --- |
| Status/formatting | Unit test with supplied end instant and `now` | Exact remaining label and active/expired state at zero, one second, one hour, and multiple hours |
| Rail/card/details rendering | Widget tests with a fixed clock | Required text/state is visible; expired interaction is disabled |
| Cart expiry | Service test with an in-memory cart and expiry transition | All quantities are removed once; one notice event is emitted |
| Rebuild scope | Widget instrumentation with 100 fixture deals and controlled tick | Countdown leaves rebuild; card, rail, and Home feed counters do not increment |
| Lifecycle/resume | Service/widget test with controllable tick source and lifecycle callback | Timer/observer are released; resume immediately processes an elapsed expiry |

## Initial RED test

`test/flash_deals_section_test.dart` creates a deal with the fixed end instant
`2000-01-01T00:00:00Z` and pumps the existing flash rail. It expects `Expired`
and the absence of `Ends soon`. The instant is far enough in the past that the
test does not depend on the runner clock or wait for a timer.

### Expected RED signal

Before implementation, the rail renders `Ends soon`, so the assertion for
`Expired` fails with zero matching widgets. This proves the current static label
does not meet the expiry state requirement.

### Recorded RED result

On 2026-09-17, `flutter test test/flash_deals_section_test.dart` failed at
`test/flash_deals_section_test.dart:40` with `Expected: exactly one matching
candidate` and `Found 0 widgets with text "Expired"`. The test reached the
assertion; no production code was changed to produce this result.

### E2 test-seam correction

The first clock-service RED test also used a `late` fake-timer variable that
the Dart compiler could not prove was assigned by the injected callback. That
was a test-seam error, not product behavior. The test now uses a nullable fake
timer and asserts it was created before checking cancellation. Its remaining
RED signal was the intended missing clock-service import/type; after E2 the
clock tests pass.

### E3 recorded RED and GREEN

`test/cart_flash_expiry_test.dart` initially failed to compile because
`CartService` had no shared-clock dependency. After E3, its two focused tests
pass: an already-expired deal is rejected at the cart mutation boundary, and a
cart line that expires after being added is removed once with one queued notice
event.

### Post-change GREEN assertion

The same rail fixture renders one `Expired` label and no `Ends soon` label.
Later tests add controlled active-countdown, disabled-interaction, cart-removal,
notice, 100-countdown rebuild, and lifecycle coverage.

## Edge and failure cases

- Null end instant and a deal already expired at initial render.
- One second, zero seconds, exactly one hour, and more than one hour remaining.
- Multiple quantities of one cart line and two different expired deals.
- Add-to-cart tap concurrent with expiry.
- Expiry while Home, details, or the cart is not visible.
- Multiple countdown leaves for the same deal and repeated clock ticks after
  expiry.
- Widget disposal and app pause/resume.

## Execution boundary

- Protected files: `lib/service/fake_api_service.dart` and `assets/data/`.
- Expected production areas after RED: a focused flash clock/status service,
  cart service, flash rail, shared card, details controller/screen, and root
  notice host.
- Initial command: `flutter test test/flash_deals_section_test.dart`.
- Planned later checks: focused F-1 tests, full `flutter test`, `flutter
  analyze`, `git diff --check`, Android emulator flow, and a comparable
  DevTools profile scenario for 100+ countdowns.
