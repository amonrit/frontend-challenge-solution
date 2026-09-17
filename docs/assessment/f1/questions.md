# F-1 — Live Flash-Sale Countdowns: Questions

## Required outcome

1. Which exact UI surfaces must render a countdown for a flash deal, including
   Home cards that also appear in the flash rail and detail views reached by a
   deep link?
2. What should a deal with no `flashSaleEndsAt` render in each of those
   surfaces?
3. Is `mm:ss` required for exactly one hour, and when must formatting switch to
   `hh:mm:ss`?
4. Must the remaining-time value be rounded down, rounded up, or truncated at
   each second boundary?
5. Which time source defines expiry: the device clock, a backend-supplied
   server clock, or another documented policy?

## Current behavior and ownership

6. Which current widgets own the static flash label in the rail and Home card,
   and where must the detail screen receive equivalent state?
7. Is `DealModel.flashSaleEndsAt` always parsed as a UTC instant, and can it be
   null, malformed, already expired, or changed after the deal is loaded?
8. Which layer should own a per-second update: each display widget, a shared
   feature service, a controller, or a ticker scoped to the visible subtree?
9. Which object owns and disposes any timer, subscription, or worker when a
   route closes, a card leaves the tree, or a controller is deleted?
10. What behavior is required when the app is backgrounded, resumed, or the
    device clock changes while the app is inactive?

## Expiry and cart behavior

11. Does a deal become expired exactly at `flashSaleEndsAt <= now`, and must
    every surface converge on that state on its next update?
12. Which cart entries identify a flash deal, and does expiry remove all
    quantities or only one line item?
13. What visible notice mechanism already exists for automatic cart removal,
    and how should repeated expiry events avoid duplicate notices?
14. If a user taps Add to bag at the same instant that expiry occurs, which
    state wins and how is that race made deterministic?
15. Must an expired deal already open on the details screen disable its button
    without requiring navigation or refresh?
16. What happens if a deal expires while it is visible in Search or another
    surface outside the explicit F-1 list?

## Performance and observability

17. What test data or fixture can represent 100 or more simultaneously visible
    flash countdowns without modifying protected catalog data?
18. Which widget subtree is permitted to rebuild once per second, and how will
    a test distinguish that subtree from a card, rail, feed, or full Home
    rebuild?
19. Which DevTools metrics and scenario define acceptable performance: frame
    timing, missed frames, widget rebuilds, Dart heap, image cache, or all of
    these?
20. What device, profile mode, item count, cache warm-up, trace duration, and
    scroll/idle scenario must be held constant for before/after evidence?
21. Which logs, analytics, or user-visible state can confirm a single expiry
    transition and automatic cart removal at runtime?

## Test and failure cases

22. How can tests control both the current time and the periodic tick without
    waiting for real seconds?
23. Which focused test should fail before implementation to prove that static
    text does not update or an expired deal remains addable?
24. Which cases must cover expiry at zero, one second remaining, one hour,
    multiple hours, an already-expired initial value, and a null end time?
25. Which regression checks must prove that timer ownership does not reintroduce
    the RES-102 post-disposal callback failure?
26. Which integration path must prove that cart removal and its notice work
    across Home, flash rail, and details navigation?
