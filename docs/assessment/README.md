# Assessment Documentation Standard

Use one document set per ticket:

```text
<ticket>/
├── scope.md
├── questions.md
├── answers.md
├── options.md
├── tdd-readiness.md
└── task-breakdown.md
```

The repository keeps the original RES-102 content under `102/` with the same
standard filenames as the other ticket folders.

## Document roles

1. **Scope** — requested outcome, constraints, out-of-scope items, and current
   workflow state.
2. **Questions** — unanswered requirement, lifecycle, edge-case, observability,
   test, and evidence questions only.
3. **Answers** — evidence-backed answers in a table with `Question`, `Answer`,
   and `Evidence` columns, followed by verified facts and follow-up limits.
4. **Options** — confirmed problem boundary, compared approaches, decision,
   rejected alternatives, and trade-offs.
5. **TDD readiness** — acceptance criteria, deterministic seam, RED signal,
   GREEN assertion, edge cases, files, commands, and RED result.
6. **Task breakdown** — execution table with ID, purpose, files, dependency,
   acceptance assertion, variants, and status.

Use the same status vocabulary in every task table: `Planned`, `Next`,
`In progress`, `Complete`, or `Follow-up`. Mark unverified runtime facts as
follow-up limits rather than completed evidence.

Update the relevant document after each workflow phase or execution task. Keep
the summary in [`../../solutions.md`](../../solutions.md) ordered by ticket ID;
use its status summary as the current delivery record. Investigation answers
preserve the source snapshot from their evidence-collection phase. When such a
row says “current”, it refers to that recorded snapshot; the scope, task
breakdown, and `solutions.md` record the delivered state.
