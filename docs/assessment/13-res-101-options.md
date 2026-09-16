# RES-101 — Options, Research, and Decision

## Confirmed problem boundary

Each keystroke starts an independent Future. The controller has no identity for
the active query, so any completion can assign `results` and `isLoading`.
Runtime logs confirmed that older responses can complete after a final query.

## Candidate approaches

### Option A — Monotonic request generation

Increment an integer generation whenever input changes, including when it is
cleared. Capture that generation before awaiting a search. Only the invocation
whose captured value still equals the latest generation may update results,
loading, searched state, or error UI.

### Option B — Compare the request query with the latest query string

Store the latest normalized query and apply a response only when its query
equals that value.

### Option C — Debounce input before starting each request

Wait for a short pause before calling the repository.

### Option D — Cancel or switch to the latest request

Use a cancellable HTTP operation or an Rx stream operator such as `switchMap`
so earlier work is cancelled or ignored automatically.

## Comparison

| Criterion | A: generation | B: query equality | C: debounce | D: cancellation/switchMap |
| --- | --- | --- | --- | --- |
| Rejects late response | Yes | Usually | No by itself | Yes |
| Invalidates on clear | Yes | Requires special handling | No by itself | Requires stream state handling |
| Handles repeated identical query | Yes; each request has unique identity | Ambiguous; old and new identical text compare equal | No correctness guarantee | Yes if latest subscription is authoritative |
| Keeps repository contract | Yes | Yes | Yes | No; needs cancellation/stream refactor |
| Loading-state correctness | Yes, gate updates by generation | Requires careful matching | No by itself | Requires lifecycle integration |
| Scope and risk | Small | Small but edge-prone | Small optimisation only | Broad |
| Testability | Deterministic with completers | Deterministic but duplicate-query case is weak | Timing-sensitive | Requires stream/cancellation tests |

## Decision

Select **Option A — monotonic request generation**.

It gives each request an unambiguous identity and invalidates all prior work
when the input changes or clears. The same identity gate covers results,
loading state, and errors. It works with the existing Future-based repository,
requires no API cancellation support, and has a deterministic controller test
shape.

## Rejected alternatives

- **Option B** is rejected because two identical queries can be separate
  requests; text equality cannot identify which completion is current.
- **Option C** is rejected as the correctness fix. It can reduce request volume
  but does not stop an already-started older response from arriving last.
- **Option D** is rejected for this ticket because the repository does not
  expose cancellation and an Rx-stream redesign broadens the controller's
  responsibilities.

## Follow-up decision: debounce

Do not add debounce in RES-101. The ticket requires result correctness, and
the simulated backend is intentionally useful for proving overlaps. A separate
product/performance decision can add debounce later, while retaining the
generation guard.

## Next TDD gate

Write a controller test with independently completable repository futures.
Complete the latest query first, then an older query. The pre-fix controller
must fail by exposing the older list; the fixed controller must retain the
latest list. Add a second test for clearing input during an in-flight request.
