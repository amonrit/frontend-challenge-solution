# RES-105 — Execution Task Breakdown

The selected plan is incremental: capture a comparable baseline first, then
address reactive scope, list construction, and image decoding separately. Each
task records evidence before moving to the next one.

| ID | Purpose | Files | Dependency | Acceptance assertion | Variants | Status |
| --- | --- | --- | --- | --- | --- | --- |
| C1 | Compare reactive-boundary mechanisms | `lib/feature/home/home_screen.dart` | Phase 3 decision | GetX subtree split and widget-local listener are compared for ownership, rebuild scope, and risk | Nested `Obx` (selected); `ValueListenableBuilder`; `GetBuilder` | Complete in `options.md` |
| C2 | Compare lazy-list composition | `lib/feature/home/home_screen.dart` | Phase 3 decision | Builder list and sliver list are compared for refresher integration and scope | `ListView.builder` (selected); `CustomScrollView`/`SliverList` | Complete in `options.md` |
| C3 | Compare image decode hint APIs | `lib/feature/shared_widget/the_network_image.dart` | Phase 3 decision | `memCacheWidth/Height` sizing and source-asset resizing are compared under protected-file constraints | Cached-image hints (selected); asset/backend resize | Complete in `options.md` |
| T0 | Capture comparable profile baseline | `docs/assessment/105/profile-baseline.md` | C1–C3 | Same device, profile mode, item count, images, warm-up, and gesture are recorded; unavailable runtime access is documented | Android profile trace (preferred); explicit environment limitation | Complete (limitation recorded) |
| T1 | Split scroll reactivity from feed rendering | `lib/feature/home/home_screen.dart` | T0 | Scroll offset is observed only by app-bar/FAB wrappers; body observes feed state without reading scroll offset | Nested `Obx`; widget-local listener | Complete |
| T2 | Make the main feed lazy | `lib/feature/home/home_screen.dart` | T1 | Cards are built through a lazy delegate while refresh, pagination, filter, and navigation still work | `ListView.builder`; sliver composition | Complete |
| T3 | Add display-sized image decode hints | `lib/feature/shared_widget/the_network_image.dart`, `test/res_105_image_sizing_test.dart` | T0 | At DPR 2 and 160 px slot, `memCacheWidth/Height` are 320; placeholders/errors remain unchanged | Pass hints directly; derive a reusable size helper | Complete |
| T4 | Compare after profile evidence | `docs/assessment/105/answers.md`, `solutions.md` | T1–T3 | Before/after frame, rebuild, and memory/image-cache metrics use the identical scenario; limitations remain explicit | DevTools trace; deterministic tests if profile unavailable | Complete (runtime limitation recorded) |
| T5 | Run integrated verification | `docs/assessment/105/`, `solutions.md` | T4 | Focused tests, full suite, analyzer, diff check, and manual behavior checks pass | Local automated checks; simulator/device smoke check if available | Complete (manual/profile limitations recorded) |
| F1 | Capture DevTools before/after on a mid-range Android device | `docs/assessment/105/profile-baseline.md`, `solutions.md` | Suitable device available | Identical profile-mode scenario records frame timing, rebuilds, and memory/image-cache metrics before and after | Physical device; configured Android emulator | Follow-up |
| F2 | Add widget tests for rebuild scope and lazy construction | `test/home_feed_list_test.dart`, Home widgets | Test seam design | Lazy feed test shows a 100-deal feed builds fewer than 100 cards in the initial viewport; direct scroll-rebuild instrumentation remains separate | Rebuild counters; controlled builder instrumentation | Partially complete (lazy test complete; rebuild test follow-up) |

## Execution rules

- Execute one `T*` task per workflow turn.
- T0 must happen before performance-sensitive code changes.
- T1–T3 preserve RED-first order and remain independently attributable in
  profiling.
- Do not claim a performance improvement without comparable profile evidence.

## Protected files

- `lib/service/fake_api_service.dart`
- Everything under `assets/data/`
- Unrelated working-tree changes such as `ios/Podfile.lock`
