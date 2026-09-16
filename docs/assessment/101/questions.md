# RES-101 — Questions Before Evidence and Task Breakdown

## 1. Required outcome and acceptance

1. What exact input/result relationship must hold after a user types quickly?
2. Does the requirement apply to every completed request or only the latest
   query when the response arrives?
3. What must Search show immediately after the user clears the input while a
   prior request is still running?
4. Must the loading indicator represent the latest request only?
5. How should an error from an older request affect the current query's UI?
6. What evidence is sufficient to prove an outdated response cannot overwrite
   the latest results?

## 2. Reproduction and async ordering

1. Can the reported wrong-result behavior be reproduced reliably using the
   bundled simulated API?
2. Which query sequence produces a response for an earlier query after the
   latest query has already returned?
3. What are the request and response log order for that sequence?
4. Does the issue reproduce when typing a prefix sequence such as `s`, `su`,
   `sus`, `sush`, `sushi`?
5. Does it reproduce when changing to an unrelated query rather than extending
   a prefix?
6. Does clearing the input while a request is in flight allow the old response
   to repopulate results?
7. Do two identical consecutive queries need separate request identities?
8. Does a request failure, retry, or fast backspace create a stale loading or
   error state?

## 3. State ownership and lifecycle

1. Which method starts a search request and where are `results`, `isLoading`,
   and `hasSearched` changed?
2. What state identifies the query that currently owns the screen?
3. Is the controller disposed when the Search route closes, and can a response
   return after that lifecycle event?
4. Does the repository or simulated API provide cancellation, or must the UI
   ignore an obsolete response?
5. What happens when two `_search` futures overlap and finish in the opposite
   order from their start order?
6. Can the current code set `isLoading` to false while a newer request remains
   in progress?

## 4. Scope, constraints, and user experience

1. Which files can contain the smallest correct stale-response fix?
2. Is adding a debounce required for correctness, desired for request volume,
   or deliberately out of scope?
3. If a debounce is used, how does the solution still prevent late responses
   from bypassing it?
4. Should whitespace-only queries be treated as empty consistently with the
   displayed input text?
5. Must the selected approach preserve the existing empty state and no-results
   state?
6. Should search requests continue after the Search route has closed?

## 5. Edge cases

1. A previous request succeeds after the input is cleared.
2. A previous request fails after a newer request succeeds.
3. A newer request starts before an older request completes.
4. The same query is submitted twice quickly.
5. The user types, deletes, and retypes the same word.
6. A result list is visible while the next request starts.
7. The Search page is closed while a request is in flight.
8. The latest request returns an empty list while an earlier request has
   non-empty results.

## 6. Test and evidence design

1. How can a fake repository expose independently completable futures for two
   queries?
2. What RED test proves an older response overwrites newer results today?
3. What GREEN assertion proves only the latest query may update results?
4. What test proves clearing the input invalidates all earlier responses?
5. How can tests assert correct `isLoading` and `hasSearched` behavior without
   coupling to private implementation details?
6. Which tests need controller-level coverage versus widget-level coverage?
7. What runtime logs should be retained from manual reproduction and final
   comparison?
8. Which focused tests, full-suite checks, analyzer checks, and manual steps
   are required before delivery?
