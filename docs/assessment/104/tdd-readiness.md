# RES-104 — TDD Readiness Gate

## Acceptance criteria

1. A load-more response from an older request round cannot append after a
   newer refresh has replaced the feed.
2. A refresh result remains the complete current feed for page 1, with no stale
   page data appended.
3. Accepted page state remains consistent with the response that was accepted.
4. Existing initial load, refresh, and load-more behavior continues to work.

## Test design

| Item | Decision |
| --- | --- |
| Test level | HomeController unit test with an injected delayed `DealRepo`. |
| Deterministic input | Initial page 1 completes; page 2 starts; refresh page 1 completes first; old page 2 completes last. |
| Observable measurement | Record requested pages and final deal IDs/list length. |
| Protected seam | The test repository overrides `fetchDeals`; `fake_api_service.dart` and `assets/data/` remain untouched. |
| RED assertion | Final list must contain only refreshed page-1 ID `[3]`; current code appends stale page-2 ID `[4]`. |
| GREEN assertion | The same completion order leaves `[3]` and keeps page state at the refreshed round. |

## Edge and failure cases

- Two rapid refreshes: only the latest refresh may replace the list.
- Two load-more requests: existing guard must still prevent duplicate page
  requests.
- A stale response with a different `totalPages` must not change pagination
  state.
- A failed stale request must not overwrite the latest round's state.
- Controller closure while a request is pending must not mutate disposed state.

## Expected files and checks

| Category | Files |
| --- | --- |
| Protected | `lib/service/fake_api_service.dart`, `assets/data/` |
| RED test | `test/home_controller_test.dart` |
| GREEN implementation | `lib/feature/home/home_controller.dart` |
| Evidence | `solutions.md`, `docs/assessment/104/` |

```sh
/Users/amonrit/fvm/versions/3.27.0/bin/flutter test test/home_controller_test.dart
/Users/amonrit/fvm/versions/3.27.0/bin/flutter analyze
```

## RED result

The first run exposed an invalid test seam because `RefreshController` requires
an initialized Flutter binding. Adding `TestWidgetsFlutterBinding.ensureInitialized()`
fixed the seam without changing production code. The intended RED run then
failed with:

```text
Expected: [3]
Actual: [3, 4]
```

The failure proves the stale page-2 append through deterministic completion
order rather than random API latency.

No production implementation has started in this phase.
