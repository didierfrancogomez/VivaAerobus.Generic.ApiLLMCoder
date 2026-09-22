# Phase 9 — Pre-review (self-review before requesting review)

> **Question it answers:** is it ready to spend another person's time?
> **MANDATORY gate:** run [`process/REVIEW-CODE.md`](REVIEW-CODE.md) on the diff — the local validator that applies
> the same bar as the human reviewers (`guidelines/**`, the task's purpose, blast radius). The
> verdict must be **APPROVED**: any 🐛/❗ finding blocks moving on to Phase 10. For *risky*-level
> changes, additionally run an independent verification pass (the ApiLLM's `evidence-auditor`
> subagent).
> **MANDATORY gate — code style:** `tools/code-style.sh <KEY> verify` must record
> `CODE-STYLE: VERIFIED` on the final commit (§9.5): the team's `Ezy` cleanup profile leaves zero
> deltas on the lines the task added or modified.

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

1. **Run everything locally from clean:** linter, formatting (the `Ezy` profile — gate in §9.5),
   types, static analysis, full test suite, production build.
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

## 9.5 Code-style gate — `Ezy` (mandatory, on the final commit)

Once the diff is final and committed (after §9.3's squash and any §9.4 fixes), run:

```bash
tools/code-style.sh <KEY> verify
```

It runs `jb cleanupcode VivaAerobus.Generic.Api.sln --profile=Ezy` again on the task's `.cs`
files, restores them byte for byte, and classifies every delta the cleanup would still produce.
**Zero deltas may land on lines the task added or modified**. Deltas on pre-existing lines are
expected, because those lines stay as `master` has them (§6.5). The tool writes
`work/<KEY>/phase-06-code-style.md` itself: the command, the scope, the delta table and, at
column 0:

```
CODE-STYLE: VERIFIED
STYLE-SHA: <git -C ../VivaAerobus.Generic.Api rev-parse HEAD>
```

- `CODE-STYLE: FAILED` means the cleanup still rewrites our lines. Go back to §6.5
  (`tools/code-style.sh <KEY> apply`, resolve the `MANUAL` deltas), amend the commit, re-run the
  tests the change affects, and re-run `verify`.
- `STYLE-SHA: UNCOMMITTED` means `verify` ran on files with uncommitted changes. It is useful as
  feedback but never opens the gate. Commit, then re-run `verify`.

The hooks block `git push` / `gh pr create` without `CODE-STYLE: VERIFIED` + `STYLE-SHA`. They
**also block when HEAD drifts from `STYLE-SHA`**: any later commit voids the style check exactly
as it voids `VALIDATED-SHA`. Run `verify` before (or together with) the final REVIEW-CODE pass,
so both anchor to the same commit.

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

Also required before push, and written only by `tools/code-style.sh <KEY> verify` (§9.5):
`work/<KEY>/phase-06-code-style.md` with `CODE-STYLE: VERIFIED` and `STYLE-SHA: <HEAD>`.

**Exit criterion:** you would be comfortable if this diff were shown in a public team review,
`REVIEW-CODE.md` returned APPROVED, the four marker lines above are true, and the Ezy style gate
(§9.5) is `VERIFIED` on the same commit.

**Next:** [Phase 10 — Create the PR and manage the review](phase-10-pr-review.md) — which begins
by **asking the user for publication approval** (`PUSH-APPROVED`); nothing is pushed before that.
