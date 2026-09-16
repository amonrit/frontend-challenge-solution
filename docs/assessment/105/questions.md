# RES-105 — Requirement and Evidence Questions

## Required outcome

1. Which user-visible scrolling scenario defines “janky” for acceptance?
2. What minimum frame-time or missed-frame improvement is expected, if any?
3. Is the target only the Home feed, or must Search and shared deal cards also
   meet the same performance behavior?
4. How many loaded deals and how many visible cards should the acceptance
   scenario contain?

## Reproduction and environment

5. Which mid-range Android device, OS version, screen size, and refresh rate
   should be used for comparable measurements?
6. Should measurements use profile mode with the same build flags and data on
   every run?
7. What exact scroll gesture, duration, distance, and warm-up period should be
   repeated before recording a trace?
8. Does the issue reproduce from a cold start, after image cache warm-up, or
   both?
9. Is the memory growth expected to be measured as Dart heap, RSS, image cache
   bytes/count, or all three?

## Reactive boundaries and lifecycle

10. Which Home state changes must rebuild the app bar, feed list, flash rail,
    filter control, and individual cards?
11. Can scroll-dependent UI such as app-bar elevation and the floating action
    button update without rebuilding the feed contents?
12. Which controller, widget, and scroll-controller lifecycles own listeners
    and subscriptions, and when must each be released?
13. Are there existing rebuild counters or DevTools “Track widget rebuilds”
    traces that identify the largest rebuilding subtree?

## List and image behavior

14. Must the feed remain a `ListView.builder`, or is another lazy viewport list
    acceptable?
15. Are there requirements for preserving scroll position, pull-to-refresh,
    pagination, and the flash rail while changing list construction?
16. What are the rendered dimensions and aspect-ratio constraints for each
    image use (feed card, flash rail, map/details)?
17. Is it acceptable to pass cache width/height hints to the image package, and
    should those hints account for device pixel ratio?
18. Should failed images, placeholders, and rapid scrolling retain their
    current visual behavior?

## Edge cases and non-regression

19. What should happen while the first page is loading, empty, refreshing, or
    loading another page?
20. How should performance changes behave with 0, 1, 20, 100, and multiple
    pages of deals?
21. Could a refresh or pagination response replace the list while a scroll
    trace is running, and what behavior must remain unchanged from RES-104?
22. Should accessibility semantics, tap targets, and route arguments remain
    identical after widget decomposition?

## Verification and evidence

23. Which DevTools views are required: Performance frame chart, timeline
    events, rebuild tracker, memory view, and image cache details?
24. What before/after metrics will be recorded, over what trace interval, and
    how many repetitions are enough to avoid a single-run outlier?
25. How will we show that the same device, profile mode, item count, image
    inputs, and scroll scenario were used before and after?
26. What regression test can verify reactive boundaries or lazy construction
    without asserting implementation details?
27. What manual checks are required for refresh, load-more, filter, card tap,
    image error, and navigation while the feed is scrolling?
