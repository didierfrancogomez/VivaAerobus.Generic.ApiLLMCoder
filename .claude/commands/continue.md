---
description: Resume a ticket after time has passed — reconcile Jira/PR/branch state, present a plan for approval, then run the rework loop to green
argument-hint: API-9999
---

Resume work on **$ARGUMENTS** whose implementation already started (possibly outside this
pipeline). `CLAUDE.md` is the orchestrator; the phases and `process/REVIEW-CODE.md` remain
authoritative. The four NON-NEGOTIABLE rules apply in full. This command adds two things over
`/implement`: a **reconciliation stage** that detects what changed while nobody was looking, and
a **mandatory plan-approval gate** — nothing is written anywhere (code, PR, Jira, config) until
the user approves the plan.

## Stage A — Gather current state (STRICTLY read-only)

Rule for this stage: no writes, no checkouts, no stashes, no config changes, no process kills.
Gathering must leave the machine exactly as found.

1. **Preflight**: `tools/jira-sync/.venv` python → `jira_sync.py doctor`. Hard failure → STOP and
   tell the user what to fix. Also record environment facts the plan depends on: docker
   containers up, DotRez QA reachable, local API running (and whose process it is).
2. **Sync the ApiLLM docs** (its `CLAUDE.md` step 1). STALE ⇒ reason from code and say so in the
   plan.
3. **Ticket, fresh**: `jira_sync.py ticket $ARGUMENTS`. Read the WHOLE dump: status, labels,
   devoluciones, PR + PR status, description **test matrix**, the evidence subtask (rows,
   execution results, attachments), and every comment — comments retire/replace test cases.
   **Snapshot discipline**: copy the dump to `work/$ARGUMENTS/ticket-snapshots/<YYYY-MM-DD-HHmm>.txt`
   (this folder is the one write allowed in Stage A — it is pipeline state, not target state).
   If an earlier snapshot exists, `diff` them — that diff IS the spec-change detector.
4. **Git, remote truth — without touching the tree**: `git fetch origin` in the code repo.
   Locate the branch from the PR (fallback `feature/$ARGUMENTS/*`). Record, all read-only:
   - current checked-out branch and HEAD SHA (the session may be standing on a DIFFERENT ticket);
   - working-tree state: staged, unstaged, untracked files (`git status --porcelain`) and
     existing stashes (`git stash list`) — these belong to the user until proven otherwise;
   - local vs `origin/<branch>`: unpushed / unpulled commits (someone else may have pushed —
     e.g. a teammate or another tool fixed something directly);
   - commits behind `origin/master` and whether integration would conflict
     (`git merge-tree $(git merge-base origin/master <branch>) <branch> origin/master`).
5. **PR, complete**: `gh pr view <n>` + `gh api .../pulls/<n>/reviews` + `.../pulls/<n>/comments`
   (+ issue comments). Record: review verdicts still standing (CHANGES_REQUESTED with no later
   approval), every thread and whether it has a reply or a code change **after** its timestamp,
   and CI status.
6. **Local pipeline state**: does `work/$ARGUMENTS/` exist? If yes read `delivery-state.md`
   (resume — never redo passed phases). If no, this is an **adoption**: phases 0–5 will be
   backfilled against the ticket and the existing diff, at the rigor the ticket warrants —
   analysis of existing code is still analysis, not a rubber stamp.

## Stage B — Reconcile, plan, and STOP for approval

7. Produce the **status summary**: ticket status · spec deltas (new/changed/retired matrix rows
   since the last snapshot or vs `phase-05-plan.md`) · PR state (open change requests, unanswered
   threads, CI) · branch drift (behind master, conflicts y/n, unpulled remote commits) ·
   working-tree hazards (dirty files, stashes, foreign branch checked out) · **evidence
   coverage**: every current matrix row mapped to evidence that post-dates the last code change —
   missing, stale, or contradicted evidence is a gap.
8. Classify every delta, one by one:
   - **bounded rework** (a reported finding, minimal fix) → Phase 10 §10.2 discipline;
   - **scope/design change** (a requirement moved) → back through Phase 4/5 first;
   - **question** (ambiguous, contradictory, or needs the requester/QA — including unusable test
     credentials) → blocking, phrased per phase-04 §4.2 with options and a recommendation.
9. Write the **plan** to `work/$ARGUMENTS/continue-plan-<YYYY-MM-DD>.md` and present it in full:
   - the status summary (7) and classified deltas (8);
   - **open gaps and questions** — even non-blocking ones, so the user decides with everything
     visible;
   - numbered steps `P-NN`, each naming the exact files/systems it will touch;
   - the **git preservation plan** (what gets stashed/kept, recovery point SHA);
   - risks and the rollback path for each mutating step.
10. **STOP — always.** Even with zero open questions. Proceed only after the user approves the
    plan explicitly (their approval and date are recorded in `delivery-state.md`). Blocking
    questions ⇒ the plan is not approvable: post the questions (to the ticket only with the
    user's ok), mark the task blocked, done. If executing later deviates from the approved plan
    in any way, come back to this gate with the delta — silent deviation is falsifying the plan.

## Stage C — Execute (gated; the existing pipeline plus the safety protocol below)

**Git safety protocol — binding for every step:**
- **Recovery point first**: before any mutation, record branch + HEAD SHA + `status --porcelain`
  into `work/$ARGUMENTS/continue-recovery.md`.
- **Preserve what is not yours**: if the tree is dirty or on another branch's work, stash with a
  label — `git stash push -u -m "continue/$ARGUMENTS <date> auto-preserve"` — record the stash
  ref in the recovery file, and **never pop it automatically** (it may belong to another branch);
  report to the user how to restore it. Pre-existing stashes are never dropped or popped.
- **Touch only planned paths**: stage by explicit path (`git add <file>…`), never `add .`/`-A`.
  Before requesting push approval, show `git diff --cached --stat` and reconcile it against the
  plan's file list — any file outside the plan stops the run.
- **Forbidden on the code repo**: `reset --hard`, `clean -f`, `checkout -- <paths>` over files
  not created this run, dropping stashes, interactive rebase, any rewrite deeper than HEAD.
  The only rewrite allowed is amending the **last commit** under the **history rewrite policy**
  (`defend-changes.md` §7): HEAD unreviewed (re-verified immediately before the push) +
  `--force-with-lease` + user approval + pre-rewrite SHA recorded; otherwise fix-forward.
- **Remote safety**: fetch immediately before push; if the remote branch advanced, integrate
  (merge) and re-run the affected gates — never overwrite.
- **Catch up with master when needed** (conflicts or meaningful drift): `git merge origin/master`
  into the branch and say so in the PR. Rebase only if the PR has no review activity yet.
- **Processes**: stop only processes this run started (record PIDs). Anything else running (the
  user's API instance, docker containers) is stopped only with the user's ok in the plan.
- **Config/seed safety**: before any admin-config `set` (e.g. `seed-marten-document.ps1`), `get`
  and save the current value under `work/$ARGUMENTS/config-backups/`; restore after evidence
  unless the change IS the deliverable.
- **Secrets hygiene**: ticket dumps and QA credentials stay in gitignored paths; never paste
  credentials or tokens into commits, PR comments, Jira comments, or evidence images.
- **Bounded retries**: an external dependency failing twice (locked QA account, DotRez 5xx,
  dead container) becomes a question/blocker in the report — never a retry loop, never a
  workaround that mutates shared state.

Execution order (each step closes by updating `delivery-state.md`; any deviation → back to §10):

11. `tools/new-run.sh $ARGUMENTS` when prior validation exists — old evidence never validates new
    code. Backfill/refresh phases 0–5 artifacts as classified (the hooks demand them).
12. Implement ONLY the planned `P-NN` steps — `guidelines/**` bind; minimal diff; no
    opportunistic refactors; out-of-scope findings become new tickets (Phase 6.4).
13. Phase 7: full suite green + every affected `S-NN` + **new rows get new test cases and fresh
    evidence** (named per the ticket's convention). `TESTS: GREEN` recorded.
14. Phase 9: `process/REVIEW-CODE.md` to APPROVED, fresh markers, new `VALIDATED-SHA`. Fix
    commits stay on the same branch (squash happens at merge, §10.3).
15. **Publication is the user's**: present the summary + staged diff-stat, WAIT for
    `work/$ARGUMENTS/PUSH-APPROVED` (never create it). Then push; **answer EVERY open PR
    thread** — a fix reference or a reasoned reply, never silence; never resolve or dismiss a
    reviewer's thread; re-request review with a one-paragraph "what changed" summary.
16. Jira: `jira_sync.py deliver $ARGUMENTS … --dry-run` first, show the plan, deliver on the
    user's yes (new evidence to the subtask, comment with the PR link, subtask matrix updated to
    match the ticket description).
17. Close with `tools/save-progress.sh $ARGUMENTS "continue"`, report the stash/recovery status
    (anything preserved in Stage C and how to restore it), and tell the user the folder.

Every human gate stands: doctor, the Stage B plan approval, HUMAN-GATE for risky, PUSH-APPROVED,
deliver dry-run. Steps owned by humans are never claimed done (Annex D §D.1).

Before requesting review (here or after `/implement`), run `/defend-changes $ARGUMENTS` — its
dossier catches unjustified diffs, side effects and breaking changes while they are still cheap
to fix, and its drafts become the PR replies.
