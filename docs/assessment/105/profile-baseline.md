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

The Pixel 6 emulator installed and ran the profile APK, but the emulator
reported Software GL due to host memory pressure (about 3.1 GB available where
5 GB was required). Frame and memory numbers from that setup would measure the
host rendering constraint rather than a representative mid-range Android
device, so no comparable before/after trace was recorded. The iOS simulator was
also not substituted because it would not be comparable to the required device
scenario.

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
- Add direct widget coverage for reactive rebuild scope; lazy construction is
  now covered by `test/home_feed_list_test.dart` (F2).

## After-change profile status

The emulator can be used for functional Android checks, but not as comparable
performance evidence because of Software GL and host memory pressure.
Source-level changes and automated behavior evidence are recorded in
`answers.md`; runtime performance improvement remains unclaimed.
