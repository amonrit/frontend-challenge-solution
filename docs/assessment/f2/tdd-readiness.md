# F-2 — Deal Impression Tracking: TDD Readiness

## Acceptance criteria

1. A Home feed, flash rail, or Search card records `deal_impression` only after
   it is at least 50% visible continuously for one second.
2. The event contains only required `deal_id`, `source`, and `position`
   properties and is emitted at most once per deal per app session across all
   three sources.
3. Dropping below 50%, disposal, identity change, or app pause cancels the
   in-progress qualification interval.
4. Ten unsent events send immediately as one batch; otherwise the first unsent
   event sends after 15 seconds. Concurrent triggers and in-flight sends do not
   duplicate or lose events.
5. Visibility tracking does not add a timer per card or rebuild a scrolling
   list for visibility/batch state changes.

## Deterministic test seam

| Concern | Controlled input | GREEN assertion |
| --- | --- | --- |
| Qualification | Injected `now` and one-shot qualification timer | Exactly one event appears only after the supplied clock reaches one continuous second at `>= 0.5` |
| Threshold reset/disposal | Explicit visibility update and observation removal | No event can appear from a cancelled observation |
| Cross-source dedup | Same deal id with distinct observation/source inputs | First qualifying observation wins; second creates no event |
| Batch thresholds | Injected sender, clock, and batch timer | One FIFO send occurs at ten events or first-unsent +15 seconds |
| Delivery failure/in-flight | Completer-backed sender | Failed events remain queued for retry; events arriving during send remain queued once |
| Wrapper behavior | `VisibilityDetectorController.updateInterval = Duration.zero` in widget test | Card forwards threshold changes and cancels its observation at disposal without rebuilding its parent list |

## Initial RED test

`test/analytics_service_impression_test.dart` constructs `AnalyticsService`
with an injected UTC clock and one-shot timer. It reports a Home observation at
exactly `0.5`, advances the clock by one second, fires the controlled timer,
and expects one `deal_impression` event with the required properties.

### Expected RED signal

Before implementation, `AnalyticsService` has neither injectable clock/timer
dependencies nor `observeImpression`. The test should fail to compile with
missing constructor parameters and method, proving the current immediate
`logEvent` sink cannot meet the qualification requirement.

### Recorded RED result

On 2026-09-17, `fvm flutter test
test/analytics_service_impression_test.dart` failed at the test's
`AnalyticsService(now: ...)` construction with `No named parameter with the
name 'now'`. The current service constructor takes no arguments, so the test
cannot control qualification time or schedule a deadline. No production code
was changed to obtain this result.

### GREEN assertion

After the first execution task, the test records no event before the deadline,
then exactly one required event at the controlled deadline.

### E1 recorded GREEN

`AnalyticsService` now accepts an injected clock and one-shot timer, retains
an eligible observation until its one-second deadline, and records the required
event only when that controlled deadline fires. The initial RED test is GREEN.
The service owns one earliest-deadline timer and cancels it in `onClose()`.
Threshold cancellation, cross-source deduplication, and batching remain E2+
work.

### E2 recorded RED and GREEN

The E2 RED tests first showed an emitted event after the same observation
dropped from `0.5` to `0.49`, and two events when Home and Search qualified the
same deal concurrently. `AnalyticsService` now removes an observation below
the threshold and exposes the same removal boundary for wrapper disposal. A
session-wide deal-id set is updated atomically when a due observation is
recorded, so insertion order makes the first qualifying observation retain its
source and position. Both cancellation and cross-source tests are GREEN.

### E3 recorded RED and GREEN

The E3 RED tests could not construct the service because it had no injected
batch sender. `AnalyticsService` now keeps a FIFO queue of qualifying
impression payloads, starts the 15-second deadline only for its first unsent
event, and takes an immutable batch snapshot under a single-flight send guard.
The focused tests verify one send with deal ids 1–10 at the threshold and one
send of an incomplete batch at its controlled 15-second deadline. Delivery
failure and pause/resume behavior remain E4 work. The first GREEN run exposed
a fixture assumption from E1: its timer factory asserted that every timer was
one second. E3 legitimately adds a 15-second batch timer, so the fixture now
asserts the first qualification timer only. This corrected the test seam
without changing product behavior. A Completer-backed sender test also proves
that an eleventh impression qualifying during the first in-flight batch remains
queued and is sent only as the next batch.

### E4 recorded RED and GREEN

E4 RED initially failed to compile because `AnalyticsService` had no lifecycle
observer API. The selected policy retains a failed batch, logs its technical
error, and schedules a controlled 15-second retry; it does not create another
impression for the already-deduplicated deal. App pause clears only
in-progress visibility observations, while unsent batches remain. On resume,
an overdue batch sends immediately. `onClose()` cancels both service timers and
removes the lifecycle observer. Focused tests cover retry, pause, resume, and
disposal. The disposal test first required `TestWidgetsFlutterBinding` setup
because it calls a widget-binding lifecycle API from a plain Dart test; that
was a test-fixture correction, not a product failure.

### E5 recorded RED and GREEN

The E5 RED widget test failed to load because `DealImpressionTracker` did not
exist. The reusable stateful wrapper now gives each rendered observation a
stable unique detector key, forwards `visibleFraction` to the app-scoped
service, and ends the observation in `dispose()` or when its identity changes.
Home feed supplies `home_feed` and its model-list index; the flash rail supplies
`flash_rail` and its horizontal index; Search supplies `search` and its result
index. The focused wrapper tests verify forwarded source/position and disposal
cancellation without any reactive wrapper around a scroll list.

## Edge and failure cases

- Visibility exactly `0.5`, just below it, and threshold jitter before the
  deadline.
- Repeated qualifying callbacks for one observation.
- Same deal visible concurrently in Home, flash rail, and Search.
- Card recycling, route pop, app pause/resume, and detector key reuse.
- Ten-event/deadline simultaneous trigger, sender failure, and events arriving
  during an in-flight send.
- An empty queue, multiple batches, and service disposal with pending timers.

## Execution boundary

- Protected files: `lib/service/fake_api_service.dart` and `assets/data/`.
- Expected production files: `AnalyticsService`, a reusable detector wrapper,
  Home feed/flash rail/Search call sites, app bootstrap if new dependencies are
  required, and Analytics debug state only if it needs delivery status.
- Initial RED command: `fvm flutter test test/analytics_service_impression_test.dart`.
- Later checks: focused F-2 tests, full `fvm flutter test`, `fvm flutter
  analyze`, `git diff --check`, Analytics debug manual flow, and comparable
  Android profile evidence.
