# RES-105 — TDD Readiness

## Acceptance criteria

- Home scroll performance is measured with comparable profile-mode traces
  before and after each optimization.
- Scroll-driven state changes rebuild only the app-bar/FAB region that needs the
  offset, not the whole Home feed.
- The main feed constructs cards lazily while preserving refresh, pagination,
  filtering, navigation, and accessibility behavior.
- Cached images receive decode/cache hints sized to their rendered slot and
  device pixel ratio, while placeholder and error behavior remains unchanged.

## Test level and deterministic inputs

- Widget test for `TheNetworkImage` with a fixed 160 logical-pixel slot and
  `devicePixelRatio: 2`; expected memory-cache hints are 320 pixels.
- Later execution tasks will add behavior tests for lazy construction and
  reactive boundaries once their implementation seams are selected.
- Performance acceptance uses a fixed device, profile mode, item count, image
  inputs, warm-up, and scroll gesture; metrics are evidence rather than unit
  test assertions.

## Expected RED signal

The focused image test should fail because `TheNetworkImage` currently passes
no `memCacheWidth` or `memCacheHeight` to `CachedNetworkImage` (both are null).

## Post-change GREEN assertion

The image test reports 320 for both hints at DPR 2. Profile traces then compare
frame timing, rebuild counts, and image/memory cache behavior using the same
scenario.

## Edge and failure cases

- Missing or failed images retain their placeholder and error widgets.
- Width or height may be unconstrained; the implementation must avoid invalid
  decode hints.
- Device pixel ratios other than 2 must scale safely.
- Home refresh, load-more, filter toggles, and card taps must remain functional.

## Files and commands

- Test: `test/res_105_image_sizing_test.dart`
- Planned production files: `lib/feature/home/home_screen.dart`,
  `lib/feature/shared_widget/the_network_image.dart`, and related widgets.
- Protected: `lib/service/fake_api_service.dart`, `assets/data/`.
- RED command: `flutter test test/res_105_image_sizing_test.dart`

## RED result

Focused run on 2026-09-17 failed as intended before production changes:

- `passes a display-sized decode hint to cached images`: expected
  `memCacheWidth == 320`, actual `null` (the same expectation applies to
  height).
