# Repository Guidelines

These guidelines apply to the entire **Rescu** repository: a Flutter app for discounted surplus food, built with GetX and a simulated backend. This is a one-week hiring assessment. Prioritize accurate diagnosis, complete behavior, and evidence over the number of tickets completed.

## Project Structure & Module Organization

- `lib/main.dart`: app entry point and registration of shared dependencies.
- `lib/app_config.dart`: app theme and configuration.
- `lib/feature/`: screens and GetX controllers grouped into `home`, `search`, `deal`, `map`, `cart`, `order`, and `analytics_debug`.
- `lib/feature/shared_widget/`: reusable widgets; keep feature-specific widgets within their feature.
- `lib/service/`: app-wide state and services, including cart, analytics, and the simulated API.
- `lib/repository/`: API access and conversion of responses into models.
- `lib/model/`: data models and JSON conversion.
- `lib/binding/`, `lib/routes/`, `lib/middleware/`: dependency bindings, navigation, and route middleware.
- `lib/util/`: utilities such as logging.
- `test/`: automated tests; organize new tests by feature where appropriate.
- `android/`, `ios/`: platform projects.
- `assets/data/`: simulated backend data.
- `solutions.md`: diagnoses, decisions, verification, AI usage, and time spent. Create it when starting ticket work.

Preserve the existing separation of responsibilities: UI renders state and receives interactions, controllers manage screen state, services own shared state, and repositories provide data access. Avoid unrelated architectural refactors.

## Coding Style

- Use the Dart formatter and `flutter_lints` configured in `analysis_options.yaml`.
- Use `snake_case.dart` for files, `UpperCamelCase` for classes, `lowerCamelCase` for methods and variables, and `_` prefixes for private members.
- Follow existing import grouping: SDK/package imports before relative imports, with a blank line between groups.
- Prefer `const` and `final` where appropriate. Preserve null safety and avoid forced casts for route or API data.
- Inject dependencies through constructors, following existing patterns, so tests can control them.
- Scope `Obx` to the smallest subtree that needs to change. Avoid rebuilding entire screens in response to scroll offsets or timers.
- Give each Timer, Worker, subscription, and scroll controller a clear owner. Release resources in the owner's `State.dispose()` or `GetxController.onClose()`.
- For async requests, account for out-of-order responses, clearing data, refresh, screen closure, and loading/error state. Debouncing alone does not prevent stale responses.
- Preserve API timestamps as UTC instants. Explicitly convert to Bangkok dates and times for display and date filtering; do not depend on the user's device timezone.
- Make the current time or async dependencies controllable in tests when needed, instead of relying on real delays that make tests unreliable.
- Show understandable error messages to users and log technical details through `LogService`. Do not swallow errors to hide symptoms.

## Source Code Reference

Read the actual source before making decisions. Treat descriptions and AI suggestions as hypotheses until verified, rather than evidence that a bug has been reproduced.

| Topic | Reference |
| --- | --- |
| Requirements, acceptance criteria, and submission rules | `PROBLEM.md` |
| Setup and running the app | `README.md`, `.fvmrc`, `pubspec.yaml`, `pubspec.lock` |
| Dependency lifetime and routing | `lib/main.dart`, `lib/binding/`, `lib/routes/routes.dart` |
| RES-101: search race | `lib/feature/search/search_deals_controller.dart` |
| RES-102: countdown lifecycle | `lib/feature/order/widget/pickup_countdown.dart` |
| RES-103 / RES-107: details lifetime and deep links | `lib/feature/deal/`, `lib/binding/deal_details_binding.dart`, `lib/routes/routes.dart` |
| RES-104 / RES-105: pagination and rendering | `lib/feature/home/`, `lib/feature/shared_widget/deal_card.dart`, `lib/feature/shared_widget/the_network_image.dart` |
| RES-106: pickup time | `lib/model/pickup_window_model.dart`, pickup display and filtering in `lib/feature/` |
| F-1: flash countdown | `lib/feature/home/widget/flash_deals_section.dart`, deal cards/details, `lib/service/cart_service.dart` |
| F-2: impressions and batches | `lib/service/analytics_service.dart`, `lib/feature/analytics_debug/`, card construction in Home/Search |
| F-3: reservations | `lib/service/cart_service.dart`, `lib/repository/order_repo.dart`, `lib/model/reservation_model.dart`, `lib/model/cart_item_model.dart`, `lib/feature/cart/` |
| Backend contract (read only) | `lib/service/fake_api_service.dart`, `assets/data/` |
| Existing test example | `test/model_test.dart` |

### Toolchain & Protected Files

- Use **Flutter 3.27.0** and **Java 17** for Android. Do not upgrade Flutter or packages.
- Assessment exception: **Flutter 3.38.10** is allowed only for debugging on a **physical iPhone running iOS 26**.
- Do not modify `lib/service/fake_api_service.dart` or any files under `assets/data/`, including to make tests pass.
- Use the existing simulated backend. No new backend or API keys are needed.
- Inspect diffs after running tooling. Do not retain unnecessary changes to lockfiles or platform files.

## Workflow

Follow the AI Coding Agent Flow, scaling the detail to the task. Role names in the diagram represent review responsibilities; they do not require multiple agents.

### 1. Requirement Gate & Plan

1. Read the ticket and relevant source. Define acceptance criteria and the Definition of Done before editing.
2. Separate facts, assumptions, and missing information. Ask the user when ambiguity affects the outcome and cannot be resolved from the repository.
3. Break work into small, independently verifiable changes that can be committed separately. Complete one ticket or feature at a time.
4. Assess relevant risks, such as async races, lifecycle, stock consistency, analytics privacy, and performance. Avoid unrelated systems or checklists.

### 2. Baseline, Architecture & Design Review

1. Check `git status` and the toolchain before starting. Preserve the user's existing work.
2. Run the app, reproduce the issue, and record steps, actual behavior, and expected behavior. Record existing analyzer/test failures as well.
3. Trace data flow and state/resource ownership to establish the root cause before fixing it.
4. Compare the proposed approach with at least one alternative, considering correctness, performance, relevant security concerns, maintainability, and time cost.
5. Use a spike or proof of concept only to resolve a specific uncertainty. Define the question and time limit. Revisit the design if the approach fails the evaluation.
6. Before changing RES-105, capture a DevTools baseline on a device with a reproducible scenario. Use profile mode on a supported device for performance measurement; do not draw production performance conclusions from debug frame timings.

### 3. TDD Loop & Failure Analysis

1. For bugs or new behavior, write a test against the acceptance criteria before implementation where practical.
2. Run the test and confirm it fails for the intended reason. If it already passes, check whether it actually reproduces the bug conditions.
3. Classify test/build failures as code, test, requirement, environment, dependency, or architecture problems, then address the cause. Never change an expected result merely to make a test pass.
4. Implement the smallest complete fix, then run targeted tests until they pass.
5. Refactor when there is a clear benefit, then rerun affected tests.
6. Keep meaningful regression tests in the suite. Avoid tests that mirror implementation details or depend on random delays. If automated verification is impractical, document manual reproduction and its limitations.
7. If the same cause repeatedly blocks progress, stop repeating the same attempt. Gather evidence and revisit assumptions before choosing another approach.

### 4. Quality Gates & Integrated Verification

Use the pinned SDK. For example, run the following commands when FVM is configured, or invoke Flutter 3.27.0 directly by its SDK path:

```sh
fvm flutter --version
fvm flutter pub get
fvm dart format <changed-dart-files>
fvm flutter analyze
fvm flutter test test/<relevant_test>.dart
fvm flutter test
git diff --check
```

- Record commands, results, and pre-existing failures separately from issues introduced by the change.
- Verify integration between controllers, services, repositories, and navigation where affected.
- Check affected user flows in the running app, including relevant loading, empty, error, retry, navigation-away, and overlapping async scenarios.
- For RES-106, cover UTC-to-Bangkok transitions across days, months, and years, plus identical day numbers in different months. Tests must not depend on the test machine's current time.
- For RES-105, provide before/after DevTools evidence using the same device, mode, item count, and scrolling scenario. Include verifiable frame timing, rebuild, and memory/image-cache evidence.
- For F-1, verify 100+ countdowns and rebuild scope. For F-2, verify continuous visibility, cross-screen deduplication, and batch thresholds. For F-3, verify rollback, release, expiry, and checkout against the chosen behavior.
- Inspect the diff for secrets, protected-file changes, dependency upgrades, and changes outside the task's scope.
- Documentation-only changes do not require Flutter tests. Check content, paths, and diffs instead.

### 5. Project State, Confidence & Delivery

- Update `solutions.md` throughout the work as a record of requirements, root causes, decisions, rejected alternatives, edge cases, tests, failures, evidence, limitations, and remaining work.
- The AI usage log must identify tools, their uses, and at least two real examples of incorrect or misleading AI suggestions as required by the assessment, including how they were detected and corrected. Never invent incidents or evidence.
- Answer all three design questions in `PROBLEM.md`. Record approximate time spent and what you would do with one more day.
- Base confidence on evidence: close a task when acceptance criteria are met and checks pass; add tests or evidence when gaps remain; return to analysis or redesign when behavior conflicts with requirements.
- Commit one logical change at a time with a ticket prefix, such as `[RES-101] Ignore stale search responses`, and include the related diagnosis. For general documentation work, use a message that clearly describes the change.
- Before delivery, summarize completed work, verification methods, results, and limitations honestly. Every submitted code change must be explainable in an interview.
- The assessment requires a public repository with full commit history and `solutions.md`, followed by an email containing the repository link. Publish the repository or send email only when the user has instructed or authorized it.
