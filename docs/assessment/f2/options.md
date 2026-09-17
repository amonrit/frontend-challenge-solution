# F-2 — Deal Impression Tracking: Options and Decision

## Confirmed problem boundary

The existing analytics sink records every call immediately and has no
session-wide deal set, visibility qualification state, batch queue, delivery
clock, or sender. Home, flash rail, and Search construct cards independently,
so a route/controller-local solution cannot enforce once-per-deal behavior
across surfaces.

## Options comparison

| Option | Correctness and lifecycle | Performance | Testability and scope | Decision |
| --- | --- | --- | --- | --- |
| Per-card `State` owns a one-second timer and calls `AnalyticsService` directly | Each recycled/disposed card must cancel its timer; cross-screen dedup and batch ownership remain separate | Up to one timer per qualifying card; unnecessary work for a large feed | Simple first widget test, but race/disposal tests spread across widgets | Rejected |
| Route controller tracks visible cards | Timer ownership is clearer than per-card state but reset on Home/Search route lifecycle; cannot naturally enforce cross-screen session dedup | One route ticker is possible | Duplicates logic across Home and Search | Rejected |
| Manual scroll geometry from controllers | Requires accounting for horizontal rail, clipping, overlays, viewport changes, and lazy child geometry | Can run on every scroll notification | Hard to reproduce exact 50% boundary; duplicates rendering assumptions | Rejected |
| App-scoped `AnalyticsService` owns observation state, one qualification deadline timer, deduplication, queue, and batch delivery; card wrappers report visibility | One session owner survives routes; wrapper disposal explicitly ends an observation; single-flight delivery avoids duplicate sends | At most one service-owned qualification timer and one batch/retry timer; wrappers only forward coalesced detector callbacks | Injectable clock/timer/sender supports deterministic service tests; small reusable wrapper keeps call sites explicit | **Selected** |
| New `ImpressionService` beside `AnalyticsService` | Separates concerns but adds another permanent owner and a handoff between event recording and delivery | Comparable to selected option | More indirection for this assessment's small analytics surface | Rejected for now |

## Selected design

Extend the existing permanent `AnalyticsService` as the session owner.

1. Each reusable `DealImpressionTracker` wraps a card with a uniquely keyed
   `VisibilityDetector` and sends only `(observationId, dealId, source,
   position, visibleFraction)` to the service.
2. The service starts an observation only at `visibleFraction >= 0.5`, clears
   it immediately below the threshold or when the wrapper disposes, and owns a
   single earliest-deadline timer. When an observation has remained eligible
   for one second, it atomically checks the session deal-id set before recording
   one event.
3. The service stores source and position from the qualifying observation. If
   the same deal becomes eligible concurrently on another surface, the first
   service call that inserts the deal id wins; later observations are ignored.
4. Qualifying events are appended to an in-memory FIFO pending queue and are
   shown through the existing debug event list at qualification time. A single
   batch sender dispatches exactly when the queue reaches 10 or the first
   unsent event reaches 15 seconds.
5. Events arriving during an in-flight send remain queued for the next batch.
   On sender failure, retain the batch and retry after a bounded 15-second
   delay; keep the deal deduplicated so retries cannot create a second session
   impression.
6. On app pause, clear in-progress visibility observations because foreground
   continuous visibility has been interrupted. Retain unsent batches; on resume
   evaluate the batch deadline immediately.

## Rejected alternatives and trade-offs

The selected service has more state than a per-widget timer, but consolidates
the only correctness boundaries that must survive card recycling and route
changes. A shared deadline scheduler is more implementation work than one-shot
widget timers; it avoids allocating and disposing up to 100 timers while the
feed is visible and makes deadline ordering controllable in tests.

Analytics debug currently means “recorded locally,” not “delivered remotely.”
This keeps the existing screen useful without silently redefining it. Delivery
state will be exposed as additional observable debug fields only if the task
tests show that reviewers need it.

## Security and privacy

The selected event map contains only the required `deal_id`, `source`, and
`position` properties. It deliberately excludes search text, device identity,
precise location, and visibility timestamps from the delivery payload.

## Evidence limits

The installed fake analytics endpoint has no simulated failure path, so retry
behavior must be verified through an injected sender test seam. Runtime scroll
cost still requires profile-mode evidence; the design comparison is not that
evidence.
