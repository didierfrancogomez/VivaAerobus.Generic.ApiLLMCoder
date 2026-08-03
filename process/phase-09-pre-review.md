# Phase 9 — Pre-review (self-review before requesting review)

> **Question it answers:** is it ready to spend another person's time?
> **MANDATORY gate with the LLM repo:** run
> `../VivaAerobus.Generic.ApiLLM/llm/REVIEW-CODE.md` on the diff — the local validator that applies
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
4. **Plan (Phase 5):** does the implementation match the approved plan? If you deviated, document
   why.
5. **Anti-scope:** verify no changes outside the agreed scope slipped in.

## 9.3 Final technical hygiene

1. **Run everything locally from clean:** linter, formatting, types, static analysis, full test
   suite, production build.
2. **Clone/build from scratch** (or delete dependencies and reinstall) to detect anything that only
   works on your machine.
3. **Verify migrations:** apply and revert on a clean database and on a database with data.
4. **Clean up the commit history:** interactive rebase, clear messages, no commits like "fix",
   "wip", "almost there". One logical commit per logical change.
5. **Update with the base branch** and re-run the tests after the merge/rebase (semantic conflicts
   do not produce a git conflict).
6. **Assess the PR size:** if it is large, split it. A 1,000-line PR does not get reviewed, it gets
   approved.
7. **Test self-check:** confirm the tests fail without the change.

## 9.4 Local validator gate (REVIEW-CODE.md)

1. Run the ApiLLM's `llm/REVIEW-CODE.md` with: (a) the diff (`git -C ../VivaAerobus.Generic.Api
   diff master...<branch>`), and (b) the ticket + the Stage A analysis.
2. Every finding cites the rule (`STY-NN`/`ARC-NN`/`ROB-NN`/`PRC-NN`) and the exact location.
3. **APPROVED** → continue. **CHANGES_REQUESTED** → fix and re-run the gate. A 🐛/❗ finding is
   never deferred "to the PR".

---

**Artifacts:** clean diff, completed self-review checklist, and
`work/<KEY>/phase-09-pre-review.md` with the validator's result — it MUST contain the literal line
`REVIEW-CODE: APPROVED` (the hooks block `git push` / `gh pr create` without it). It is written
only when `REVIEW-CODE.md` actually returned APPROVED.

**Exit criterion:** you would be comfortable if this diff were shown in a public team review, and
`REVIEW-CODE.md` returned APPROVED.

**Next:** [Phase 10 — Create the PR and manage the review](phase-10-pr-review.md)
