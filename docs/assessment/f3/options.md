# F-3 — Stock Reservations: Options and Decision

## Confirmed problem boundary

The current cart mutates synchronously and locally, while the existing backend
has asynchronous create/release operations, five-minute reservation expiry, and
checkout rejection for unknown or expired ids. A cart line presently holds only
one nullable reservation. There is no backend adjustment endpoint, and a 410
does not identify the failing cart line.

The design must preserve a user removal against late async completion, prevent
checkout of a non-reserved line, and avoid a timer or full-cart rebuild per
reservation countdown.

## Reservation ownership options

| Option | Correctness and lifecycle | Performance | Testability and maintenance | Decision |
| --- | --- | --- | --- | --- |
| Put reserve/release orchestration in `CartController` | Route-local controller can be recreated while an operation is pending, despite reservations belonging to the app-wide bag. Other add paths would bypass it. | No inherent timer cost. | Duplicates cart rules across details and cart screens. | Reject |
| Create a second app-scoped `ReservationService` that mirrors cart state | Can own async work, but introduces two mutable sources of truth and cross-service coordination for add/remove/expiry. | Can share one clock. | More indirection and synchronization tests than this task needs. | Reject |
| Extend app-scoped `CartService` with an injected reservation gateway | Keeps a line, its reservation state, mutations, and async generation token under one permanent owner. All screens call the same boundary. | Reuses the existing app clock; leaf widgets can observe time. | A small gateway interface and controlled clock make races deterministic. | **Select** |

## Quantity-change options

| Option | Correctness and user impact | Cost | Decision |
| --- | --- | --- | --- |
| Change local quantity only and retain the prior hold | Checkout quantity can exceed the held quantity; violates stock guarantee. | Smallest diff, unsafe. | Reject |
| Release old hold, then reserve replacement quantity | A failed reserve loses the user's valid old hold during the gap. | Simple API sequence, poor failure behavior. | Reject |
| Reserve the replacement quantity first, then replace the line's hold and best-effort release the old id | A failed replacement preserves the old confirmed line. A brief duplicate hold is possible, but it avoids giving up a valid hold before a new one exists. | Requires per-line pending state and an operation generation. | **Select** |
| Represent each increment as an independent hold | Avoids replacement but requires multiple cart lines or changing the checkout/model shape to carry several ids per displayed line. | Larger UI/model change; API is currently one id per item. | Reject |

The selected replacement sequence is also used for decrement. The UI first
shows the requested quantity as pending; a successful replacement becomes the
only confirmed hold and releases the former id. If replacement fails, the
previous quantity and reservation stay in place. This is deliberately not
called an atomic adjustment: the backend offers none.

## Expiry policy options

| Option | Correctness and user impact | Decision |
| --- | --- | --- |
| Keep an expired line and let checkout discover it | Gives users a stale bag and delays actionable feedback. | Reject |
| Auto-reserve again at expiry | Can unexpectedly reserve stock, may repeatedly contend, and changes the user’s intent. | Reject |
| Remove the locally expired line immediately, release best-effort, and show a clear notice; require an explicit add to reserve again | Does not present an uncheckoutable line as available and makes a new hold a deliberate user action. | **Select** |

`expiresAt` remains the server-provided UTC authority. The existing app-scoped
clock supplies wall-clock refresh and resume reconciliation; it does not create
one timer per cart line. A countdown leaf derives its label from this clock,
while CartService removes only lines that have actually expired.

For checkout, the selected policy is:

1. Block checkout while any line is pending or locally expired.
2. On a server 410, retain no claimed-valid reservation state: invalidate and
   remove all cart lines that were part of the request, then show one message
   asking the user to add items again.
3. Do not automatically reserve again. The 410 contract does not identify the
   failing line, so keeping other lines as guaranteed would be an unsupported
   claim.
4. On a non-410 checkout failure such as 502, keep confirmed cart lines and
   their countdowns for a user-initiated retry.

The all-lines 410 recovery is conservative. It sacrifices a potentially valid
line to avoid presenting a cart as reservable when the server has rejected an
unknown member of the request without identifying it.

## Async and release policy

For the first-add operation, object identity is the invalidation boundary: a
completion may attach its hold only while its exact optimistic `CartItemModel`
is still in `items`; otherwise it releases the late hold. The E2
remove-and-readd regression test passed before adding a generation map, so a
separate counter would be redundant at this stage. E3 will add a per-line
operation generation where it is needed: replacement changes quantity while
the same line remains in the cart, so object presence alone cannot distinguish
an older completion from the newer request.

Removal, flash-sale expiry, successful checkout cleanup, and replacement all
release superseded ids best-effort. A release failure is logged but never
restores a line the user removed or reverses a successful checkout; the server
hold still has its five-minute expiry. The backend currently does not simulate
release failure, so this branch needs a client-controlled gateway test seam.

## Test seam options

| Option | Result | Decision |
| --- | --- | --- |
| Test through `FakeApiService` mutation counter and real latency | Couples tests to global call order and waits hundreds of milliseconds; cannot deterministically force every race. | Reject |
| Inject `OrderRepo` directly | Its concrete type is tied to the fake API and lacks controlled failure hooks. | Reject |
| Define a narrow reservation/checkout gateway and inject clock functions into CartService | Tests can supply delayed completers, 409/410/502 responses, release failure, and controlled expiry. Production adapter remains `OrderRepo`. | **Select** |

## Trade-offs

- One reservation per displayed line keeps checkout compatible with its current
  payload but makes quantity changes a replacement operation rather than a true
  server-side adjustment.
- Optimistic pending state improves response time but requires disabling or
  serializing same-line mutations until the operation settles.
- Conservative all-lines removal on 410 protects stock correctness, while a
  future backend that returns the failed reservation id could support targeted
  recovery.
- Reusing the existing clock avoids another periodic service, but its time
  semantics must stay independent of flash-sale domain wording in the UI.
