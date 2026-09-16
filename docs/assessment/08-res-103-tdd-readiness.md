# RES-103 — TDD Readiness Gate

## Acceptance criteria

1. A live `DealDetailsController` refreshes its deal availability when the
   cart item count changes.
2. Once that controller closes, later cart changes do not call
   `DealRepo.fetchById` for its deal.
3. Every active detail controller owns only its own observer; closing one does
   not stop refreshes for a different live controller.

## Test design

| Item | Decision |
| --- | --- |
| Test level | Focused controller test. It triggers the real `CartService.itemCount` observable and counts calls through a test `DealRepo`. |
| Deterministic inputs | Fixed `DealModel` fixture, in-memory cart, and a repository whose `fetchById` completes immediately. |
| RED signal | After `controller.onClose()`, a second cart change still increments the repository call count because the unretained Worker remains subscribed. |
| GREEN assertion | The first cart change produces exactly one fetch; the second cart change after `onClose()` produces no additional fetch. |
| Multi-controller follow-up | A second live controller continues to fetch after the first closes. |

## Edge and failure cases

- The same deal can be added more than once; every successful quantity change
  updates `itemCount` and should exercise the observer.
- `onClose()` may be called only once by GetX, but Worker disposal should be
  safe if cleanup is invoked defensively.
- This test does not assert cancellation of an already-started request. The
  selected scope is prevention of future cart-change callbacks.
- The test calls `onInit()` and `onClose()` directly to make controller
  resource ownership deterministic; route-level lifecycle coverage is planned
  during verification.

## Protected and expected files

| Category | Files |
| --- | --- |
| Protected | `lib/service/fake_api_service.dart`, `assets/data/` |
| Expected RED test | `test/deal_details_controller_test.dart` |
| Expected GREEN implementation | `lib/feature/deal/deal_details_controller.dart` |
| Evidence | `solutions.md`, `docs/assessment/` |

## Commands

```sh
/Users/amonrit/fvm/versions/3.27.0/bin/flutter test test/deal_details_controller_test.dart
/Users/amonrit/fvm/versions/3.27.0/bin/flutter analyze
/Users/amonrit/fvm/versions/3.27.0/bin/flutter test
git diff --check
```

## Manual verification after GREEN

Open deal 1, 2, and 3 and back out of each. Open deal 4 and tap **Add to bag**.
Only deal 4 should produce one `GET /deals/4` request.

## RED result

The focused test was run against the unmodified production controller:

```text
Expected: <1>
Actual:   <2>
```

The first cart change called the counting repository once. After
`controller.onClose()`, the second cart change called it again. The console
also logged `re-checking availability for deal 1` twice. This is the intended
RED signal: closing the controller does not currently release the `ever`
observer.

The first run exposed a test-fixture compilation mistake (`DateTime` is not a
const constructor). The fixture was corrected before accepting the RED result;
no production code was changed.

## GREEN result

After E1 retained and disposed the GetX Worker in `onClose()`, the same focused
test passed with one availability refresh before close and none after close:

```text
All tests passed!
```

Command: `/Users/amonrit/fvm/versions/3.27.0/bin/flutter test test/deal_details_controller_test.dart`.
