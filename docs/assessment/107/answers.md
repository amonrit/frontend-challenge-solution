# RES-107 — Evidence-Backed Answers

This document records the source and test facts collected before implementation.
Later execution and verification results are recorded in `solutions.md` and the
task breakdown.

## Routing and current behavior

| Question | Answer supported by evidence | Evidence |
| --- | --- | --- |
| 1.1 | The documented URI is `rescu://open/deal?id=42&source=push`. The in-app simulator parses the URI and navigates using its path and query string. | `PROBLEM.md`; `lib/feature/home/home_screen.dart` |
| 1.3 | A normal card navigation passes both `Routes.dealRoute(...)` and the `DealModel` in `Get.arguments`; the simulator route passes no model argument. | `lib/feature/shared_widget/deal_card.dart`; `lib/feature/home/widget/flash_deals_section.dart`; `home_screen.dart` |
| 2.3 | Route query values are read from `Get.parameters` first and fall back to the current route URI. A missing source falls back to `unknown` for analytics. | `lib/feature/deal/deal_details_controller.dart`; source regression test |
| 2.4 | At evidence-collection time, `DealDetailsController.onInit()` force-cast `Get.arguments` to `DealModel`, so a deep link with no arguments threw before a details page could render. This was the RES-107 RED condition and is now fixed. | `deal_details_controller.dart`; RED test |
| 2.5 | The `/deal` route uses `DealDetailsBinding`, which lazily constructs a fresh `DealDetailsController` with the shared repository, cart service, and analytics service. | `lib/routes/routes.dart`; `lib/binding/deal_details_binding.dart` |
| 1.5 | Deal 42 exists in the bundled catalog. | `assets/data/deals.json` line 602 (read-only) |

## Repository and error facts

| Question | Answer supported by evidence | Evidence |
| --- | --- | --- |
| 4.1 | `DealRepo.fetchById` calls `FakeApiService.getDealById` and converts the response to `DealModel`. | `lib/repository/deal_repo.dart` |
| 4.2 | The simulated API waits 200–700 ms, logs `GET /deals/:id`, returns the matching record, and throws `ApiException('Deal not found', statusCode: 404)` when there is no match. | `lib/service/fake_api_service.dart` (read-only) |
| 4.3 | A valid ID lookup has simulated latency, so an ID-based details flow needs an explicit loading state before the model is available. | `fake_api_service.dart`; current screen reads `controller.deal` synchronously |
| 4.4 | At evidence-collection time, the details screen had no loading or error branch. T4 added explicit loading, error, retry, and loaded branches. | `lib/feature/deal/deal_details_screen.dart`; T4 |
| 3.6 | Analytics currently logs `deal_details_view` only after the model cast succeeds, using the model ID and route source. | `deal_details_controller.dart` |

## Lifecycle and compatibility facts

| Question | Answer supported by evidence | Evidence |
| --- | --- | --- |
| 3.1 | The controller owns details state and the repository owns API access. Route parsing/loading responsibility is not separated yet; `onInit` currently assumes the route binding already supplied a model argument. | controller, binding, repository source |
| 3.4 | The current controller starts a cart `ever(...)` observer after initialization and disposes its Worker in `onClose()`. A deep-link loading design must not start availability work before a model exists. | `deal_details_controller.dart` |
| 5.5 | Normal card navigation supplies a model argument and must continue to work when ID loading is added. | `deal_card.dart`; `flash_deals_section.dart` |
| 5.9 | Availability refresh errors are currently not converted to a user-facing state; the refresh Future is awaited without a catch branch. | `deal_details_controller.dart` |

## Baseline verification

| Check | Result | Evidence |
| --- | --- | --- |
| Baseline full suite | 9 tests passed on 2026-09-16 using Flutter 3.27.0. | `/Users/amonrit/fvm/versions/3.27.0/bin/flutter test` |
| Final full suite | 13 tests passed after RES-107 implementation. | `/Users/amonrit/fvm/versions/3.27.0/bin/flutter test` |
| Static analysis | No issues on 2026-09-16. | `/Users/amonrit/fvm/versions/3.27.0/bin/flutter analyze` |
| Protected files | `fake_api_service.dart` and `assets/data/` remained unchanged throughout RES-107. | `git status`; source inspection |

## Follow-up limits

- Android cold-start intent verification and the iPhone Simulator flow both
  cover deal 42. Dedicated widget tests for loading/error rendering and
  repeated deep-link navigation remain follow-up coverage.
