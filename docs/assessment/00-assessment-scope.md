# Rescu Assessment Scope

## Purpose

This folder records the work before implementation. It separates what the assessment asks for from hypotheses, solution options, research, and verification results.

Each ticket or feature will have its own file and follow this sequence:

1. Restate the required outcome and completion criteria.
2. List clarifying questions, likely questions from a reviewer, and edge cases.
3. Describe how the current behavior can be reproduced and observed.
4. Compare possible fixes, including trade-offs and rejected options.
5. Research framework or platform guidance when a choice depends on it.
6. Define fair tests and measurements before implementation.
7. Complete the TDD and execution-readiness checklists.
8. Implement only after the approach and success criteria are clear.

The files record plans and evidence. They do not claim a root cause or a completed fix until the behavior has been reproduced and verified.

## Required Pre-Execution Gates

Every selected ticket or feature must include these sections before its execution tasks:

### TDD Checklist

- [ ] A testable acceptance criterion is written in plain language.
- [ ] The test level is chosen: unit, widget, route-level widget, integration, or manual.
- [ ] A deterministic test input exists, including controlled time, API response, or state where needed.
- [ ] The test fails before the fix or feature implementation for the intended reason.
- [ ] The failure signal identifies the required behavior, not an unrelated setup failure.
- [ ] The post-change assertion proves the requested behavior and relevant cleanup or rollback.

### Execution Readiness Checklist

- [ ] Root cause or required behavior is supported by source and reproduction evidence.
- [ ] Constraints and protected files are identified.
- [ ] Candidate approaches are compared against correctness, lifecycle, performance, scope, and testability.
- [ ] The chosen approach and rejected alternatives have written reasons.
- [ ] Edge cases and failure states have planned checks.
- [ ] Expected files, test commands, and manual verification flow are listed.
- [ ] The work is small enough for one logical ticket commit.

## Assessment Requirements

### Part A — Bug Tickets

| Ticket | Required outcome |
| --- | --- |
| RES-101 | Search results must always match the latest query, including when the search field is cleared. |
| RES-102 | Leaving My orders must not cause `setState() called after dispose()`. |
| RES-103 | Closing deal pages must not leave listeners that continue to request deal data. |
| RES-104 | Refreshing while loading a later Home page must not create duplicate deals or corrupt pagination. |
| RES-105 | Home scrolling and memory use must improve, with DevTools before/after evidence. |
| RES-106 | Pickup times and the “Pickup today” filter must use the Bangkok market timezone correctly. |
| RES-107 | `rescu://open/deal?id=42&source=push` must open a working deal-details page. |

For every selected ticket: reproduce the behavior, establish the root cause, fix it properly, verify it, and document the diagnosis in `solutions.md` at submission time.

### Part B — Features

| Feature | Required outcome |
| --- | --- |
| F-1: Flash-sale countdown | Show a live countdown in the flash rail, Home cards, and details. Expired deals cannot be added, are removed from the bag with a notice, and 100+ countdowns must have a narrow rebuild scope. |
| F-2: Impression tracking | Log one impression per deal per app session after the card is at least 50% visible for one continuous second. Include source and position; batch delivery at 10 events or 15 seconds. |
| F-3: Stock reservations | Add optimistically, reserve with the API, roll back failed reservations, display five-minute reservation time, release or adjust holds, pass reservation IDs to checkout, and handle expired reservations. |

For every selected feature: implement the complete user-visible flow, relevant failure behavior, and the required performance verification.

### Part C — Written Deliverables

At submission, create `solutions.md` at the repository root with:

1. The root cause, solution rationale, rejected alternative, and edge cases for completed tickets and features.
2. An AI usage log, including two real examples of misleading or incorrect AI advice and how it was corrected.
3. Short answers on GetX versus widget lifecycles, large `Obx` scopes, and automated testing for RES-106.
4. Approximate time spent and work planned for one additional day.
5. DevTools before/after evidence for RES-105.

## Constraints

- Use Flutter 3.27.0 and Java 17 for Android. Do not upgrade Flutter or packages.
- Do not modify `lib/service/fake_api_service.dart` or `assets/data/`.
- Commit one logical change at a time with the ticket prefix, for example `[RES-101] Ignore stale search responses`.
- Submit a public repository with the full commit history and `solutions.md`.

## Planned File Order

| File | Purpose | Status |
| --- | --- | --- |
| `00-assessment-scope.md` | Requirements and investigation workflow | Complete |
| `01-res-102-questions.md` | RES-102 questions before task breakdown | Complete |
| `02-res-102-answers.md` | Evidence-backed RES-102 answers before task breakdown | Complete |
| `03-res-102-task-breakdown.md` | RES-102 tasks and method-comparison plan | Complete |
| Later files | One file per selected ticket or feature | Not started |

The next RES-102 file will cover reproduction, solution options, research, and test design only after the remaining questions have evidence or an explicit scope decision.
