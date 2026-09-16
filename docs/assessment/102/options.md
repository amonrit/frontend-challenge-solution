# RES-102 — Options and Decision

## Problem boundary

`PickupCountdown` creates a `Timer.periodic` in widget state. The timer must
stop when that state is disposed, while mounted countdown text must continue to
update.

## Options

| Option | Resource released? | Strength | Limitation | Decision |
| --- | --- | --- | --- | --- |
| Store timer and cancel in `dispose()` | Yes | Matches the creator's lifecycle | Requires retaining one field | Selected |
| Check `mounted` before `setState` | No | Prevents the exception | Leaves periodic work alive | Rejected |
| Cancel when pickup opens | Sometimes | May reduce idle ticks | Does not cover route removal | Rejected |
| Move ticking to controller/global service | Depends | Could support shared countdowns | Broadens ownership and scope | Deferred to F-1 |

## Decision rationale

Widget-owned cancellation is the smallest complete fix. It releases the actual
resource at the lifecycle boundary that owns it and preserves independent
behavior for multiple countdown instances. An injected clock remains a narrow
test seam with `DateTime.now` as the production default.
