# RES-103 — Options, Research, and Decision

## Confirmed problem boundary

`DealDetailsController.onInit()` subscribes to `cartService.itemCount` with
GetX `ever(...)`. The runtime reproduction opened four detail controllers,
closed the first three, and changed the cart once. Four callbacks and four
`GET /deals/:id` requests were logged, including requests for the closed
controllers.

## Candidate approaches

### Option A — Retain the Worker and dispose it in `onClose()`

Store the `Worker` returned by `ever(...)` in the controller and call
`worker.dispose()` from `onClose()`.

### Option B — Add a mounted/closed guard around the callback

Track whether the controller is closed and return early from the callback when
it is no longer active.

### Option C — Move availability observation to a shared cart-level owner

Remove per-detail observers and create one shared service/controller that
refreshes availability for the currently relevant deal IDs.

### Option D — Make the cart service push availability updates directly

Have cart mutations refresh affected deals through a repository/service layer,
so detail controllers only observe their own state.

## Comparison

| Criterion | A: dispose Worker | B: guard callback | C: shared owner | D: cart-driven refresh |
| --- | --- | --- | --- | --- |
| Stops future callbacks | Yes, cancels subscription | No, callback still runs | Yes if owner lifecycle is correct | Yes for removed detail observers |
| Preserves live detail refresh | Yes | Yes | Requires routing state to active details | Requires new data flow |
| Scope | Small, one controller | Small, but incomplete cleanup | Broad architectural change | Broad service/repository change |
| Handles many detail pages | One disposable Worker per controller | Still one active subscription per page | Potentially efficient | Potentially efficient |
| Testability | Directly assert Worker disposal/call count | Must assert both guard and continuing work | Requires shared-owner integration tests | Requires cart/API integration tests |
| In-flight request behavior | Does not cancel an already started HTTP future | Does not cancel it | Depends on shared owner | Depends on service implementation |
| Risk | Low; matches resource owner | Medium; hides work instead of releasing it | High; changes ownership and behavior | High; changes cart responsibilities |

## Research evidence

- GetX 4.7.3 `ever(...)` returns a `Worker` wrapping a stream subscription.
- GetX 4.7.3 `Worker.dispose()` invokes the subscription cancellation callback
  and is safe to call once.
- The controller lifecycle hook available for cleanup is `onClose()`.
- Flutter/Dart cleanup principles require the owner of a listener/resource to
  release it when that owner is destroyed.

## Decision

Select **Option A**, with a closed-state response guard. The controller creates
the observer, so it retains and disposes that Worker in its own `onClose()`.
This prevents new cart-change callbacks from closed detail controllers while
preserving the current availability refresh behavior for a live controller. A
guard after the asynchronous repository call also prevents a previously
started request from changing closed controller state.

Worker disposal does not cancel an already in-flight `fetchById` future. The
controller therefore checks its closed state after awaiting the response and
discards a late successful result. The delayed-repository regression test
proved this guard is necessary. Transport cancellation remains out of scope
because `DealRepo` exposes no cancellation handle.

## Rejected alternatives

- **Option B** is rejected as the primary fix because it suppresses callback
  effects but leaves the subscription and its work alive.
- **Option C** is rejected for RES-103 because it broadens ownership and adds a
  shared-state design that the ticket does not require.
- **Option D** is rejected because it couples cart mutations to detail-page
  availability and changes service responsibilities beyond the defect.

## Next TDD gate

Before implementation, define the acceptance assertions and write a focused
test that proves a live controller refreshes and a disposed controller does
not. The test must fail against the current source before the Worker disposal
change.
