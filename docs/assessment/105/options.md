# RES-105 — Performance Options, Research, and Decision

## Confirmed problem boundary

Source inspection confirms three independent optimization seams in the Home
surface: one `Obx` observes scroll and feed state for the whole screen, the
main feed maps every loaded deal into a `children` list, and the shared image
wrapper does not provide decode-size hints. Runtime frame, rebuild, and memory
contributions remain unmeasured until a repeatable profile trace is available.

## Candidate approaches

### A. Split reactive boundaries — selected

Keep GetX, but scope `Obx` to the app-bar elevation/FAB state and to the small
regions that own loading, filter, and feed changes. Build stable chrome and
feed structure outside scroll-driven observers. This preserves the current
architecture while reducing the rebuild area.

### B. Replace the scroll observable with a widget-local listener

Use `AnimatedBuilder` or `ValueListenableBuilder` around only the scroll UI.
This can make ownership clearer, but moves state coordination out of the
controller and adds a second reactive pattern to a GetX screen.

### C. Lazy feed construction — selected

Use a builder-based list (or sliver) for deal cards so widgets are created as
they enter the viewport. Preserve the existing `SmartRefresher`, pagination,
filtering, and flash-rail placement.

### D. Custom sliver layout

Replace the body with `CustomScrollView` and multiple slivers. This offers
fine-grained composition, but is a larger change than the current one-list
screen needs and increases integration risk with the refresher package.

### E. Decode images at display size — selected

Pass cache/decode width and height derived from the rendered slot and device
pixel ratio to the shared cached-image widget. Keep placeholders and error
states unchanged.

### F. Change image assets or backend dimensions

Resize source assets or add server-side image transformations. This is outside
the client-only assessment constraints and cannot be verified without changing
the protected backend/catalog.

## Trade-off comparison

| Area | Selected A+C+E | B+D alternatives | F alternative |
| --- | --- | --- | --- |
| Correctness | Keeps GetX state, list interactions, and image semantics intact. | More ownership and layout changes can affect refresh/navigation behavior. | Depends on unavailable backend/catalog changes. |
| Performance | Targets observed rebuild area, eager construction, and oversized decodes. | Can perform well, but adds patterns or complexity without evidence they are needed. | Potentially best source bytes, but not in client scope. |
| Maintainability | Small, explicit boundaries using existing widgets and controller. | Mixed reactive patterns or slivers increase cognitive and integration cost. | Adds cross-system operational ownership. |
| Testability | Widget tests can assert visible behavior; source-level boundaries remain local. | More plumbing and layout setup to exercise. | Requires backend/asset test infrastructure. |
| Scope/risk | Incremental and reversible per bottleneck. | Broader refactor with more regression surface. | Violates protected-file and assessment constraints. |
| Measurement | Each change can be profiled independently and together. | Attribution is harder when layout/state patterns change simultaneously. | Cannot be measured in this repository. |

## Decision

Select the combined client-side plan **A + C + E**. It addresses each confirmed
source bottleneck while preserving the GetX layer-first architecture and the
existing refresh/pagination contract. Each execution task will remain isolated
so before/after traces can attribute the effect of the change. The plan does
not claim a performance improvement until comparable profile evidence is
captured.

## Rejected alternatives

- A widget-local `ValueListenableBuilder` was deferred to avoid mixing reactive
  state patterns before measuring the simpler GetX boundary split.
- A full sliver rewrite was rejected as unnecessary scope and higher refresher
  integration risk.
- Backend or asset resizing was rejected because those files are protected and
  the task is client-side.

## Measurement plan

Use the same profile-mode device, item count, image inputs, warm-up, and fixed
scroll gesture for baseline and after runs. Record frame timing, jank/missed
frames, widget rebuild counts, Dart/RSS memory where available, and image cache
count/bytes. If a device trace cannot be captured, keep the limitation explicit
and use automated behavior tests without inventing performance numbers.

## Next TDD gate

Define testable behavior and a RED signal for lazy construction, reactive
boundary behavior, and image sizing before implementation. Performance claims
remain blocked on comparable DevTools evidence.
