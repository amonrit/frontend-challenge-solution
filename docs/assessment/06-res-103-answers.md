# RES-103 — Evidence-Backed Answers

This document records answers supported by the current source, dependency
inspection, automated tests, and runtime logs.

## Required outcome and current source behavior

| Question | Evidence-backed answer | Evidence |
| --- | --- | --- |
| 1.1 | The documented flow is to open several deal pages, close them, then tap **Add to bag**; requests from pages that are no longer active must not continue accumulating. | `PROBLEM.md`, RES-103. |
| 1.3 | The current controller is intended to refresh `quantityLeft` whenever `cartService.itemCount` changes. That behavior must remain for a live detail page. | `deal_details_controller.dart`. |
| 1.5 | The ticket specifically describes the cart observer and accumulated `GET /deals/:id` calls. A broader audit of unrelated detail-page resources is not yet justified. | `PROBLEM.md`; source inspection. |
| 4.2 | The existing availability refresh uses `DealRepo.fetchById`, which delegates to the simulated API and parses a `DealModel`. | `deal_repo.dart`; `fake_api_service.dart` (read only). |

## Lifecycle and ownership facts

| Question | Evidence-backed answer | Evidence |
| --- | --- | --- |
| 3.1 | `DealDetailsController.onInit()` creates the cart observer by calling `ever(cartService.itemCount, ...)`. | `deal_details_controller.dart`. |
| 3.2 | In the resolved GetX dependency, `ever` returns a `Worker` that wraps a stream subscription and exposes `dispose()`. | GetX 4.7.3 `rx_workers.dart`; `pubspec.lock`. |
| 3.6 | Each controller calls `ever` independently, so each detail-page controller has an independent observer subscription. | `deal_details_controller.dart`; GetX `ever` implementation. |
| 3.7 | The detail route creates `DealDetailsController` through `DealDetailsBinding`; the detail widget reads from that controller. Route removal and controller cleanup must therefore be verified through GetX navigation behavior. | `deal_details_binding.dart`; `routes.dart`; `deal_details_screen.dart`. |
| 3.8 | No other timer, Worker, or stream subscription was found in `DealDetailsController`; the cart `ever` observer is the repeating listener in this path. | Repository search and controller source. |
| 4.4 | The project resolves GetX 4.7.3 under the existing `^4.6.6` constraint. The selected cleanup API must be compatible with that resolved Worker type. | `pubspec.yaml`; `pubspec.lock`; GetX source. |

## Request and test evidence

| Question | Current answer | Evidence |
| --- | --- | --- |
| 6.3 | A fake `DealRepo` can count `fetchById` calls, and a controllable `CartService`/observable can trigger the observer without real network latency. | Constructor injection in `DealDetailsController`; `DealRepo` API. |
| 6.5 | The RED signal occurred as expected: after `onClose()`, a second cart mutation increased the counted `fetchById` calls from one to two. | Focused controller test before the fix, 2026-09-16. |
| 6.9 | The existing full suite passes before RES-103 work: `flutter test` completed with 5 passing tests. | Flutter 3.27.0 run, 2026-09-16. |

## Read-only evidence collection run

| Check | Result | Evidence |
| --- | --- | --- |
| Source trace | `onInit()` creates one `ever` observer per controller instance; the returned `Worker` is not retained in the current source. | `deal_details_controller.dart`; GetX 4.7.3 `rx_workers.dart`. |
| Dependency inspection | `ever` returns a `Worker` wrapping a stream subscription; `Worker.dispose()` calls the subscription cancellation callback. | GetX 4.7.3 source. |
| Regression baseline | Full project suite passed: 5 tests. | `/Users/amonrit/fvm/versions/3.27.0/bin/flutter test`. |
| Static analysis | No issues found. | `/Users/amonrit/fvm/versions/3.27.0/bin/flutter analyze`. |
| iOS runtime launch | App built and launched on iPhone 17 Pro Simulator after clearing generated build artifacts. Startup log showed `FakeApiService ready`, `/home` screen view, `GET /deals/flash`, and `GET /deals?page=1`. | `/private/tmp/rescu-res103-runtime.log`, Flutter 3.27.0 run. |
| Simulator restart retry | Simulator was shut down, booted, and the app rebuilt/launched again successfully. Startup logs were reproduced, but coordinate/accessibility taps still did not navigate from the Home screen. | Flutter 3.27.0 run after `simctl shutdown`/`boot`, 2026-09-16. |
| Manual request reproduction | In a clean app run, the user opened deal 1, 2, and 3 and backed out of each, then opened deal 4 and tapped **Add to bag**. One cart change logged four refresh callbacks and four requests: `GET /deals/3`, `/deals/4`, `/deals/2`, and `/deals/1`. | Interactive Flutter run terminal output, 2026-09-16; output captured in the session transcript. |

These checks establish the observer/resource facts, a clean baseline, and a
successful iOS runtime launch. The controlled manual flow reproduced the
request accumulation: one cart change triggered one request for each of four
detail controllers, including the three routes that had already been closed.

## Runtime facts still pending

- Reliability across repeated runs and request counts for other page counts.
- Whether every navigation-removal path disposes the controller.
- Behavior of in-flight availability requests during controller disposal.
- Additional console log captures for other navigation paths.
- Route-level automated coverage beyond the documented Back flow.

## Scope decisions still requiring evidence or user input

- In-flight request cancellation is deliberately out of scope: this fix stops
  future observer callbacks, and no evidence showed a visible error from an
  already-started response.
- List-child removal and app background/resume were not made acceptance
  criteria because the ticket documents the Back-navigation flow.
