# F-3 — Stock Reservations: Requirement Questions

## Required outcome and user experience

1. What must appear immediately after an add action: a line at the requested
   quantity, a reserving state, both, or only a confirmation after the API
   returns?
2. Which cart interactions must be disabled while an add, release, adjustment,
   or checkout request for the same deal is pending?
3. What plain-language notice tells a user that a contested reservation was
   rolled back without exposing HTTP status codes or backend details?
4. If an existing cart line is incremented optimistically and the new hold
   fails, which previous quantity, reservation id, and countdown must be
   restored?
5. May two rapid taps on Add create overlapping reservations for one deal, and
   what visible quantity should win while they are unresolved?
6. How should a reservation response whose quantity differs from the requested
   quantity be presented, if that is possible under the API contract?

## Reservation ownership and lifecycle

7. Which app-scoped object owns reservation state, in-flight operations, and
   expiry timers so state survives cart-screen/controller recreation?
8. Is a cart line with no reservation temporarily valid while its optimistic
   reservation request is pending, and can it enter checkout?
9. What uniquely associates a reservation with a cart line when the same deal
   is added, removed, and added again before earlier async work completes?
10. How does the client prevent a delayed reserve success from restoring a line
    the user removed while that request was in flight?
11. Does app backgrounding pause the displayed countdown, continue it from a
    wall clock, or force revalidation on resume?
12. Should closing the app or disposing the app-scoped cart attempt release,
    given that a process can be terminated before an asynchronous release
    completes?
13. How does existing flash-sale expiration removal release a still-valid stock
    reservation for the removed cart line?

## Quantity changes and release semantics

14. Does the backend offer a reservation-adjustment operation, or must a
    quantity change release and create a new reservation?
15. When decrementing a line, must the remaining quantity retain an existing
    reservation, receive a replacement reservation, or be removed and
    re-reserved?
16. If changing quantity needs release followed by reserve, what protects the
    user from the gap where stock can be claimed by another shopper?
17. If the release request fails after the line was removed locally, should the
    line return, should release retry, or should the failure only be logged?
18. On cart clear after a successful checkout, should every reservation be
    explicitly released, or does the checkout contract consume them?
19. What happens if a user removes a line while checkout is in flight?

## Expiry and checkout policy

20. Is the server-provided `expiresAt` authoritative for the countdown, and
    which timezone/clock representation prevents a device-timezone error?
21. At the displayed expiry instant, should the app immediately remove the line,
    leave it visibly expired until user action, or attempt a new reservation?
22. What happens if expiry occurs after Checkout is tapped but before the server
    validates reservation ids?
23. If checkout returns 410 for one expired reservation in a multi-line bag,
    should the app remove only affected lines, preserve all lines, or retry the
    remaining valid lines? How can it know which line expired from the contract?
24. After a 410, should the app automatically attempt to reserve again, require
    the user to add again, or offer an explicit retry action?
25. What user-facing message and logging policy distinguish 410 expiry from
    transient checkout failures such as a 502?
26. Can checkout start with a pending, missing, or locally expired reservation
    id, and what guard prevents an invalid request?

## Existing contract and data questions

27. What exactly do `OrderRepo.reserve`, `releaseReservation`, and `checkout`
    accept, return, and throw, including 409, 410, latency, and intermittent
    failure behavior?
28. Does a successful checkout consume every supplied reservation, and does it
    validate deal id and quantity against the reservation?
29. Which fields in `ReservationModel` and `CartItemModel` already exist, and
    which state still needs a model, service, or presentation boundary?
30. Which current add, decrement, remove, clear, flash-expiry, and checkout
    call sites bypass a reservation-aware operation today?
31. What GetX registration lifetime does `CartService` have, and can it safely
    depend on `OrderRepo` without a circular dependency?

## Observability, test, and evidence questions

32. Which logs or debug UI state can distinguish a reserve request, optimistic
    line, confirmed hold, release attempt, expiry, rollback, and checkout 410?
33. What deterministic clock/timer seam can test a five-minute countdown and
    expiry without waiting in real time?
34. What controllable repository or API seam can force reserve success, 409,
    release failure, delayed completion, checkout 410, and checkout 502?
35. Which unit tests prove that stale async completions cannot resurrect or
    corrupt cart state after removal, decrement, expiry, or a newer add?
36. Which widget tests prove countdown display, disabled checkout states, and
    clear recovery messages without depending on a real snackbar animation?
37. Which integration/manual flows prove optimistic rollback, release on each
    quantity path, expiration during use, and 410 recovery with the real fake
    backend?
38. What profile-mode scenario verifies that per-line reservation countdowns do
    not rebuild the full cart or create a periodic timer per line?
