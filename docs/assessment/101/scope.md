# RES-101 — Scope and Workflow State

## Requested outcome

When a user types a query quickly, the results shown on Search must correspond
to the text currently in the input. A response for an older query must not
replace the newer query's results, including after the input is cleared.

## Assignment constraints

- Reproduce the wrong-result behavior before changing production code.
- Establish request ordering and state ownership from source and runtime
  evidence.
- Treat debounce as a possible optimisation, not assumed correctness.
- Keep the fix isolated to RES-101; do not combine it with other tickets.
- Do not modify `lib/service/fake_api_service.dart` or `assets/data/`.
- Use Flutter 3.27.0 and preserve the existing GetX/layered architecture.
- Record diagnosis, alternatives, tests, and evidence in `solutions.md` and
  ticket assessment documents.
- Commit logical changes with a `[RES-101]` prefix only after explicit user
  instruction.

## Relevant source inspected

- `lib/feature/search/search_deals_controller.dart`
- `lib/feature/search/search_screen.dart`
- `lib/binding/search_binding.dart`
- `lib/repository/deal_repo.dart`
- `PROBLEM.md`

## Workflow state

- Status: complete through Phase 8 documentation currency audit.
- Production change: `SearchDealsController` uses a monotonic request
  generation to give the latest input exclusive ownership of post-await state.
- Evidence: deterministic RED/GREEN controller tests, full automated checks,
  and AppleScript-driven simulator checks are recorded in the linked
  assessment documents and `solutions.md`.

## Documentation currency audit

Audited through the shared 2026-09-18 verification. All RES-101 execution
tasks are complete and their evidence is reflected in the scope, answers,
options, TDD record, execution task list, and `solutions.md`. The seven-test
figure in the answers document is intentionally the pre-change baseline; the
nine-test figure is the then-current post-change full-suite result. The latest
shared suite passes 77 tests. Remaining acceptance-evidence entries in
`solutions.md` concern RES-105 and F-1 through F-3, not RES-101.
