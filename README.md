# VivaAerobus.Generic.ApiLLMCoder

**Implementation** agent for `VivaAerobus.Generic.Api`. Given a Jira task, it runs the mandatory
12-phase process: analyzes (phases 0–4), **stops if there are blockers**, and implements
(phases 5–11) only on a ✅ verdict.

- **Entry points** (open a Claude Code session HERE):
  - **`/implement API-9999`** — new ticket: scaffolds, fetches the ticket, gates and walks the
    12 phases.
  - **`/continue API-9999`** — a ticket whose implementation already started (here or outside
    the pipeline, e.g. a PR with review rounds). Stage A is strictly read-only: fresh ticket
    snapshot (diffed against the previous one = spec-change detector), PR reviews/threads/CI,
    branch drift vs `origin/master` and vs the remote, working-tree hazards (dirty files,
    stashes, foreign branch), evidence coverage per matrix row. Stage B writes
    `work/<KEY>/continue-plan-<date>.md` (classified deltas, open questions, `P-NN` steps, git
    preservation plan, risks) and **always stops for the user's approval**. Stage C executes
    under the git safety protocol (recovery point first, stash-and-never-pop, explicit-path
    staging, no history rewrite beyond an unreviewed HEAD with `--force-with-lease`, fetch
    before push, bounded retries on external dependencies), backfilling phases 0–5 when the
    task was never in the pipeline.
  - **`/defend-changes API-9999`** — before requesting review: an evidence-cited dossier of the
    PR diff vs master (`work/<KEY>/defend-<date>.md`) — per change: who asked (ticket row,
    comment, review thread, guideline ID), why this approach, side effects (dependency map),
    breaking-change checklist for this API — with a verdict per entry
    (DEFENSIBLE / WEAK / UNJUSTIFIED / RISKY) and draft PR replies. Remediation only with
    approval.
- **The orchestrator:** [`CLAUDE.md`](CLAUDE.md) — pipeline, gates, repo layout, the five
  non-negotiable rules (analysis first, no system docs here, evidence first, never a stale
  `main`, the ApiLLM guidelines govern HOW code is written).
- **The process:** [`process/`](process/) — one file per phase + the methodology
  (`ANALYZE-TASK`, `change-playbook`, `REVIEW-CODE`) + annexes (daily checklist, hotfix route,
  team adoption guide, agent execution map) + `_templates/`.
- **Automation:** [`tools/`](tools/) — `new-task.sh` (scaffold + ticket fetch + readiness gate),
  `new-run.sh` (immutable validation runs), `save-progress.sh` (versions `work/<KEY>/` and
  regenerates the task index `work/README.md`), and the **`jira-sync`** bridge
  ([`tools/jira-sync/README.md`](tools/jira-sync/README.md)): `doctor` (toolchain preflight),
  `ticket` (full dump: header, labels, test-flow, description, subtasks with their matrix, all
  comments, every attachment format with date and author), `ready` (Definition-of-Ready gate),
  `deliver` (evidence → matrix `Execution Result` per row via `--results` → comment with the PR
  link → `TestComplete` → *In review* → unassign for QA; `--dry-run` first, always). Output is
  UTF-8 regardless of the console code page.
- **Enforcement:** [`.claude/`](.claude/) — hooks that fast-forward this repo to `origin/main`
  before every prompt, inject the gate state, and deny code-repo writes / `git push` /
  `gh pr create` until the artifact contract is met and the human signatures exist
  (`HUMAN-GATE-OK` for *risky* tasks, `PUSH-APPROVED` for publication — never created by the
  agent).

It works together with two sibling repos (same parent directory):

| Repo | Role |
|---|---|
| `../VivaAerobus.Generic.Api` | The code — where implementation happens |
| `../VivaAerobus.Generic.ApiLLM` | Evidence-cited documentation + analysis pipeline (SYNC / guidelines) |

This repo **does not document the system** (the ApiLLM pipeline does) and **holds no API code** —
only the process and the per-task work artifacts (`work/<KEY>/`, index in
[`work/README.md`](work/README.md); resumable at any time with `/implement` or `/continue`).
Never versioned: human signatures, `work/_active`, ticket dumps and snapshots, attachments,
evidence runs and config backups (they can carry client data or test credentials).
