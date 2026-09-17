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
