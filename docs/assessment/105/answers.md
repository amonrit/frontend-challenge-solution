# RES-105 — Evidence-backed Answers

## Source evidence (before implementation)

| Question area | Answer | Evidence |
| --- | --- | --- |
| Reactive boundary | `HomeScreen.build` is wrapped in one `Obx` and reads scroll offset, loading, flash deals, today filter, and visible deals inside that closure. | `lib/feature/home/home_screen.dart:17-110` |
| Scroll updates | `HomeController._onScroll` writes every scroll offset to an observable; the current screen reads that observable for app-bar elevation and the floating action button. | `lib/feature/home/home_controller.dart:20-39`, `home_screen.dart:17-21,103-109` |
| List construction | The loaded feed uses `ListView(children: [...visibleDeals.map(...)])`, which constructs the mapped card widget list in the build path rather than using a builder delegate. | `lib/feature/home/home_screen.dart:70-101` |
| Flash rail | The flash section uses a horizontal `ListView.builder`, while the outer Home feed remains a regular children list. | `lib/feature/home/widget/flash_deals_section.dart:35-48` |
| Image sizing | Before T3, feed and rail images passed rendered width/height to `TheNetworkImage`, but the wrapper passed no decode-size hints. | `lib/feature/shared_widget/deal_card.dart:31-33`, `flash_deals_section.dart:67-70`, `the_network_image.dart:26-30` |
| Shared widget scope | `DealCard` is used by both Home and Search, so a shared image or card change can affect both surfaces. | `lib/feature/shared_widget/deal_card.dart:9`, Home/Search call sites |

## Baseline checks

| Check | Result | Command / environment |
| --- | --- | --- |
| Flutter toolchain | Flutter 3.27.0, Dart 3.6.0, DevTools 2.40.2 | `flutter --version` |
| Full test suite | 28 tests passed | `flutter test` |
| Static analysis | No issues found | `flutter analyze` |
| Profile DevTools baseline | Android before/after VM timeline captured; raster timing was not repeatable enough for an improvement claim | [Profile baseline record](profile-baseline.md) |

## Implementation evidence

- T3 now derives finite `memCacheWidth/Height` from layout constraints and
  device pixel ratio. The focused widget test passes with 320-pixel hints for
  a 160-pixel slot at DPR 2.

## Before/after comparison

| Concern | Before | After | Evidence type |
| --- | --- | --- | --- |
| Scroll reactivity | One `Obx` covered the whole `Scaffold` and read scroll offset. | App bar and FAB observe scroll offset in separate wrappers; body does not read it. | Source diff and analyzer |
| Feed construction | Main feed used `ListView(children: [...map(...)])`. | Main feed uses `ListView.builder` with the same item order and callbacks. | Source diff and Home regression tests |
| Image decode sizing | No `memCacheWidth/Height` values were passed. | Finite layout dimensions are scaled by device pixel ratio and passed as hints. | Focused widget test |
| Runtime frame/memory metrics | Not captured. | Not captured; no comparable Android target was available. | Explicit limitation |

## Integrated verification

- Image sizing focused test: 1 passed.
- Home controller regression suite: 6 passed.
- Full Flutter suite: 29 passed.
- `flutter analyze`: no issues found.
- `git diff --check`: passed.
- Manual device flow and profile-mode metrics remain unperformed because no
  comparable Android target was available.
- `test/home_feed_list_test.dart` now verifies that a 100-deal feed initially
  builds fewer than 100 `DealCard` widgets, providing direct lazy-construction
  coverage.

## Confirmed versus unconfirmed

- Confirmed by source: the broad `Obx` dependency set, per-scroll observable
  writes, eager feed children mapping, and absence of image decode hints.
- Not yet confirmed by runtime measurement: frame drops, rebuild counts, Dart
  heap/RSS growth, image-cache size, and the relative contribution of each
  source observation.

## Follow-up limits

1. Repeat the profile-mode trace on one physical, repeatable mid-range Android device with
   fixed item count, image inputs, and scroll gesture before selecting an
   optimization.
2. Measure frame timing, widget rebuilds, and image/memory cache behavior in
   DevTools; do not infer those numbers from debug mode or source inspection.
3. Verify that any list/image change preserves refresh, pagination, filter,
   card navigation, placeholders, and accessibility semantics.
