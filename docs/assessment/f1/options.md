# F-1 — Live Flash-Sale Countdowns: Options and Decision

## Confirmed problem boundary

The current presentation has two independent static labels and no details
countdown. The cart is app-scoped but does not understand expiry. F-1 therefore
needs one consistent time policy across all surfaces, an app-lifetime expiry
path for cart contents, and a rendering boundary that does not rebuild a card
or Home list every second.

## Options comparison

| Option | Correctness and lifecycle | 100+ countdown performance | Cart expiry coverage | Testability and scope | Decision |
| --- | --- | --- | --- | --- | --- |
| A. A `Timer.periodic` in every countdown widget | Each widget can format its own text, but creates many timers and repeats RES-102 disposal risk. It cannot remove a cart item when no relevant widget is mounted. | Up to 100 timers and 100 independent callbacks per second; rebuild scope is harder to audit. | Requires another global mechanism. | Simple first widget, but inconsistent policy and many lifecycle owners. | Rejected. |
| B. A ticker in Home and another in details controllers | Reduces timers compared with A, but duplicates time state across routes and misses expiry while neither route is active. | Each controller can rebuild too much unless every observer is split carefully. | Still requires cart-specific expiry ownership. | Coupled to route lifetime; deep links and navigation complicate behavior. | Rejected. |
| C. One app-scoped clock service, pure flash-status projection, and leaf observers | One service owns one periodic timer and app-lifecycle refresh. Pure status/formatting gives every surface the same expiry rule. | Each countdown text observes the shared current instant; card/feed observers depend only on a one-time expiry state transition. | The service can publish expiry transitions to the app-scoped cart service. | Controlled clock and tick source make unit/widget tests deterministic; adds one focused service and root notice host. | Selected. |
| D. One `AnimationController`/ticker per visible countdown | Frame-synchronised display, but still allocates one controller per visible countdown and leaves cart expiry global work unresolved. | Better visual alignment than A, but unnecessary for a once-per-second label and still multiplies lifecycle ownership. | Requires another global mechanism. | More Flutter-specific setup and test complexity. | Rejected. |

## Selected design

Introduce a single app-scoped `FlashSaleClockService` that owns the periodic
tick, accepts an injectable `now` source for tests, and refreshes immediately
when the application returns to the foreground. It registers active flash end
instants and publishes a one-time expiry transition per deal. A pure
`FlashSaleStatus` helper determines active/expired state, remaining duration,
and the required `mm:ss` or `hh:mm:ss` label from an end instant and a supplied
current instant.

Each rail/card/detail countdown becomes a small reactive leaf that reads the
clock and rebuilds only its text each second. A separate expiry-state observer
changes interaction affordances only when the deal crosses into `Expired`; it
does not depend on every clock tick. The details add action and cart add path
both consult the same pure status rule, so a tap that races expiry is rejected
at the mutation boundary.

`CartService` remains the owner of cart mutation. On the service's one-time
expiry transition, it removes all quantities for that deal ID and emits a
one-shot notice event. A root-level notice host converts that event into the
existing snackbar style, keeping business mutation separate from presentation
and making repeated expiry notifications deduplicable.

## Research notes

- [Dart `Timer.periodic`](https://api.dart.dev/dart-async/Timer/Timer.periodic.html)
  creates a repeated callback; this supports one clock owner rather than one
  callback per visible countdown.
- [Flutter `WidgetsBindingObserver`](https://api.flutter.dev/flutter/widgets/WidgetsBindingObserver-class.html)
  receives foreground/background lifecycle notifications and must be removed
  when its owner is disposed.
- Existing RES-102 code demonstrates that a timer must be cancelled in
  `dispose`; the selected design centralizes that responsibility in the
  app-scoped service rather than repeating it across cards.

## Rejected alternatives and trade-offs

- A global `Obx` around Home or a deal card is rejected because it would rebuild
  expensive layout and image subtrees every second. The selected design adds
  more small widgets but limits per-second work to countdown text.
- Updating the cart only when its screen is open is rejected because expiry must
  remove items throughout the app session.
- Calling `Get.snackbar` directly from the clock service is rejected because it
  mixes time/expiry policy with UI presentation and makes notice behavior harder
  to test.
- The selected service must register and retire deal IDs carefully. Stale
  registrations would retain data or emit irrelevant expiry transitions; the
  execution plan must define registration ownership and cleanup.

## Decision limits

- The assignment does not specify server-clock synchronization. The selected
  design uses the existing device-clock model but keeps `now` injectable so a
  future server-offset policy has one replacement seam.
- Background timing is not assumed to be exact. On resume, the service reads
  the current instant and processes any elapsed expiry transitions immediately.
- DevTools must still verify 100+ countdown rebuild scope and runtime behavior;
  this comparison is not performance evidence.
