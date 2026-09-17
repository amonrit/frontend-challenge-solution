# F-1 — Live Flash-Sale Countdowns: Scope

## Requested outcome

Replace the static flash-sale label with a live countdown wherever a flash deal
appears: the flash rail, Home deal cards, and deal details. Format remaining
time as `mm:ss`, or `hh:mm:ss` when it exceeds one hour.

At expiry, the UI must show `Expired`, prevent adding the deal to the bag, and
remove an existing cart entry with a visible notice. The Home feed must support
100 or more visible countdowns while rebuilding only the changing text each
second; the result requires DevTools performance evidence.

## Constraints

- Use Flutter 3.27.0 and Java 17. Do not upgrade Flutter or packages.
- Do not modify `lib/service/fake_api_service.dart` or files in `assets/data/`.
- Preserve the existing GetX dependency and route structure unless later
  evidence justifies a scoped change.
- Do not claim runtime, countdown, cart-removal, or performance behavior until
  it has been reproduced or tested.
- Preserve unrelated working-tree changes, including `ios/Podfile.lock`.

## In scope

- Flash-sale expiry data represented by `DealModel.flashSaleEndsAt`.
- Countdown display in the flash rail, Home cards, and deal details.
- Expired add-to-cart behavior, cart removal, and user notice.
- Per-second update ownership, rebuild scope for 100+ countdowns, and
  performance evidence.
- Deterministic unit, widget, and relevant integration coverage.

## Out of scope

- Impression tracking (F-2).
- Stock reservations and checkout behavior (F-3).
- Changes to the fake API or bundled catalog data.
- Unrelated Home pagination, search, pickup countdown, or deep-link behavior.

## Workflow state

- Current phase: Phase 6 — E6 root notice host complete.
- Next phase: Phase 6 — execute E7, verify 100-countdown rebuild scope and
  disposal.
- No diagnosis, option selection, test, production-code change, or runtime
  claim has been made for F-1.
