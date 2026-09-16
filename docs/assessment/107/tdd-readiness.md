# RES-107 — TDD Readiness Gate

## Acceptance criteria

1. A `/deal?id=42&source=push` route with no model argument loads deal 42 and
   renders the existing details content.
2. A normal card route that supplies a `DealModel` still loads immediately and
   does not make an unnecessary initial ID request.
3. Loading, invalid ID, and repository failure states are explicit and do not
   crash the details screen.
4. A controller that closes while loading cannot mutate state after closure.

## First RED test

| Item | Decision |
| --- | --- |
| Test level | Focused controller test with an injected fake `DealRepo`. |
| Deterministic input | `Get.arguments == null`, route represents `id=42`, repository returns a fixed deal. |
| RED signal | Current `onInit()` force-casts null `Get.arguments` to `DealModel`, throwing before `fetchById` can run. |
| GREEN assertion | The controller requests ID 42, reaches loaded state, and exposes the returned deal. |
| Scope | This first test isolates the missing-argument crash; loading/error and normal-argument coverage follow as separate tests. |

## Edge and failure cases to cover

- Existing `DealModel` argument remains the fast path.
- Valid numeric ID loads through `DealRepo.fetchById`.
- Missing, nonnumeric, and unknown IDs become user-visible error states.
- Repository latency exposes loading before the model arrives.
- A late completion after controller close is ignored.
- Cart availability observation starts only after a model has loaded.

## Expected files and checks

| Category | Files |
| --- | --- |
| Protected | `lib/service/fake_api_service.dart`, `assets/data/` |
| RED test | `test/deal_details_deep_link_test.dart` |
| GREEN implementation | `lib/feature/deal/deal_details_controller.dart`, `lib/feature/deal/deal_details_screen.dart` |
| Evidence | `solutions.md`, `docs/assessment/` |

```sh
/Users/amonrit/fvm/versions/3.27.0/bin/flutter test test/deal_details_deep_link_test.dart
/Users/amonrit/fvm/versions/3.27.0/bin/flutter analyze
```

## RED result

The focused test failed before any repository call with:
`type 'Null' is not a subtype of type 'DealModel' in type cast` at
`DealDetailsController.onInit()`. This is the intended failure: the deep-link
route has an ID but no model argument, and the current controller force-casts
the missing argument.

Command: `/Users/amonrit/fvm/versions/3.27.0/bin/flutter test test/deal_details_deep_link_test.dart`.
