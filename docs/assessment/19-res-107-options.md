# RES-107 — Options, Research, and Decision

## Confirmed design boundary

The `/deal` route receives an ID and optional `source` through
`Get.parameters`. In-app card navigation also supplies a `DealModel` through
`Get.arguments`, but a deep link does not. The existing `DealRepo.fetchById`
already provides the required data access. The fix must preserve both entry
paths and make loading/error state explicit.

## Candidate approaches

### Option A — Resolve in `DealDetailsController` (selected)

Read `Get.arguments` only when it is a `DealModel`; otherwise parse and validate
the route ID, expose an observable loading/error state, and call
`dealRepo.fetchById`. Initialize the availability observer only after a model
exists. The screen renders a loading branch, the existing loaded page, or a
retryable error branch.

### Option B — Resolve in route middleware

Use `GetMiddleware` to inspect route parameters and load a model before the
page is built, then inject the model into route arguments.

### Option C — Resolve in the binding/factory

Have `DealDetailsBinding` create a controller with a model-loading Future or a
resolver service, keeping route interpretation out of the controller.

### Option D — Resolve in the screen with `FutureBuilder`

Keep the controller model-only and let `DealDetailsScreen` parse the route and
fetch the model while rendering asynchronous branches.

## Comparison

| Criterion | A: controller | B: middleware | C: binding/factory | D: screen FutureBuilder |
| --- | --- | --- | --- | --- |
| Handles model argument and ID | Yes | Yes, but must rewrite arguments | Yes | Yes |
| Explicit loading/error UI | Yes | Requires route-level handoff | Requires extra state contract | Yes, but splits ownership |
| Preserves existing binding | Small change | Middleware and argument plumbing | Binding becomes async-aware | Controller/screen contract changes |
| Controller lifecycle safety | Centralized; can guard late fetch | Harder to tie load to controller close | Requires resolver ownership | Must coordinate Future and controller observer |
| Testability | Focused controller tests plus widget state tests | Route/middleware integration setup | Binding integration setup | Widget tests with repository injection |
| Normal card navigation risk | Low; model argument remains fast path | Medium; argument rewriting can affect route behavior | Medium; binding must distinguish paths | Medium; screen becomes data-aware |
| Scope and cost | Small and aligned with current architecture | Broad route plumbing | Medium architectural change | Broad responsibility shift |

## Decision

Select **Option A — resolve in `DealDetailsController`**. It keeps API access in
the existing repository, keeps route-owned state in the existing controller,
preserves the fast model-argument path, and provides one place to guard loading
and error transitions. The controller can reject invalid IDs before making a
request and can avoid starting cart availability work until `deal` is loaded.

## Rejected alternatives

- **Middleware** was rejected because it introduces asynchronous route
  argument rewriting and makes controller lifecycle/error ownership less clear.
- **Binding/factory resolution** was rejected because the current binding is a
  simple dependency registration point; making it an async model resolver adds
  a new abstraction for one route.
- **Screen `FutureBuilder`** was rejected because it moves repository and route
  parsing into UI code and splits ownership between the screen and controller.

## Required edge behavior for the selected approach

- A valid `DealModel` argument loads immediately and retains existing card
  navigation behavior.
- A valid numeric ID without an argument shows loading, then the loaded deal.
- Missing, nonnumeric, or invalid route input shows an understandable error and
  does not call the repository.
- A repository 404/error shows an understandable error and offers retry where
  the final UI design supports it.
- A late fetch completion after controller closure cannot mutate state.
- A second ID request cannot replace a newer route state with an older result.

## Next TDD gate

Write deterministic controller tests for the current missing-argument failure,
valid ID loading, invalid ID handling, and preservation of the model-argument
path. Add widget coverage for loading and error rendering if the controller
state contract requires it.
