# RES-101 — TDD Readiness Gate

## Acceptance criteria

1. After overlapping searches, only the latest query may update `results`,
   `isLoading`, and search state.
2. Clearing the input invalidates every request that started before the clear.
3. A live latest query still displays its own results after the guard is added.

## Test design

| Item | Decision |
| --- | --- |
| Test level | Focused controller test. |
| Deterministic inputs | Test `DealRepo` returns independently completable Futures for each query. |
| RED signal | Start `sushi`, then `bakery`; complete `bakery` first and `sushi` last. Current controller exposes `sushi`, the stale list. |
| GREEN assertion | Results remain `bakery` after the stale `sushi` Future completes. |
| Follow-up test | Clear input while a request is in flight; its later completion must not repopulate results. |

## Edge and scope decisions

- Each input event, including an empty one, must increment the request
  generation.
- The test uses distinct result lists so the failure is visible and does not
  depend on simulated latency.
- No debounce is added. The request generation is the correctness mechanism.
- Route closure and transport cancellation are follow-up limits, not required
  to prove stale-result prevention in this ticket.

## Expected files and checks

| Category | Files |
| --- | --- |
| Protected | `lib/service/fake_api_service.dart`, `assets/data/` |
| RED test | `test/search_deals_controller_test.dart` |
| GREEN implementation | `lib/feature/search/search_deals_controller.dart` |
| Evidence | `solutions.md`, `docs/assessment/` |

```sh
/Users/amonrit/fvm/versions/3.27.0/bin/flutter test test/search_deals_controller_test.dart
/Users/amonrit/fvm/versions/3.27.0/bin/flutter analyze
/Users/amonrit/fvm/versions/3.27.0/bin/flutter test
git diff --check
```

## RED result

The focused test completed `bakery` first and verified that its result was
shown. It then completed the older `sushi` Future. The final assertion expected
`bakery`, but the controller exposed `sushi` instead. This is the intended RED
signal: an older completion overwrites the latest query's result.

Command: `/Users/amonrit/fvm/versions/3.27.0/bin/flutter test test/search_deals_controller_test.dart`.

## GREEN result

After E1, the same deterministic completion order passed: `bakery` completed
first, then the older `sushi` completion was ignored. The focused command
completed with one passing test on 2026-09-16. The clear-input boundary remains
the next dedicated regression test (E3).
