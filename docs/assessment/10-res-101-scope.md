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

- Current phase: Phase 0 complete.
- Next phase: create `docs/assessment/11-res-101-questions.md` containing
  questions only.
- Production code and tests: unchanged in this phase.
