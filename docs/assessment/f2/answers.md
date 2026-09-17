# F-2 — Deal Impression Tracking: Evidence-Backed Answers

## Evidence record

| Source or command | Observed fact |
| --- | --- |
| `PROBLEM.md:134-151` | A qualifying card is at least 50% visible continuously for one second; the event is once per deal per app session and contains `deal_id`, `source`, and `position`. Valid sources and both batch thresholds are explicit. |
| `lib/service/analytics_service.dart` | `logEvent` creates an `AnalyticsEvent`, immediately appends it to observable `events`, and logs it. It has no session deduplication, pending batch, sender, retry, or clock dependency. |
| `lib/feature/analytics_debug/analytics_debug_screen.dart` | The debug screen renders every item currently in `AnalyticsService.events`; it does not distinguish queued, delivered, or failed delivery state. |
| `lib/feature/home/widget/home_feed_list.dart` | Home feed uses a lazy `ListView.builder`; flash rail is list index zero when present; ordinary deal cards start after the rail/header and are constructed as `DealCard(deal: ...)` with the card default source. |
| `lib/feature/home/widget/flash_deals_section.dart` | Flash cards are built directly in a horizontal `ListView.builder`; their zero-based index is available in the item builder and route source is already `flash_rail`. |
| `lib/feature/search/search_screen.dart` | Search uses a lazy `ListView.builder`; latest result index is available and `DealCard` currently receives `source: 'search'`, but no position. |
| `lib/service/fake_api_service.dart:222-225` | `sendAnalyticsBatch` accepts `List<Map<String, dynamic>>`, waits simulated latency, logs batch size, and returns `Future<void>`; its shown implementation has no simulated analytics-specific error path or partial acknowledgement. |
| Installed `visibility_detector 0.4.0+2` source | A detector requires a unique key. `VisibilityInfo.visibleFraction` is a rectangular visible-area ratio in `[0, 1]`. Callbacks are deferred/coalesced at most once per `VisibilityDetectorController.updateInterval` (default 500 ms), or frame-coalesced at `Duration.zero`; `forget(key)` cancels pending updates for a detached detector. |

## Answers

| Questions | Evidence-backed answer | Evidence |
| --- | --- | --- |
| 1, 9 | The requirement states once per **deal** per app session across all screens. Therefore session deduplication is keyed by deal identity, while the sole event must retain one source/position selected when it qualifies. The exact tie-break behavior is not specified. | `PROBLEM.md:138-145` |
| 2 | Exactly 50% qualifies because the requirement uses `≥50%`. If the package is selected, its fraction is calculated from rectangular visible area. | `PROBLEM.md:138-140`; installed package `visibility_detector.dart` |
| 6 | The Home feed's model-list position is available as `index - dealStartIndex`. The current UI index includes a conditional flash rail and header, so UI row index is not the same thing as a deal-list position. | `home_feed_list.dart` |
| 7 | The flash rail builder exposes a zero-based `index` in `flashDeals`; route navigation already labels it `flash_rail`. | `flash_deals_section.dart` |
| 8 | The Search builder exposes the latest displayed result's zero-based `index`. The controller invalidates stale responses by generation before assigning `results`. | `search_screen.dart`; `search_deals_controller.dart` |
| 11, 12 | `AnalyticsService` is registered as a permanent dependency at app bootstrap, so it is the existing app-scoped location for session state. No logout/reset flow is present in the inspected source. | `main.dart`; `analytics_service.dart` |
| 16, 17 | The 10-event and 15-second-first-unsent thresholds are requirements. The implementation ordering and simultaneous-trigger guard are not yet defined. | `PROBLEM.md:142-145` |
| 20, 21 | The simulated analytics endpoint returns `void` after logging. In its current source it has no endpoint-specific failure or partial-acceptance behavior. Client retry policy remains a design decision. | `fake_api_service.dart:222-225` |
| 23, 24 | Existing debug UI exposes all `AnalyticsService.events` only. It can show properties because it renders the properties map, but it cannot currently prove delivery state. | `analytics_debug_screen.dart`; `analytics_service.dart` |
| 26 | Package callbacks can be made frame-coalesced with `VisibilityDetectorController.updateInterval = Duration.zero`; the package also exposes `notifyNow` and `forget(key)` for deterministic test cleanup. A separate injectable clock/timer seam is still needed for the one-second qualification and 15-second batch deadline. | installed `visibility_detector_controller.dart` |
| 32 | Current `AnalyticsService` retains all logged events in memory for the lifetime of its registration, immediately exposes them through an Rx list, and does not deliver batches. | `analytics_service.dart` |
| 33 | Home normal cards currently use default source `home`, flash cards are direct widgets, and search cards use `search`; no call site currently passes all required F-2 source/position fields. | `deal_card.dart`; Home/Search sources |
| 34 | The installed package requires unique keys, coalesces callbacks, and offers explicit pending-callback cleanup. It does not itself implement the one-second business timer or session deduplication. | installed package source |
| 35 | The batch endpoint accepts event maps and returns no acknowledgement payload; no analytics-specific failure is implemented in the shown fake backend. | `fake_api_service.dart:222-225` |

## Follow-up limits

The following questions require an explicit product/engineering decision or
runtime evidence and therefore are not answered as facts yet: continuous-time
reset and jitter policy (3–5), source/position tie-break policy (9–10), exact
session end and dedup-after-failure behavior (12–15), simultaneous batch and
in-flight behavior (18–19), retry/flush policy (20, 22), privacy constraints
(25), deterministic cross-screen test design (27–31), and profile-mode scroll
measurements (30–31).

No runtime visibility callback, batch delivery, or scroll performance result
has been claimed in this phase.
