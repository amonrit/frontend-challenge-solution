# RES-105 — Profile Baseline Record

## Attempt

Date: 2026-09-17

The pinned Flutter 3.27.0 toolchain reported these connected targets:

- iPhone 17 Pro Simulator, iOS 26.5 (booted)
- macOS desktop
- Mac Designed for iPad
- Chrome
- Pixel 6 Android emulator, Android 15 / API 35 (created after the initial
  inventory)

The initial AVD launch selected Software GL because of host memory pressure.
Restarting the same AVD with `-gpu host` established a host-GPU profile target;
both revisions were installed in profile mode on that target. The iOS simulator
was not substituted because it would not be comparable to the Android scenario.

## Reproducibility contract for later evidence

When a suitable target is available, record the device/OS, profile mode, loaded
item count, image inputs, cache warm-up, scroll gesture, trace duration, and
DevTools metrics (frame timing, rebuilds, Dart/RSS memory, image-cache count or
bytes). Use the identical contract before and after each implementation task.

## Before/after timeline attempt

The trace was captured from the Flutter VM timeline streams used by DevTools:
`Dart`, `Embedder`, `GC`, `Isolate`, and `API`. The same AVD, profile mode,
viewport, and six 350 ms upward swipes were used for the pre-RES-105 worktree
(`d4b3024`) and the current revision. The list was warmed before a timeline
reset; the final six swipes were the measured window.

| Metric | Before (warm run) | After (warm run) | Interpretation |
| --- | ---: | ---: | --- |
| `Animator::BeginFrame` p90 | 3.414 ms | 3.669 ms | No material improvement shown by this single run. |
| `GPURasterizer::Draw` p90 | 29.707 ms | 117.444 ms | Not reliable: host-GPU emulator raster timing varied sharply between repeats. |

An earlier cold-run pair showed build p90 from 6.763 ms to 3.978 ms and raster
p90 from 121.336 ms to 114.416 ms. The disagreement with the warmed pair is
why these measurements are retained as evidence, but not used to claim a
performance improvement.

## Result

T0 now has genuine Android before/after timeline evidence. It is insufficient
for a measured jank or memory-improvement claim because the host-GPU emulator
does not produce repeatable raster timing and no image-cache/RSS comparison was
captured.

## Required follow-up

- Repeat the identical trace on a physical mid-range Android device and capture
  image-cache/RSS data alongside frame timing (F1).

## After-change profile status

The host-GPU emulator can be used for functional Android checks and trace
collection. Its raster timing is not repeatable enough for a performance claim.
Source-level changes and automated behavior evidence are recorded in
`answers.md`; runtime performance improvement remains unclaimed.
