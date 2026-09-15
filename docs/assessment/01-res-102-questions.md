# RES-102 — Questions Before Task Breakdown

## 1. Required Outcome

1. What exact user journey must be safe after this ticket is complete?
2. Does “navigate back” mean only the back button, or every way the Orders route can be removed?
3. Is the requirement only that debug mode no longer throws, or must all work associated with removed countdowns stop as well?
4. What user-visible behavior must remain unchanged while an order countdown is still on screen?
5. Does this ticket include behavior after the pickup window opens, or only disposal safety?
6. What evidence will be sufficient to call this ticket complete?

## 2. Current Behavior and Reproduction

1. Can the reported `setState() called after dispose()` error be reproduced in the current revision?
2. Which active order and countdown instance trigger it?
3. How long after leaving My orders does the error occur?
4. Does it occur on every navigation attempt or intermittently?
5. Does it occur when leaving through the app bar back button, gesture navigation, replacement navigation, and system back navigation?
6. Does it occur with one active order, several active orders, or both?
7. Does scrolling a countdown off screen cause the same lifecycle failure?
8. Does reloading the orders list while countdowns are visible create or dispose countdown instances in a way that changes the result?
9. What logs, Flutter error reports, or stack traces identify the failing callback?

## 3. Lifecycle and Ownership

1. Which object creates the repeating work that updates the countdown?
2. Which object owns that resource for its full lifetime?
3. When exactly is that owner disposed?
4. What happens to the repeating work after the owner is disposed?
5. Can multiple countdown instances exist at once?
6. Does each instance have independent cleanup responsibilities?
7. Can the controller, route, list, or parent widget outlive an individual countdown widget?
8. Are there other timers, stream subscriptions, GetX Workers, animation controllers, or listeners involved in the same screen?
9. Could a callback fire while the widget is being removed or rebuilt?

## 4. Scope and Constraints

1. Which files are in scope for a lifecycle fix, and which files should remain untouched?
2. Can the issue be reproduced using bundled orders without changing protected backend or asset files?
3. Does the pinned Flutter version affect available testing or timer APIs?
4. Must the change remain isolated from RES-103 and F-1 countdown work?
5. Would a shared countdown abstraction be justified by this ticket alone?
6. What existing behavior would be at risk if the timer lifecycle changes?
7. What should happen if an order changes from active to past while the screen remains visible?
8. Is resource cleanup required when a card leaves the widget tree for reasons other than route navigation?

## 5. Edge Cases

1. What happens when the pickup start time is already in the past at widget creation?
2. What happens when the pickup start time passes while the widget is visible?
3. What happens when several countdowns tick at the same moment?
4. What happens when a user repeatedly opens and closes My orders quickly?
5. What happens when a screen is removed before the first timer tick?
6. What happens when a screen is removed immediately after a timer tick?
7. What happens when the device is backgrounded and later resumed?
8. What happens when order loading fails, retries, or replaces the current list?
9. What happens when an active order is removed from the list during a rebuild?

## 6. Possible Solution Space

1. What are all reasonable ways to stop or prevent post-disposal callbacks?
2. Which options release the resource itself, and which only suppress a visible exception?
3. Which option matches the actual owner’s lifecycle?
4. Which option preserves periodic updates while the widget is mounted?
5. Which option handles multiple countdown instances safely?
6. Which option has the smallest scope and lowest regression risk?
7. Which option is easiest to explain and verify in an interview?
8. Which options should be rejected, and what evidence would justify rejecting them?

## 7. Research Questions

1. What does Flutter document about `State.dispose()` and asynchronous callbacks?
2. What does Dart document about `Timer.periodic`, cancellation, and callback lifetime?
3. What lifecycle guarantees apply when Flutter removes a stateful list child or route?
4. What test tools can advance periodic timer time deterministically?
5. What testing pattern best captures framework errors caused by callbacks after disposal?
6. Are there Flutter version-specific considerations for the pinned SDK version?

## 8. Verification and Comparison

1. What is the exact baseline reproduction script?
2. What signal proves that the pre-change behavior fails?
3. What targeted automated test would fail before a correct fix and pass afterward?
4. How can the test advance time without waiting for real seconds?
5. How can the test verify that the countdown still updates while mounted?
6. How can repeated route entry and exit be verified without leaving active callbacks behind?
7. What manual regression flow should be run on the app after automated tests pass?
8. What logs or error capture should be retained as evidence?
9. What unrelated tests and checks must pass before committing?
