# RES-105 — Evidence-backed Answers

## Source evidence

| Question area | Answer | Evidence |
| --- | --- | --- |
| Reactive boundary | `HomeScreen.build` is wrapped in one `Obx` and reads scroll offset, loading, flash deals, today filter, and visible deals inside that closure. | `lib/feature/home/home_screen.dart:17-110` |
| Scroll updates | `HomeController._onScroll` writes every scroll offset to an observable; the current screen reads that observable for app-bar elevation and the floating action button. | `lib/feature/home/home_controller.dart:20-39`, `home_screen.dart:17-21,103-109` |
| List construction | The loaded feed uses `ListView(children: [...visibleDeals.map(...)])`, which constructs the mapped card widget list in the build path rather than using a builder delegate. | `lib/feature/home/home_screen.dart:70-101` |
| Flash rail | The flash section uses a horizontal `ListView.builder`, while the outer Home feed remains a regular children list. | `lib/feature/home/widget/flash_deals_section.dart:35-48` |
| Image sizing | Feed and rail images pass rendered width/height to `TheNetworkImage`, but the shared wrapper does not pass decode-size hints such as `cacheWidth` or `cacheHeight` to `CachedNetworkImage`. | `lib/feature/shared_widget/deal_card.dart:31-33`, `flash_deals_section.dart:67-70`, `the_network_image.dart:26-30` |
| Shared widget scope | `DealCard` is used by both Home and Search, so a shared image or card change can affect both surfaces. | `lib/feature/shared_widget/deal_card.dart:9`, Home/Search call sites |

## Baseline checks

| Check | Result | Command / environment |
| --- | --- | --- |
| Flutter toolchain | Flutter 3.27.0, Dart 3.6.0, DevTools 2.40.2 | `/Users/amonrit/fvm/versions/3.27.0/bin/flutter --version` |
| Full test suite | 28 tests passed | `/Users/amonrit/fvm/versions/3.27.0/bin/flutter test` |
| Static analysis | No issues found | `/Users/amonrit/fvm/versions/3.27.0/bin/flutter analyze` |
| Profile DevTools baseline | Not captured; environment limitation recorded | [Profile baseline record](profile-baseline.md) |

## Confirmed versus unconfirmed

- Confirmed by source: the broad `Obx` dependency set, per-scroll observable
  writes, eager feed children mapping, and absence of image decode hints.
- Not yet confirmed by runtime measurement: frame drops, rebuild counts, Dart
  heap/RSS growth, image-cache size, and the relative contribution of each
  source observation.

## Follow-up limits

1. Capture a profile-mode trace on one repeatable mid-range Android device with
   fixed item count, image inputs, and scroll gesture before selecting an
   optimization.
2. Measure frame timing, widget rebuilds, and image/memory cache behavior in
   DevTools; do not infer those numbers from debug mode or source inspection.
3. Verify that any list/image change preserves refresh, pagination, filter,
   card navigation, placeholders, and accessibility semantics.
