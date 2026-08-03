# Phase 9 — Pre-review (self-review before requesting review)

> **Question it answers:** is it ready to spend another person's time?
> **MANDATORY gate:** run [`process/REVIEW-CODE.md`](REVIEW-CODE.md) on the diff — the local validator that applies
> the same bar as the human reviewers (`guidelines/**`, the task's purpose, blast radius). The
> verdict must be **APPROVED**: any 🐛/❗ finding blocks moving on to Phase 10. For *risky*-level
> changes, additionally run an independent verification pass (the ApiLLM's `evidence-auditor`
> subagent).

**Goal:** do not spend a teammate's time on things you could have caught yourself. Review your diff
as if it belonged to someone else you feel no affection for.

## 9.1 Review of the full diff

1. **Read the entire diff, file by file, line by line**, in the comparison interface (not in the
   editor). It is surprising what shows up.
2. **Remove noise:** debug code, `console.log`, prints, test comments, commented-out code, TODOs
   without a ticket, unrelated formatting changes, temporary files, dependencies you added and no
   longer use.
3. **Verify nothing slipped in:** local configuration files, `.env`, credentials, tokens, absolute
   paths from your machine, real customer data, large binary files, unapproved dependencies.
4. **Verify there are no accidental changes:** files you touched by mistake, unintentional lockfile
   changes, involuntary reverts of other people's code.
5. **Readability pass:** names, overly long functions, deep nesting, introduced duplication,
   unexplained magic. Would you understand it in six months?
6. **Robustness pass:** null cases, unhandled errors, dangerous default values, unbounded
   operations, queries without pagination.
7. **Security pass:** server-side validation, authorization on every new endpoint, sensitive data
   kept out of logs and responses.

## 9.2 Closing the loop with the previous phases

1. **Acceptance criteria:** walk through them one by one and mark each with the evidence of how it
   is met.
2. **Impact matrix (Phase 2):** walk through it in full and confirm every row is addressed or
   explicitly ruled out. **This is the step that prevents the most incidents.**
3. **Assumption log (Phase 4):** every assumption is validated, or it is noted in the PR for the
   reviewer to confirm.
4. **Deviation audit (Phase 5's plan is the contract):** compare the diff against
   `phase-05-plan.md` piece by piece. Every deviation must be (a) **approved by the user** and
   (b) **documented in the plan's `## Deviations (approved)` section**. An unapproved or
   undocumented deviation sends the work back to Phase 4/5 — it is never "explained in the PR"
   instead. Outcome recorded as `DEVIATIONS: NONE` or `DEVIATIONS: APPROVED-AND-DOCUMENTED`
   (the hooks demand one of the two before push).
5. **Anti-scope:** verify no changes outside the agreed scope slipped in.
6. **Final completeness re-validation (mandatory before calling it implemented):** with the three
   sources side by side — the **Jira task** (description, acceptance criteria, comments — a
   comment may have retired matrix rows), the **plan** (every numbered `P-NN` step, every
   specific plan) and the **code** (the full diff) — confirm that nothing remains uninvolved:
   no acceptance criterion without code, no `P-NN` without its diff, no impact-matrix row
   without its change or its explicit discard, no `S-NN` scenario without its Phase 7 evidence
   row or written non-applicability. The audit is row-by-row over the numbered lists, not an
   impression. Only when the three agree is `COMPLETENESS: VERIFIED` recorded (the hooks demand
   it before push).

## 9.3 Final technical hygiene

1. **Run everything locally from clean:** linter, formatting, types, static analysis, full test
   suite, production build.
2. **Clone/build from scratch** (or delete dependencies and reinstall) to detect anything that only
   works on your machine.
3. **Verify migrations:** apply and revert on a clean database and on a database with data.
4. **Squash into ONE clean commit (team policy):** the PR carries a single commit containing the
   whole solution, conventional message with the ticket key, explaining the *why*. The
   development checkpoints (Phase 6) disappear here — e.g.
   `git reset --soft master && git commit` (interactive rebase is not available to the agent
   harness). This single commit is the one `VALIDATED-SHA` anchors to.
5. **Update with the base branch** and re-run the tests after the merge/rebase (semantic conflicts
   do not produce a git conflict).
6. **Assess the PR size:** if it is large, split it. A 1,000-line PR does not get reviewed, it gets
   approved.
7. **Test self-check:** confirm the tests fail without the change.

## 9.4 Local validator gate (REVIEW-CODE.md)

1. Run `process/REVIEW-CODE.md` with: (a) the diff (`git -C ../VivaAerobus.Generic.Api
   diff master...<branch>`), and (b) the ticket + the Stage A analysis.
2. Every finding cites the rule (`STY-NN`/`ARC-NN`/`ROB-NN`/`PRC-NN`) and the exact location.
3. **APPROVED** → continue. **CHANGES_REQUESTED** → fix and re-run the gate. A 🐛/❗ finding is
   never deferred "to the PR".

---

**Artifacts:** clean diff squashed into one commit, completed self-review checklist, and
`work/<KEY>/phase-09-pre-review.md` (skeleton: `process/_templates/validation-report.md`;
on rework, the previous one was archived by `tools/new-run.sh` into `validation/run-NNN/` —
runs are immutable, never edited). The hooks block `git push` /
`gh pr create` unless the file contains ALL of these lines at column 0, each written only when it
is actually true (recording one without doing the work is falsifying the gate):

```
REVIEW-CODE: APPROVED
VALIDATED-SHA: <git -C ../VivaAerobus.Generic.Api rev-parse HEAD — the squashed commit>
COMPLETENESS: VERIFIED
DEVIATIONS: NONE            (or DEVIATIONS: APPROVED-AND-DOCUMENTED)
```

⚠️ **Diff drift:** if the code repo's HEAD changes after this file is written (any new commit),
the approval is void — the hooks deny the push until `REVIEW-CODE.md` is re-run on the current
diff and `VALIDATED-SHA` is updated.

**Exit criterion:** you would be comfortable if this diff were shown in a public team review,
`REVIEW-CODE.md` returned APPROVED, and the four marker lines above are true.

**Next:** [Phase 10 — Create the PR and manage the review](phase-10-pr-review.md) — which begins
by **asking the user for publication approval** (`PUSH-APPROVED`); nothing is pushed before that.
