# RES-103 — Scope and Workflow State

## Requested outcome

When a user opens several deal-detail pages and later taps **Add to bag**, a
closed detail page must no longer trigger a stock-refresh request. Requests
from currently active detail pages must continue to support the existing
availability display.

## Assignment constraints

- Reproduce the request accumulation before changing production code.
- Establish the lifecycle/resource owner from the actual source.
- Keep the fix isolated to RES-103; do not combine it with RES-101, RES-102,
  or F-1 work.
- Do not modify `lib/service/fake_api_service.dart` or `assets/data/`.
- Use Flutter 3.27.0 and preserve existing project architecture.
- Add evidence and diagnosis to `solutions.md` after the relevant work.
- Commit one logical change at a time with a `[RES-103]` prefix, only after
  explicit user instruction.

## Relevant source inspected

- `lib/feature/deal/deal_details_controller.dart`
- `lib/binding/deal_details_binding.dart`
- `lib/routes/routes.dart`
- `lib/service/cart_service.dart`
- `lib/repository/deal_repo.dart`
- `PROBLEM.md`

## Workflow state

- Current phase: Phase 0 complete.
- Next phase: write `docs/assessment/05-res-103-questions.md` with questions
  only.
- Production code, tests, and implementation decisions: not changed in this
  phase.
