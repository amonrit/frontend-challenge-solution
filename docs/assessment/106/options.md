# RES-106 — Options, Research, and Decision

## Confirmed problem boundary

The API contract is UTC instants while the product market is Bangkok (UTC+7).
`PickupWindowModel` currently formats UTC fields directly and compares only the
numeric day against device-local `DateTime.now()`. The main bottleneck is an
implicit time domain: display, “today”, and open-state decisions do not share an
explicit market clock or conversion policy.

Secondary risks are:

- comparing `start.day` alone produces false positives across months and years;
- a device configured outside Bangkok can show a different local date than the
  market date;
- conversion at individual widgets would duplicate policy and drift over time;
- a timezone database dependency would add package size and setup cost for a
  single fixed-offset market.

## Candidate approaches

### A. Centralized Bangkok market-time utility with fixed UTC+7 — selected

Keep API values as UTC instants internally. Add one market-time conversion seam
that maps an instant to Bangkok wall-clock fields and accepts an injectable
`now` function for tests. Use it for `label` and complete year/month/day
comparisons; compare `isOpenNow` as instants in UTC.

### B. Add an IANA timezone database package

Use `Asia/Bangkok` from a timezone database and convert through a package API.
This is extensible to many markets and future rule changes, but adds a package
and initialization/lookup complexity that the current single-market app does
not need.

### C. Convert timestamps in the repository/model and store local values

Convert UTC strings during parsing and keep Bangkok wall-clock `DateTime` values
in the model. Widgets become simple, but the model loses the original instant
semantics and other consumers may accidentally treat market-local values as
UTC.

### D. Convert independently in each widget/filter

Keep the model unchanged and apply `add(Duration(hours: 7))` in cards, map,
details, and Home filtering. This avoids a shared utility but duplicates policy
across call sites and leaves other model methods inconsistent.

## Trade-off comparison

| Criterion | A. Central fixed offset | B. IANA timezone package | C. Normalize model values | D. Widget-level conversion |
| --- | --- | --- | --- | --- |
| Correctness | One explicit market domain; complete date comparison; UTC instant semantics retained. | Highest general timezone fidelity. | Can display correctly but risks losing instant semantics. | Easy to miss a call site or use different rules. |
| Testability | Small pure conversion/date seam with injected clock. | Requires package initialization and timezone fixtures. | Tests can be simple but must distinguish local values from instants. | Many duplicated widget/filter tests. |
| Maintainability | One policy owner and minimal call-site changes. | More infrastructure than current scope needs. | Hidden coupling between model parsing and market policy. | Policy duplication and future drift. |
| Performance | Constant-time arithmetic and one date projection per decision. | Lookup/zone conversion overhead and package data. | Constant-time after parse, but semantics are less clear. | Repeated conversion across UI consumers. |
| Dependency/cost | Uses existing Dart/intl APIs; no package addition. | Adds dependency, data, and initialization cost. | No new dependency. | No new dependency but higher defect risk. |
| Multi-market extensibility | Requires replacing the offset provider later. | Best fit if markets/timezone rules expand. | Requires model redesign for market context. | Scaling multiplies duplicated logic. |

## Decision

Select **A** for the current Bangkok-only product. Bangkok has a stable UTC+7
offset and no daylight-saving transition, while the API already provides UTC
instants. Centralizing conversion keeps internal data unambiguous and gives all
consumers a single seam to use, avoiding duplicated timezone logic. It also
keeps tests deterministic without adding a package. Leave an explicit seam so
a named timezone provider can replace the fixed offset if the product becomes
multi-market.

## Rejected alternatives

- The IANA package was rejected for this scope because it adds dependency and
  initialization cost without a current DST or multi-market requirement.
- Storing converted local values in the model was rejected because it blurs the
  distinction between an instant and a wall-clock representation.
- Widget-level conversion was rejected because it duplicates the policy and can
  leave cards, map, details, and filters inconsistent.

## Before/after measurement plan

Use fixed UTC instants and an injected Bangkok “now” in both measurements. Before
the change, record the current label and `isToday` result. After the change,
assert the same inputs produce the Bangkok local label and complete calendar-date
membership, including midnight, overnight, month-end, and year-end cases.

## Next TDD gate

The next phase writes deterministic model and Home filter RED tests for the
wrong label and day-only comparison before any production implementation.
