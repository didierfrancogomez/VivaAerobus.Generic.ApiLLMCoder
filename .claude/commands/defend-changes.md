---
description: Build an evidence-cited defense of a PR's diff vs master — who asked each change, why this approach, side effects and breaking changes — then remediate what cannot be defended
argument-hint: API-9999 (or a PR number)
---

Defend the changes of **$ARGUMENTS**'s PR as they will land on `master`. "Defend" means
**evidence, not rationalization**: every statement cites a source (ticket text, a named comment,
a guideline ID, a code path). A change whose requester or reason cannot be cited is not defended —
it is a **finding**. Run this after `/implement` or `/continue`, before requesting review or
`PUSH-APPROVED`, and again before merge when the PR sat idle.

## Stage A — Scope (STRICTLY read-only; leaves the machine exactly as found)

1. Resolve the PR and branch (`gh pr view`, fallback `feature/$ARGUMENTS/*`); `git fetch origin`.
2. The **reviewed diff** is `merge-base(origin/master, branch)..branch` — what the reviewer sees.
   Additionally record how far `origin/master` has moved since the merge-base: commits the branch
   has NOT seen can interact with it even without textual conflicts (**semantic drift** — e.g.
   master changed a schema or a shared builder the branch also touches). List the master commits
   touching any file or symbol the branch touches.
3. Load the traceability sources: the fresh ticket dump (requirements, matrix, every comment with
   author + date), PR reviews and threads (who requested what, when), `work/$ARGUMENTS/` artifacts
   (plan `P-NN` steps, continue-plans, verdicts), and commit messages on the branch.
4. Sync the ApiLLM docs (its `CLAUDE.md` step 1); use `documents/cross-module/dependency-map.md`
   for impact tracing — STALE docs ⇒ trace from code and say so.

## Stage B — The defense dossier (per change, no exceptions)

Write `work/$ARGUMENTS/defend-<YYYY-MM-DD>.md`. For **every** changed file — and within it every
logically distinct change — one entry:

| Field | Content |
|---|---|
| What | One-sentence factual description of the change |
| Who asked / why | The citable source: ticket part/matrix row, requirement comment (author+date), PR review comment (author+id), guideline ID, or bugfix evidence. **No source found ⇒ verdict UNJUSTIFIED** — never invent a rationale |
| Why this approach | The reasoning, and the alternatives that were (or should have been) considered. If a simpler/cleaner approach exists, name it honestly |
| Side effects | Every caller/consumer of the touched symbols (dependency map + search), endpoints sharing the code path, DI/registration changes, serialization/contract surface, config parts and seeds |
| Breaking changes | Explicit yes/no with evidence, against this API's checklist below |
| Verdict | **DEFENSIBLE** · **WEAK** (works, better approach exists) · **UNJUSTIFIED** (no citable reason — candidate to revert) · **RISKY** (side effect or breaking change without mitigation) |

**Breaking-change checklist for this API** (the main focus of the review — check each against the
diff AND against the semantic drift from step A.2):

- Output models: fields removed/renamed/nulled, values newly masked or unmasked, types changed —
  consumers (web/mobile/kiosk) see this immediately;
- Booking-rules criteria and config-part schemas: new/renamed toggles, changed defaults, seeds out
  of sync with schema (a drifted settings document 500s at runtime, not at compile time);
- DotRez request projections: removed/added fields change what downstream code can read;
- DI: constructor/registration changes that alter lifetimes or resolution;
- Endpoint behavior for existing flows: anything that changes a response for a request that
  worked before, including performance-relevant call patterns (per-item fan-outs);
- Error surface: new error codes/status changes.

Close the dossier with: summary table (one row per entry), the **open questions** (UNJUSTIFIED and
RISKY entries phrased per phase-04 §4.2), and **draft PR defense comments** — ready to paste per
reviewer thread or as a PR summary comment. Drafts only: nothing is posted in this stage.

## Stage C — Present, then remediate only with approval

5. Present the dossier summary + verdicts + drafts. **STOP.** Nothing is written to code, PR, or
   Jira without the user's explicit approval of a remediation plan (same gate discipline as
   `/continue` Stage B — silent deviation is falsifying the plan).
6. Approved remediations follow the `/continue` Stage C safety protocol (recovery point, labeled
   stash, planned paths only, bounded fixes, fresh gates via `new-run.sh` when validation exists):
   - **UNJUSTIFIED** → default remedy is revert, not justification-after-the-fact; keeping it
     requires the requester's explicit confirmation on the ticket;
   - **WEAK** → fix only if the reviewer asked or the user opts in; otherwise record the better
     approach in the dossier and move on — no opportunistic refactors;
   - **RISKY** → mitigate (guard, config default, migration note) or revert; a knowingly-shipped
     breaking change needs the requester's written sign-off on the ticket.
7. **History rewrite policy** (applies here and to `/continue` fixes). The ONLY rewrite these
   commands may perform is `git commit --amend` of the **last commit (HEAD)** — never an
   interactive rebase, never anything deeper, never a rewrite of already-reviewed rounds; if more
   than HEAD would need rewriting, it is fix-forward with new commits (§10.2.4), no exceptions.
   Amending HEAD requires ALL of:
   (a) **HEAD has zero review activity** — no review submitted, no thread, no comment on or after
       it. Because a reviewer can start at any moment, re-verify this **immediately before the
       push** (fresh `git fetch` + `gh` reviews/comments check); any activity that appeared since
       the plan ⇒ abort the amend and convert to a fix-forward commit;
   (b) `--force-with-lease` (never bare `--force`) — aborts if the remote moved;
   (c) the user approved the amend in the remediation plan;
   (d) never on `master`;
   (e) the pre-rewrite SHA recorded in `work/$ARGUMENTS/continue-recovery.md` first.
8. Posting: PR comments (defense replies, "what changed" summary) and Jira updates go out only
   after the user approves the drafts; pushes wait for `work/$ARGUMENTS/PUSH-APPROVED` as always.
9. Close with `tools/save-progress.sh $ARGUMENTS "defend-changes"`; the dossier is part of the
   task's memory — the next `/continue` reads it as prior state.

Hard rules: read-only until Stage C approval · a defense without a citation is a finding, never
prose · the dossier reports what it could NOT verify (`unknown — not found`) instead of omitting
it · reviewer threads are answered, never resolved or dismissed by the agent · credentials and
ticket-dump contents never appear in the dossier drafts destined for the PR.
