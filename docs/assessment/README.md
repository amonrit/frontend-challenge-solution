# Assessment Documentation Standard

Use one document set per ticket:

```text
<ticket>-scope.md
<ticket>-questions.md
<ticket>-answers.md
<ticket>-options.md
<ticket>-tdd-readiness.md
<ticket>-task-breakdown.md
```

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
record actual completion order in its `Work order` section.
