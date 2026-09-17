# RES-101 to RES-107 — Regression Evidence Matrix

This matrix separates deterministic defect proof from Android route smoke
coverage. Each **RED baseline** was rerun in a detached worktree at the commit
that introduced that ticket's failing test. Each **GREEN current** run used
Flutter 3.27.0 on the current `main` revision on 2026-09-17.

| Ticket | Unit/widget proof | RED baseline rerun | GREEN current rerun | Android integration coverage |
| --- | --- | --- | --- | --- |
| RES-101 | `test/search_deals_controller_test.dart` | `cbc87e7`: older result replaced latest result. | 2 passed. | Search route accepts rapid replacement input and renders the final-query result state. |
| RES-102 | `test/pickup_countdown_test.dart` | `3fcffc2`: `setState() called after dispose()` and a pending periodic timer. | 4 passed. | Orders mounts a `PickupCountdown`, then Back leaves the route without a framework exception. |
| RES-103 | `test/deal_details_controller_test.dart` | `d7578b4`: expected 1 request, actual 2 after close. | 4 passed. | `deal_navigation_test.dart` opens and leaves a Home deal three times; the combined smoke flow also exercises route lifecycle. |
| RES-104 | `test/home_controller_test.dart` | `918d69d`: expected refreshed IDs `[3]`, actual stale append `[3, 4]`. | 7 passed, including the shared RES-106 filter test. | Home remains usable after a feed scroll. Network completion ordering remains deterministic unit-test coverage. |
| RES-105 | `test/home_feed_list_test.dart`, `test/home_screen_rebuild_scope_test.dart`, `test/res_105_image_sizing_test.dart` | `beb4164`: expected image decode hint 320, actual `null`. | 3 passed. | Home lazy feed is scrolled in the smoke flow. It is not used as a frame-time or memory benchmark. |
| RES-106 | `test/bangkok_time_policy_test.dart`, `test/res_106_pickup_window_test.dart`, Home filter test | `e9b8fa3`: UTC label `10:30 – 14:00` instead of Bangkok `17:30 – 21:00`; `isToday` incorrectly returned true across a month. | 3 policy tests, 6 pickup-window tests, and the Home filter assertion passed. | `Pickup today` is toggled and every rendered feed `DealCard` satisfies `pickupWindow.isToday`. Boundary dates are covered only by fixed-clock unit tests. |
| RES-107 | `test/deal_details_deep_link_test.dart` | `c2cd103`: `Null` could not be cast to `DealModel`. | 3 passed. | Simulated `rescu://open/deal?id=42&source=push` reaches `DealDetailsScreen`; a prior Android test also validates card navigation. |

## Commands

```sh
# Current unit/widget suite
flutter test

# Android integration tests
flutter test \
  integration_test/deal_navigation_test.dart -d emulator-5554
flutter test \
  integration_test/res_101_107_smoke_test.dart -d emulator-5554
```

## Interpretation boundaries

- Race conditions in RES-101, RES-103, and RES-104 require controlled
  completion order, so their unit/controller tests are the decisive evidence.
- RES-105 performance requires DevTools or device profiling. Its widget tests
  verify mechanisms that affect work scope; they do not claim frame-time or
  memory improvements.
- RES-106 market-date edge cases require a fixed Bangkok clock. The Android
  smoke test validates the live UI path only.
- Android integration tests complement these deterministic tests by proving
  startup, bindings, navigation, and real fake-API wiring work together.
