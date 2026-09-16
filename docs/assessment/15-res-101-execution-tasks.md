# RES-101 — Execution Tasks

These tasks implement the selected monotonic request generation guard. Execute
only one task per user-approved `next`.

| ID | Task | Files | Dependency | Acceptance assertion | Status |
| --- | --- | --- | --- | --- | --- |
| E1 | Add request-generation ownership to Search and gate result/loading mutations. | `lib/feature/search/search_deals_controller.dart` | RED stale-response test | A stale completion cannot replace the latest result or loading state. | Complete; GREEN verification pending E2 |
| E2 | Run and record focused GREEN result for the stale-response test. | test and evidence docs | E1 | `flutter test test/search_deals_controller_test.dart` passes. | Complete; 1 test passed on 2026-09-16 |
| E3 | Add clear-input regression coverage. | `test/search_deals_controller_test.dart` | E2 | A response that started before clear cannot repopulate results or restore searched state. | Complete; focused suite passed 2 tests on 2026-09-16 |
| E4 | Run automated quality gates. | tests, `solutions.md` | E3 | Focused suite, full suite, analyzer, and diff check pass. | Complete; focused 2 tests, full 9 tests, analyzer and diff check passed on 2026-09-16 |
| E5 | Repeat the rapid-input manual comparison. | `solutions.md`, assessment evidence | E4 | Late old responses do not replace the final query's UI state. | Next |

## E1 implementation variants

| Variant | How it works | Decision |
| --- | --- | --- |
| Integer generation | Increment on every input event, capture before await, apply all state only if it still matches. | Selected: unique request identity, clear invalidation, no repository changes. |
| Latest normalized query text | Apply only if the request query equals a stored current query. | Rejected: identical query text can represent different requests. |
| Per-request `isLoading` counter | Count outstanding requests and display loading while count is non-zero. | Not selected: it describes network activity, not whether the latest query is loading; it adds state beyond ticket needs. |

## E3 test variants

| Variant | How it works | Decision |
| --- | --- | --- |
| Controlled Future completes after clear | Start a query, clear input, complete the old Future, assert prompt state and empty results remain. | Selected: directly covers invalidation boundary. |
| Widget test with fake delays | Enter text and clear TextField while a delayed repository responds. | Useful integration follow-up, but slower and less focused. |
| Manual-only check | Clear input during real simulated latency. | Rejected as primary regression coverage because response timing is random. |

## E4 verification commands

```sh
/Users/amonrit/fvm/versions/3.27.0/bin/flutter test test/search_deals_controller_test.dart
/Users/amonrit/fvm/versions/3.27.0/bin/flutter test
/Users/amonrit/fvm/versions/3.27.0/bin/flutter analyze
git diff --check
```

## Stop conditions

- If E1 does not make the RED test GREEN, inspect whether every state mutation
  after `await` is protected by the captured generation.
- If E3 fails, do not restore stale results merely to avoid an empty screen;
  clearing input is an explicit invalidation event.
- If manual verification shows an old query after the final input, return to
  the request-generation ownership rather than adding debounce as a patch.
