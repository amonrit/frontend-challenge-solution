# RES-104 — Scope and Workflow State

## Requested outcome

When the Home feed is loading the next page and the user quickly pulls to
refresh, the final feed must contain the correct items once, in the correct
order. A response from an older loading round must not overwrite or append
stale data from a newer refresh round.

## Assignment constraints

- Keep the change isolated to RES-104.
- Do not modify `lib/service/fake_api_service.dart` or anything under
  `assets/data/`.
- Preserve normal Home initial load, pull-to-refresh, and load-more behavior.
- Use Flutter 3.27.0 and the existing repository/API contract.
- Follow the repository TDD workflow: questions, evidence, options, RED test,
  one execution task per user-approved `next`, verification, and documentation
  currency audit.
- Preserve unrelated working-tree changes, including `ios/Podfile.lock`.

## Planned scope

- Inspect Home controller, pagination model, refresh callbacks, and feed UI.
- Reproduce or deterministically model overlapping refresh and load-more work.
- Compare request-round, cancellation, and serialization approaches before
  selecting one.
- Add regression coverage before production implementation.
- Verify that page state and feed contents remain consistent after overlap.

## Out of scope

- Home feed performance optimization belongs to RES-105.
- Pickup timezone/filter behavior belongs to RES-106.
- API or bundled catalog changes.
- New pagination product behavior beyond preventing stale or duplicate data.

## Workflow state

- Current phase: Phase 1 — requirement and evidence questions recorded.
- Next phase: Phase 2 — collect evidence-backed answers.
- Production code and tests: unchanged for RES-104.
