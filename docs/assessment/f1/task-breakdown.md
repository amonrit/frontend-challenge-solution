# F-1 — Live Flash-Sale Countdowns: Execution Task Breakdown

The selected design is delivered in small red/green steps. Each task keeps the
clock policy, cart mutation, and rendering work independently reviewable.

| ID | Purpose | Files | Dependency | Acceptance assertion | Variants | Status |
| --- | --- | --- | --- | --- | --- | --- |
| C1 | Compare ticker and expiry ownership | `options.md` | Phase 2 evidence | One app-scoped clock with leaf observers is selected over per-widget or route-owned timers | Per-widget timer; controller ticker; shared service; animation ticker | Complete |
| E1 | Define pure flash status and formatting | `lib/model/flash_sale_status.dart`, `test/flash_sale_status_test.dart` | Initial RED recorded | A supplied end instant and current instant produce active/expired state and exact `mm:ss`/`hh:mm:ss` labels | Static helper; immutable value object | Complete — 4 focused tests pass |
| E2 | Add one app-scoped clock and lifecycle refresh | `lib/service/flash_sale_clock_service.dart`, `main.dart`, clock-service tests | E1 | One timer updates current time; resume updates immediately; disposal releases timer/observer | `GetxService` with `WidgetsBindingObserver`; root widget-owned service | Complete — 2 focused clock tests pass |
| E3 | Add cart expiry boundary and notice event | `CartService`, `main.dart`, cart expiry tests, notice event type | E1, E2 | Expired add is rejected; a deal expiry removes its entire cart line and emits one notice event | Cart-owned worker; clock-owned coordinator | Complete — 2 focused cart tests pass |
| E4 | Render the flash rail countdown and make the initial RED green | Flash rail, reusable countdown leaf, rail widget tests | E1, E2 | Active deal shows formatted countdown; expired deal shows `Expired`, not `Ends soon` | Inline leaf; reusable countdown widget | Complete — expired and active rail tests pass |
| E5 | Add Home-card and details rendering and interaction gates | Shared card, details screen/controller, widget tests | E1, E2, E3 | Both surfaces show countdown/expired state; expired card is disabled and detail Add to bag cannot mutate cart | Per-surface adapters; shared state widget plus adapters | **Next executable task** |
| E6 | Mount the root notice host | App root, notice-host widget, widget/service test | E3 | Each automatic cart removal produces one visible notice without coupling the clock to snackbar calls | Root host; route shell host | Pending |
| E7 | Verify 100-countdown rebuild scope and disposal | Focused widget tests, clock instrumentation | E2, E4, E5 | One tick rebuilds countdown leaves only; 100 leaves create no timer-per-widget or post-disposal callback | Build counters; test-only observer instrumentation | Pending |
| E8 | Run end-to-end and performance verification | F-1 docs, integration test, profile evidence | E3–E7 | Targeted/full tests, analyzer, Android flow, and comparable DevTools profile evidence meet acceptance criteria | Android emulator functional run; physical-device DevTools profile run | Pending |

## Execution order and safeguards

1. E1 must establish pure policy before any timer or UI work.
2. E2 owns the only periodic timer and lifecycle observer. No countdown widget
   may create another repeating timer.
3. E3 guards the cart mutation boundary before E4/E5 expose interactions.
4. E4 makes the existing rail RED test green. E5 then extends the same policy
   to Home cards and details.
5. E6 makes notice presentation explicit; E7 proves the render boundary; E8
   records only measured runtime claims.

## Protected files

- `lib/service/fake_api_service.dart`
- Everything under `assets/data/`
- Unrelated `ios/Podfile.lock`
