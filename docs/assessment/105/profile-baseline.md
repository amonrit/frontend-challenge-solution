# RES-105 — Profile Baseline Record

## Attempt

Date: 2026-09-17

The pinned Flutter 3.27.0 toolchain reported these connected targets:

- iPhone 17 Pro Simulator, iOS 26.5 (booted)
- macOS desktop
- Mac Designed for iPad
- Chrome

No Android emulator or physical mid-range Android device was available. The
assignment's performance acceptance is specifically framed around a mid-range
Android device, so no comparable profile-mode frame, rebuild, or memory trace
was recorded. The iOS simulator target was not substituted because it would not
be comparable to the required device scenario.

## Reproducibility contract for later evidence

When a suitable target is available, record the device/OS, profile mode, loaded
item count, image inputs, cache warm-up, scroll gesture, trace duration, and
DevTools metrics (frame timing, rebuilds, Dart/RSS memory, image-cache count or
bytes). Use the identical contract before and after each implementation task.

## Result

T0 is complete with an explicit environment limitation. No performance number
or improvement claim is made from this attempt.

## Required follow-up

- Capture DevTools before/after on a mid-range Android device (F1).
- Add direct widget coverage for reactive rebuild scope and lazy construction
  (F2).

## After-change profile status

The same target inventory remained available after T1–T3, so a comparable
Android profile trace still could not be captured. Source-level changes and
automated behavior evidence are recorded in `answers.md`; runtime performance
improvement remains unclaimed.
