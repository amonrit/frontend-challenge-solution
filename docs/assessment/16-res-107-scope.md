# RES-107 — Scope and Workflow State

## Requested outcome

Opening `rescu://open/deal?id=42&source=push` must land on a fully working
details page for deal 42. The same deal already opens from the Home feed.
Showing an error or fallback page is not an acceptable outcome for this ticket.

## Assignment constraints

- Reproduce the deep-link crash before changing production code.
- Establish how route parameters, optional in-app arguments, dependency
  binding, controller state, and repository loading interact.
- Cover the provided in-app deep-link simulation and retain compatibility with
  Home/flash-rail navigation.
- Provide loading and error handling for an ID-based route, including a deal
  that cannot be loaded.
- Keep the fix isolated to RES-107; do not combine it with unrelated tickets.
- Do not modify `lib/service/fake_api_service.dart` or anything under
  `assets/data/`.
- Use Flutter 3.27.0 and preserve the existing GetX/layered architecture.
- Record diagnosis, alternatives, tests, and evidence in `solutions.md` and
  ticket assessment documents.
- Commit logical changes with a `[RES-107]` prefix only after explicit user
  instruction.

## Relevant source inspected

- `PROBLEM.md`
- `lib/feature/home/home_screen.dart`
- `lib/routes/routes.dart`
- `lib/binding/deal_details_binding.dart`
- `lib/feature/deal/deal_details_controller.dart`
- `lib/feature/deal/deal_details_screen.dart`
- `lib/repository/deal_repo.dart`

## Workflow state

- Current phase: Phase 3 complete; implementation options compared and the
  controller-owned resolver selected.
- Next phase: define the TDD readiness gate and write the first RED test.
- Production code and tests: unchanged for RES-107.
