# RES-102 — Evidence-Backed Answers

This file answers only questions supported by the ticket, current source, or primary Flutter/Dart documentation. Question numbers refer to [01-res-102-questions.md](01-res-102-questions.md).

## 1. Required Outcome

| Question | Answer | Evidence |
| --- | --- | --- |
| 1.1 | A user opens My orders while an order has an upcoming pickup, leaves the screen, and must not encounter `setState() called after dispose()` within the following timer ticks. | `PROBLEM.md`, RES-102. |
| 1.3 | The ticket explicitly requires that the debug crash stops. Releasing callback-producing resources is also the correct lifecycle behavior: Flutter says `dispose()` releases resources retained by `State`, and calling `setState()` after disposal is an error. | [Flutter `State.dispose`](https://api.flutter.dev/flutter/widgets/State/dispose.html). |
| 1.4 | While mounted, the widget must retain its current role: display “Opens in …” and update its displayed remaining time every second. | `pickup_countdown.dart`: existing `Timer.periodic(Duration(seconds: 1))` and display logic. |
| 1.5 | No new pickup-window behavior is required by RES-102. The current text for a past pickup start is “Pickup window is open”; changing terminal countdown behavior belongs to a separately scoped decision. | `PROBLEM.md`, RES-102; `pickup_countdown.dart`. |
| 1.6 | The assessment requires reproduction, root-cause diagnosis, a proper fix, verification, and written diagnosis for each selected ticket. | `PROBLEM.md`, Part A. |

## 2. Current Behavior and Reproduction

| Question | Answer | Evidence |
| --- | --- | --- |
| 2.2 | Three bundled active orders should render countdowns: IDs 9001 (`READY`, pickup in 18 minutes), 9002 (`CONFIRMED`, 47 minutes), and 9003 (`CONFIRMED`, 132 minutes). | `assets/data/orders.json`; `OrderModel.isActive`; `orders_screen.dart`. |
| 2.5 | The app-bar back action and a standard back gesture both remove the pushed route through Flutter navigation. The ticket explicitly names back navigation; other route-removal paths need a scope decision before being acceptance criteria. | `PROBLEM.md`, RES-102; `routes.dart`. |
| 2.9 | The only callback that directly calls `setState()` in the orders countdown path is the callback passed to `Timer.periodic` in `PickupCountdown.initState()`. | `pickup_countdown.dart`; repository search for `Timer.periodic` and `setState`. |

## 3. Lifecycle and Ownership

| Question | Answer | Evidence |
| --- | --- | --- |
| 3.1 | `PickupCountdown.initState()` creates the repeating timer. | `pickup_countdown.dart`. |
| 3.2 | `_PickupCountdownState` owns the timer because it creates it and the callback calls that state object’s `setState()`. | `pickup_countdown.dart`; [Flutter `State.dispose`](https://api.flutter.dev/flutter/widgets/State/dispose.html). |
| 3.3 | Flutter calls `State.dispose()` when the state object is permanently removed from the tree; it will not build again afterward. | [Flutter `State.dispose`](https://api.flutter.dev/flutter/widgets/State/dispose.html). |
| 3.4 | A `Timer.periodic` callback continues at its configured interval until its timer is cancelled. | [Dart `Timer.periodic`](https://api.dart.dev/dart-async/Timer/Timer.periodic.html). |
| 3.5 | Multiple instances can exist because each active-order tile constructs its own `PickupCountdown`. | `orders_screen.dart`. |
| 3.6 | Each countdown instance has independent lifecycle responsibility because each creates its own periodic timer. | `orders_screen.dart`; `pickup_countdown.dart`. |
| 3.7 | The route and `OrdersController` can outlive an individual list child; the countdown widget is a descendant of the list. | `orders_screen.dart`; Flutter widget-tree ownership model. |
| 3.8 | In the current orders feature, the only repeating callback found is the countdown’s `Timer.periodic`. The controller does not create a timer, Worker, subscription, or animation controller. | Repository search of `lib/feature/order/`. |

## 4. Scope and Constraints

| Question | Answer | Evidence |
| --- | --- | --- |
| 4.2 | Yes. The bundled orders data includes future pickup times for active orders, so no protected backend or asset modification is needed for the documented flow. | `assets/data/orders.json`; `FakeApiService._enrichOrder`. |
| 4.3 | Flutter 3.27.0 is pinned by the assessment and `.fvmrc`; validation must use that version. | `PROBLEM.md`; `.fvmrc`. |
| 4.4 | RES-102 must remain separate from RES-103 and F-1 for commit and diagnosis clarity. The assessment requires one logical change per commit. | `PROBLEM.md`, Ground rules. |
| 4.5 | No. A shared countdown abstraction is not required to solve the stated lifecycle defect and would broaden the ticket. | `PROBLEM.md`, diagnosis-quality and commit-scope guidance. |
| 4.6 | The active countdown text and its one-second refresh while mounted are existing behavior that must not regress. | `pickup_countdown.dart`. |

## 7. Research Questions

| Question | Answer | Evidence |
| --- | --- | --- |
| 7.1 | Flutter documents `dispose()` as the terminal lifecycle stage. A disposed state is unmounted, may not receive `setState()`, and should release retained resources. | [Flutter `State.dispose`](https://api.flutter.dev/flutter/widgets/State/dispose.html). |
| 7.2 | Dart documents that periodic timers repeat until cancellation; scheduling timing is not guaranteed to be exact. | [Dart `Timer.periodic`](https://api.dart.dev/dart-async/Timer/Timer.periodic.html). |

## Questions Still Requiring Evidence or a Scope Decision

The following are intentionally unanswered until the next investigation phase:

- Runtime observations: 2.1, 2.3, 2.4, 2.6–2.8.
- Disposal timing and race behavior: 3.9.
- All edge-case questions in section 5.
- The complete solution comparison in section 6.
- Test-tool and test-design questions 7.3–7.6 and section 8.

## Scope Decision Needed

Should RES-102’s acceptance criteria cover **every path that disposes a `PickupCountdown`** (including removal from the list during rebuild), or only the documented action of navigating back from My orders?

My recommendation is every disposal path, because the same widget-owned callback can survive any disposal path. However, I will not turn that recommendation into a requirement without your direction.
