# RES-104 — Evidence-Backed Answers

This phase records the pre-change evidence only. No RES-104 production code or
regression test has been added yet.

## Current behavior and request ownership

| Question | Evidence-backed answer | Evidence |
| --- | --- | --- |
| 2.3 | The fake paginated endpoint waits a random 250–950 ms before returning, so overlapping completion order is possible. | `lib/service/fake_api_service.dart` |
| 3.1 | `HomeController` owns the observable `deals` list, `_page`, `_totalPages`, `_isFetchingMore`, and both refresh/load-more callbacks. | `lib/feature/home/home_controller.dart` |
| 3.2 | `refreshDeals()` resets `_page` to 1 and replaces the list after its await; `loadMore()` increments `_page` before awaiting and appends after its await. | `home_controller.dart` |
| 3.4 | `_isFetchingMore` prevents concurrent load-more calls, but refresh has no equivalent coordination or request-round identity. | `home_controller.dart` |
| 4.1 | `PagedResponseModel` carries `items`, the response `page`, and `totalPages`; `hasMore` compares page with total pages. | `lib/model/paged_response_model.dart` |
| 4.4 | Pagination is one-based: the repository requests `page: 1` for refresh and increments from the current page for load-more. | `home_controller.dart`; `lib/repository/deal_repo.dart` |

## Before measurement

### Source-level overlap trace

The current code permits this deterministic ordering trace:

```text
Initial state: deals = page 1, _page = 1
1. loadMore starts → _page becomes 2 → request page 2 is in flight
2. refresh starts → _page becomes 1 → request page 1 is in flight
3. refresh returns → deals is replaced with page 1
4. older page-2 response returns → page 2 is appended to the refreshed list
```

This is a source-derived measurement of state transitions, not a claim about a
specific random runtime timing. The fake API's 250–950 ms delay provides the
overlap window needed to reproduce it; a deterministic delayed repository will
be required for the RED test.

### Baseline commands

| Check | Before result | Command |
| --- | --- | --- |
| Full test suite | 13 tests passed | `/Users/amonrit/fvm/versions/3.27.0/bin/flutter test` |
| Static analysis | No issues | `/Users/amonrit/fvm/versions/3.27.0/bin/flutter analyze` (previous project baseline) |
| RES-104 focused regression | Not available yet; no test exists before Phase 4 | `test/home_controller_test.dart` to be added later |
| Runtime request measurement | Pending; no RES-104 runtime trace recorded yet | Home overlap flow to be run after a deterministic seam is prepared |

## Protected files and limits

- `lib/service/fake_api_service.dart` and `assets/data/` remain read-only.
- The current source inspection does not establish whether the backend can
  return duplicate IDs across pages; that requires evidence or an injected test
  repository.
- No change, after measurement, or post-fix result exists in this phase.

## Next evidence needed

1. Create a delayed fake repository that controls page-1/page-2 completion
   order without modifying the protected fake API.
2. Run the RED test against the current controller and capture the duplicated
   or stale final item IDs.
3. Compare candidate request-round and serialization designs before choosing
   the implementation.
