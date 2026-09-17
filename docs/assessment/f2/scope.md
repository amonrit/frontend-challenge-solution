# F-2 — Deal Impression Tracking: Scope

## Requested outcome

Record one `deal_impression` event per deal per app session when its card is at
least 50% visible continuously for one second. Each event must include
`deal_id`, `source`, and list `position`; valid sources are `home_feed`,
`flash_rail`, and `search`.

Hold qualifying events for batched delivery through
`FakeApiService.sendAnalyticsBatch`: send at 10 unsent events or 15 seconds
after the first unsent event, whichever happens first. The Analytics debug
screen must make recorded events observable, and scrolling must not regress.

## Constraints

- Use Flutter 3.27.0 and Java 17. Do not upgrade Flutter or packages.
- Do not modify `lib/service/fake_api_service.dart` or anything in
  `assets/data/`.
- Preserve the existing GetX dependency and route structure unless evidence
  later justifies a scoped change.
- `visibility_detector` is already available and may be used, but is not
  mandated.
- Preserve unrelated working-tree changes, including `ios/Podfile.lock`.
- Do not claim runtime visibility, batching, or scrolling performance until it
  is reproduced or measured.

## In scope

- Session-wide impression deduplication.
- Continuous visibility qualification for Home feed, flash rail, and search
  cards.
- Source and position assignment at each rendering call site.
- Batch threshold/timer delivery and failure behavior.
- Analytics debug observability and deterministic unit/widget/integration
  coverage.
- Rebuild and scroll-performance evidence relevant to visibility tracking.

## Out of scope

- Flash-sale expiration behavior (F-1).
- Stock reservations and checkout behavior (F-3).
- Changing backend responses or bundled catalog data.
- Persisting analytics across a process restart unless later requirements show
  that app-session scope requires it.

## Workflow state

- Current phase: Phase 0 — scope initialized.
- Next phase: Phase 1 — write requirement questions.
- No diagnosis, option selection, test, production-code change, or runtime
  claim has been made for F-2.
