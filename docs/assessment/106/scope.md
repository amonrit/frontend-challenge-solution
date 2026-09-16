# RES-106 — Scope and Workflow State

## Requested outcome

Pickup windows must display the correct market-local time for Bangkok, and the
Home **Pickup today** filter must include every deal whose pickup date is today.
Date comparisons must remain correct across midnight, month boundaries, and
year boundaries.

## Assignment constraints

- Keep the change isolated to RES-106.
- Do not modify `lib/service/fake_api_service.dart` or anything under
  `assets/data/`.
- Preserve the existing API contract, which sends ISO-8601 UTC instants.
- Use Flutter 3.27.0 and the existing `intl` dependency unless evidence shows
  a necessary scoped change.
- Follow the repository workflow: questions, evidence, options, RED test, one
  execution task per approved `next`, verification, and documentation audit.
- Preserve unrelated working-tree changes, including `ios/Podfile.lock`.

## Planned scope

- Inspect ISO-8601 parsing, display formatting, `isToday`, `isOpenNow`, and
  Home filtering call sites.
- Establish the required Bangkok timezone policy and an injectable clock/time
  zone seam for deterministic tests.
- Reproduce the wrong display and date-filter boundary cases with fixed UTC
  instants.
- Compare timezone conversion and date-comparison approaches before selecting
  one.
- Add tests before production implementation and record before/after behavior.

## Out of scope

- API payload or bundled catalog changes.
- Home pagination/refresh behavior (RES-104).
- Home rebuild and image-memory optimization (RES-105).
- Countdown and reservation time policies outside pickup-window display/filter
  behavior.

## Workflow state

- Current phase: Phase 3 — timezone and date-comparison approaches compared.
- Next phase: Phase 4 — write deterministic RED tests and TDD readiness.
- Production code and tests: unchanged for RES-106.
