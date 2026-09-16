# RES-104 — Options, Research, and Decision

## Confirmed problem boundary

`HomeController` accepts page-1 refresh and later-page load-more completions
independently. Refresh resets `_page` before awaiting page 1; load-more advances
`_page` before awaiting its page and appends whatever response returns. The
critical bottleneck is the shared mutable page/list state crossing an await
boundary without a request-round identity.

Secondary bottlenecks are:

- an older response can still call `assignAll` or `addAll` after a newer round;
- `_isFetchingMore` protects only load-more versus load-more, not refresh versus
  load-more;
- duplicate filtering is absent, so a stale append is visible as duplicate
  cards rather than being rejected;
- `RefreshController` completion calls are tied to individual callbacks, so a
  stale callback may also update refresh UI after a newer round.

## Candidate approaches

### A. Monotonic request-round and page tokens — selected

Give each refresh a new generation. Each request captures its generation and
requested page. After `await`, accept the response only when its generation is
still current and its page is still the expected next page. Advance `_page`
only when the response is accepted. Ignore stale completions while completing
the originating refresh/load indicator safely.

### B. Serialize refresh and pagination

Put all feed operations behind a single queue or mutex. A refresh waits for an
active load-more request, then replaces the list; later pagination starts from
the refreshed page.

### C. Cancel or switch to the latest stream

Represent refresh/load-more events as a stream and use cancellation or
`switchMap` semantics so a new refresh supersedes previous work.

### D. Deduplicate IDs after every response

Append only deals whose IDs are not already present, using a `Set<int>` or an
immutable merge step. Keep the current request flow otherwise unchanged.

## Trade-off comparison

| Criterion | A. Generation/page tokens | B. Serialize operations | C. Cancel/switch stream | D. ID deduplication |
| --- | --- | --- | --- | --- |
| Correctness | Rejects stale refresh and pagination responses; preserves newest round. | Correct ordering, but old work still delays the newest refresh. | Correct only if every async operation cooperates with cancellation. | Hides duplicate IDs but can still append stale page data or lose ordering. |
| Lifecycle/resource ownership | Uses existing controller fields and async Futures; no new long-lived worker. | Queue lifetime must be closed with the controller and can retain pending work. | Adds stream/subscription lifecycle and a larger refactor. | Minimal resource cost. |
| Performance | Stale network work may finish, but stale UI/list mutations are skipped. | Can increase refresh latency behind slow page requests. | May reduce accepted work, but backend requests may still continue. | Adds O(n) ID checks on each merge and does not avoid network work. |
| Maintainability | Small, explicit invariant around generation and expected page. | More stateful queue behavior and harder retry semantics. | Highest conceptual and architectural change for the current repository API. | Easy to add but easy to mistake for a complete race fix. |
| Testability | Deterministic delayed repository can control completion order and assert IDs/page. | Requires queue timing and cancellation/flush assertions. | Requires stream cancellation and subscription tests. | A simple duplicate test passes while stale ordering bugs can remain. |
| Cost and scope | Low-to-medium; fits the existing controller and repository contract. | Medium; introduces operation scheduling. | High; likely changes repository/event boundaries. | Low, but insufficient as the primary fix. |

## Decision

Select **A, monotonic request-round and page tokens**. It directly protects the
state that crosses the asynchronous boundary, works with the existing Future
repository API, and gives a deterministic test seam. Keep ID deduplication only
as a possible defensive invariant if evidence shows the backend can overlap
pages; it is not a substitute for rejecting stale rounds.

## Rejected alternatives

- Serialization was rejected as the primary design because a slow, obsolete
  page request would delay the user's refresh and retain unnecessary work.
- A stream `switchMap`/cancellation refactor was rejected because the current
  repository returns Futures and cancellation would not necessarily stop the
  backend request.
- ID deduplication alone was rejected because it cannot identify an old page
  response or restore the correct order after refresh.

## Before/after measurement plan

Before implementation, the RED test will inject a delayed repository and record
request order, accepted pages, final deal IDs, and list length for the overlap
trace. After implementation, the same inputs must show the refreshed page once,
no stale append, and a consistent `_page`/`totalPages` state. The production
fake API must remain untouched in both measurements.

## Next TDD gate

The next phase writes the deterministic RED test and readiness checklist. No
production implementation starts before that test fails for the intended stale
response behavior.
