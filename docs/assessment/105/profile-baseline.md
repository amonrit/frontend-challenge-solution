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

The emulator trace was captured from the Flutter VM timeline streams used by
DevTools: `Dart`, `Embedder`, `GC`, `Isolate`, and `API`. The same AVD, profile mode,
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

T0 now has Android-emulator before/after Flutter VM timeline evidence. It is
insufficient for a measured jank or memory-improvement claim because the
host-GPU emulator does not produce repeatable raster timing and no image-cache
or RSS comparison was captured.

## Physical-device Perfetto capture

Date: 2026-09-17

A physical Android 15 device was connected through Wireless debugging. Flutter
could install and launch profile APKs, but its Dart VM Service could not be
discovered through the wireless log stream; DevTools frame and memory views
were therefore unavailable. The preferred measurement path is Flutter DevTools
over a USB data connection, which gives direct access to Flutter frame timing,
Dart heap, and image-cache evidence. That path was unavailable because only a
charge-only USB cable was available for this assessment session.

Rather than fabricate a DevTools result or stop at emulator data, the fallback
was a physical-device Perfetto capture through Wireless debugging. It provides
system scheduling and graphics events, but it is not equivalent to Flutter
DevTools and is documented with its own data-quality limits below.

As a system-level alternative, Perfetto captured `sched/sched_switch`, `freq`,
`idle`, `am`, `wm`, `gfx`, and `view` events for 15 seconds. Both runs used the
same contract: force-stop the app, launch Home, then perform three upward and
two downward 350 ms swipes at the same coordinates.

| Revision | Source | Trace size | SHA-256 |
| --- | --- | ---: | --- |
| Before | `beb4164` (pre-RES-105 implementation) | 15 MB | `403d32a5d58561ab3efe01545f94b1f5af7871977202704751d13e061bc3068b` |
| After | Current profile APK | 11 MB | `38a904cdd4e4185448c31341924d8aae3cfe08da2f53d33c949bc4f89e3e042f` |

The raw traces are intentionally not committed because they are binary capture
artifacts. Trace size is not a performance metric, so this capture does not
claim an improvement. It establishes a repeatable physical-device trace
contract that can be opened in Perfetto UI when a trace processor is available.

## Perfetto UI analysis attempt

Both traces were opened in Perfetto UI and contained CPU Scheduling, CPU
Frequency, graphics, and `dev.rescu.rescu` process tracks. A SQL query against
the current trace returned 8,382.758 ms of scheduled process time across 8,803
scheduling slices during its 15-second capture. This is an observation only,
not a performance result.

Perfetto UI also reported import/data-loss errors in both captures: 18,519 for
the baseline and 22,362 for the current trace. Those warnings make the two
scheduled-time values unsuitable for a before/after comparison. No runtime
improvement claim is made from this analysis.

## Required follow-up

- Analyze the physical traces with Perfetto UI or restore a stable Flutter VM
  Service connection to capture DevTools frame timing and Dart/RSS/image-cache
  memory alongside this trace contract.

## After-change profile status

The host-GPU emulator can be used for functional Android checks and trace
collection. Its raster timing is not repeatable enough for a performance claim.
The physical-device Perfetto capture provides stronger runtime evidence, but
without analyzed frame or memory slices runtime performance improvement remains
unclaimed.
