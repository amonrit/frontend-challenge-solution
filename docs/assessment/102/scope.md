# RES-102 — Scope and Workflow State

## Requested outcome

Leaving My orders while active pickup countdowns are visible must not produce
`setState() called after dispose()` or leave periodic callbacks running. A
mounted countdown must continue updating once per second.

## Assignment constraints

- Keep the fix isolated to RES-102.
- Use Flutter 3.27.0 and the existing widget architecture.
- Do not modify `lib/service/fake_api_service.dart` or anything under
  `assets/data/`.
- Preserve unrelated working-tree changes, including `ios/Podfile.lock`.

## Out of scope

- Shared/global countdown architecture for F-1.
- Cart or deal-detail Worker ownership (RES-103).
- Pickup terminal-state behavior after the window opens.
- Android-specific navigation verification.

## Workflow state

- Status: Complete for the documented route-pop and widget-disposal behavior.
- Focused tests, manual smoke test, analyzer, and regression checks passed.
- Follow-up limits are recorded in `answers.md` and `solutions.md`.
