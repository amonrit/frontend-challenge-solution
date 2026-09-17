# F-2 — Deal Impression Tracking: Requirement Questions

## Required outcome

1. Does an impression represent the deal identity only, regardless of which
   surface exposed it, or does each source need its own event before the
   session-wide deduplication rule applies?
2. Is a card exactly 50% visible considered qualifying, and which rendered
   bounds define its visible fraction when clipped by a scrollable viewport?
3. Must the visible second be strictly uninterrupted, including a frame where
   visibility drops below 50%, or may brief threshold jitter be tolerated?
4. When a card becomes visible after already being partially visible during a
   layout change, from which instant does its continuous one-second interval
   start?
5. Should a card that remains eligible while the app is paused count wall-clock
   elapsed time after resume, or require one continuous foreground second?

## Sources and positions

6. Which Home list positions count as `home_feed` when the screen has headers,
   flash rail, filters, and pagination controls before deal cards?
7. Is a flash rail card's `position` its zero-based index in `flashDeals`, even
   if the deal also appears in the Home feed?
8. Is a Search result position its index in the latest displayed result list,
   and how should an in-flight or stale query result be treated?
9. If a deal appears in two surfaces at the same time, which source and
   position must the one session event retain?
10. Must the source/position be captured at qualification time, at enqueue
    time, or when the batch is delivered?

## Session deduplication and lifecycle

11. What component owns the once-per-deal app-session set, and how is that
    lifetime kept independent of route/controller recreation?
12. When is a session considered finished in this app: process termination,
    GetX dependency reset, or a user-visible logout/reset action?
13. If an event qualifies but delivery fails, should the deal remain deduped
    while retry is pending, or may a later visibility observation enqueue it
    again?
14. If two visibility callbacks for the same deal race, what atomic boundary
    prevents two queued events?
15. How are per-card visibility timers cancelled when the card is removed,
    recycled, changes deal identity, drops below threshold, or its route is
    disposed?

## Batching and delivery

16. Does the 10-event threshold send immediately on the tenth qualifying event,
    including events already waiting for a 15-second timer?
17. Does the 15-second window begin with the first unsent event and remain
    fixed when later events join the batch?
18. If the tenth event and 15-second deadline occur together, how is one send
    chosen and duplicate sends prevented?
19. What happens to events that qualify while a batch request is in flight?
20. On delivery failure, are events retained, retried automatically, dropped
    after logging, or surfaced in Analytics debug state?
21. On a successful partial/empty response contract, what proves that the whole
    local batch was accepted?
22. Must an incomplete batch be flushed during app pause, route changes, or
    service disposal?

## Observability and privacy

23. Does Analytics debug need to distinguish recorded, queued, in-flight,
    delivered, and failed events, or does the existing event list have a
    defined meaning?
24. What instrumentation can show the source, position, qualification time,
    batch membership, and delivery result without exposing unnecessary user or
    device data?
25. Is any personally identifying, location, search-query, or timestamp data
    prohibited beyond the required `deal_id`, `source`, and `position`?

## Test and evidence questions

26. Which abstraction can provide deterministic visibility percentages and
    continuous-time advancement without a real scroll delay?
27. How can tests prove cross-screen session deduplication when Home, flash
    rail, and Search create different widget instances?
28. How can tests control the 15-second batch deadline, the 10-event threshold,
    delivery success/failure, and concurrent enqueue behavior?
29. Which widget or integration test can verify that a removed or recycled card
    cannot emit after its visibility timer would have elapsed?
30. What profile-mode scenario, device, item count, scrolling sequence, and
    metrics will establish that visibility tracking has not regressed scrolling
    performance?
31. Which manual flow on Analytics debug will prove the required properties and
    batch behavior using the real app?

## Evidence gaps to resolve in Phase 2

32. What current behavior does `AnalyticsService` record, retain, and expose?
33. Where are Home feed, flash rail, and Search cards constructed, and what
    source/position information is available at those call sites today?
34. What lifecycle guarantees and callback semantics does the installed
    `visibility_detector` version provide for widget removal and detector-key
    reuse?
35. What does `FakeApiService.sendAnalyticsBatch` accept and return, and what
    failures can the simulated backend produce for this endpoint?
