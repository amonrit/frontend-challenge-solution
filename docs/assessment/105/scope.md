# RES-105 — Scope and Workflow State

## Requested outcome

Improve Home-feed scrolling performance and memory behavior on a mid-range
Android device. The feed should avoid rebuilding the entire screen during
scrolling, keep list construction bounded by the viewport, and decode/cache
images at a size appropriate for their rendered space. The result must be
supported by comparable before/after DevTools evidence.

## Assignment constraints

- Keep the work isolated to RES-105.
- Do not modify `lib/service/fake_api_service.dart` or anything under
  `assets/data/`.
- Use Flutter 3.27.0 and Java 17; do not upgrade Flutter or packages.
- Capture a profile-mode baseline before changing performance-sensitive code.
- Use the same device, mode, item count, and scroll scenario for after evidence.
- Preserve unrelated working-tree changes, including `ios/Podfile.lock`.

## Planned scope

- Inspect Home reactive boundaries, scroll listeners, list construction, deal
  cards, and image loading dimensions.
- Reproduce the reported jank and memory growth where the environment allows.
- Capture DevTools frame timing, rebuild, and image/memory evidence before any
  performance change.
- Compare bounded-list, reactive-boundary, and image-decoding approaches before
  selecting an implementation.

## Out of scope

- Home refresh/pagination race behavior (RES-104).
- Pickup timezone policy (RES-106).
- Flash countdown, impressions, and reservations (F-1 to F-3).
- Backend or catalog changes.

## Workflow state

- Current phase: Android before/after timeline and direct scroll-rebuild test
  completed.
- Next step: use Flutter DevTools over USB on a physical mid-range Android
  device to capture repeatable frame, memory, and image-cache evidence.
- Production code and tests: Home feed extraction, lazy-construction coverage,
  and a widget test that proves scroll state does not rebuild `HomeFeedList`
  are complete. The Pixel 6 AVD uses host GPU, but its raster timing is not
  repeatable enough for a measured improvement claim. The latest Android
  emulator integration regression suite passed all seven ticket flows; it is
  functional evidence, not performance evidence.
