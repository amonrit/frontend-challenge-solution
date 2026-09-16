# RES-104 — Questions Before Evidence and Task Breakdown

## 1. Required outcome and acceptance

1. After refresh overlaps load-more, which exact feed ordering and item set
   must the user see?
2. Must a refresh always replace all previously loaded pages, or may it retain
   pages that have already been confirmed current?
3. Should the latest refresh win even when an older load-more request completes
   later?
4. How should the UI represent loading when refresh and pagination overlap?
5. What does “more items than the catalog contains” mean for the expected
   maximum item count and page metadata?

## 2. Reproduction and request timing

1. Which user gesture or scroll position reliably starts `loadMore`?
2. How quickly must pull-to-refresh follow the pagination trigger to reproduce
   the issue?
3. Does the fake API provide deterministic latency or failure controls for
   page 1 and later pages?
4. Which request completion order produces duplication or stale data?
5. Can the same issue occur with two load-more calls, two refreshes, or only
   refresh versus load-more?
6. What request/page sequence and final list should the regression test assert?

## 3. State ownership and lifecycle

1. Which controller fields own the current page, total pages, loading guards,
   and visible deal list?
2. Does `RefreshController` have independent refresh and load-more completion
   states that must be balanced for every request round?
3. What should happen if the Home controller closes while a page response is
   in flight?
4. Can a refresh start while `_isFetchingMore` is true, and should either
   operation be queued, cancelled, or ignored?
5. Is pagination state allowed to change before a repository response is
   accepted?

## 4. Repository and data contract

1. Does `PagedResponseModel` identify the response page and total page count?
2. Can the API return overlapping or reordered items between pages?
3. Is `DealModel.id` stable and suitable for duplicate detection, or must the
   feed preserve duplicate IDs if the backend returns them?
4. Are page numbers one-based for every Home request?
5. What should happen when a refresh or load-more request fails?

## 5. Edge cases and compatibility

1. What should happen when refresh completes with an empty first page?
2. What should happen when the user refreshes after reaching the final page?
3. What should happen when a stale response reports a different `totalPages`?
4. Should the current “Pickup today” filter survive a refresh?
5. Should flash deals reload as part of the same refresh round or remain
   independent?
6. What behavior is required after repeated rapid refresh gestures?

## 6. Test and evidence design

1. Should the regression be a controller unit test with injected delayed
   repositories, a widget test using `RefreshController`, or both?
2. What deterministic fake repository API can control completion order without
   modifying `fake_api_service.dart`?
3. Which assertions prove that stale responses cannot append or replace feed
   data?
4. How will accepted page numbers, request generations, and final item IDs be
   observed in the test?
5. Which runtime logs or screenshots are needed to compare the reproduction
   before and after the fix?
6. What full-suite, analyzer, diff, and manual checks are required before
   marking RES-104 complete?
