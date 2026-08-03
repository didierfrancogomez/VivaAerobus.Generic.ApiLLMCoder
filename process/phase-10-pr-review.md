# Phase 10 — Create the PR and manage the review

> **Question it answers:** transfer context and obtain approval.
> **Precondition:** APPROVED verdict from the Phase 9 gate (`process/REVIEW-CODE.md`), green CI, and
> the **user's explicit publication approval** (§10.0 — `work/<KEY>/PUSH-APPROVED`).

**Goal:** transfer all the context from phases 0–9 to the reviewer with the least possible effort
on their part.

## 10.0 User approval to publish (MANDATORY, enforced)

Nothing leaves the machine without the user's explicit yes. Before any `git push` or
`gh pr create`:

1. **Present the user a publication summary:** the single squashed commit (message + short diff
   stat), the Phase 9 result (the four marker lines), the deviations section of the plan (empty
   or approved), and the draft PR title/description.
2. **Ask for approval and WAIT.** The user signs by creating the file by hand:
   `touch work/<KEY>/PUSH-APPROVED`. The agent is **forbidden** from creating it (the hooks deny
   it, same as `HUMAN-GATE-OK`), and the hooks deny push/PR while it does not exist.
3. If the user asks for changes, apply them and **go back through Phase 9** (the new commit voids
   `VALIDATED-SHA`; the gate re-closes on its own) before asking again.

## 10.1 Building the PR

1. **Title:** written **explicitly by hand**, client convention (PRC-102/PRC-103):
   `API-<n> <gitmoji> <imperative, concrete description>` — never GitHub's branch-derived
   default (`Feature/api 1662/sp change services` is the documented anti-pattern). It should be
   understandable without opening the PR. The code repo's own
   `.github/pull_request_template.md`, when present, is authoritative over the template below.
2. **Description using the template:**

```markdown
## Ticket
KEY-123 (link)

## Context and problem
What problem it solves and why it matters. 2–4 lines.

## Solution
What this change does, at a high level. How it works.

## Alternatives considered
What else I evaluated and why I chose this. (Avoids 80% of the "why didn't you do X?" comments.)

## Impact radius
What is affected and what is NOT affected. Consumers, data, contracts, configuration.

## How to test it
Concrete steps, test users/data, what should be observed.

## Evidence
Screenshots / video / sample responses. Before and after.

## Migrations / data
Yes/No. Reversible? Estimated duration. Backfill?

## Feature flag
Name, default value, cleanup ticket.

## Risks and rollback plan
What can go wrong, which signal to watch, how it is reverted.

## Assumptions to confirm
List for the reviewer.

## Checklist
- [ ] Acceptance criteria covered
- [ ] Tests added/updated and green CI
- [ ] Impact radius reviewed
- [ ] Documentation updated
- [ ] Configuration provisioned in all environments
- [ ] No secrets or sensitive data
- [ ] REVIEW-CODE.md (local validator) → APPROVED
```

3. **Link bidirectionally:** the PR references the ticket and the ticket references the PR. Also
   link dependent PRs and the merge order.
4. **Labels and metadata:** type, area, size, "requires migration", "breaking change",
   "needs coordinated deployment".
5. **Choose reviewers deliberately:** whoever knows the code, whoever owns the impacted area
   (CODEOWNERS), and whoever consumes the contract if you changed it. One or two reviewers, not
   eight.
6. **Self-annotate the diff:** leave your own comments on the non-obvious parts, explaining the why
   and pointing out where you want special attention. It saves rounds.
7. **Draft vs. ready:** if something is missing or you want early directional feedback, mark it as
   a draft and say so. Do not request a formal review of something incomplete.
8. **Green CI before requesting review.** Requesting a review with a red pipeline is transferring
   your work to the reviewer.

## 10.1b Update Jira (delivery — same approval as the push)

With the PR open, deliver the ticket via the vendored bridge (`tools/jira-sync/README.md`),
covered by the same user approval that signed `PUSH-APPROVED` (delivery is outward: it uploads
evidence, comments, changes labels/status/assignee):

```bash
python tools/jira-sync/jira_sync.py deliver <KEY> \
    --evidence <dir with Issue/Solution pairs + collection JSON> \
    --pr <n> --comment "<which S-NN ran where; evidence attached>" --dry-run
```

**Always `--dry-run` first and show the user the plan**; re-run without it only after they agree.
`deliver` performs, in order: evidence → comment → **adds `TestComplete` keeping `TestCaseReady`**
(PRC-105) → transition to *In review* → **unassign so QA picks it up** (PRC-106). It aborts on a
failed upload or transition, leaving the ticket in the most truthful reachable state. The
evidence naming is `Issue`/`Solution` per PRC-104. Record the run in `delivery-state.md`.

## 10.2 Managing the review — and the rework loop

**When comments come back** (PR review or QA rejection returning the ticket to In Progress — a
*devolución*, counted in the ticket header; normal, not a crisis), the loop is:

1. **Open a fresh run**: `tools/new-run.sh <KEY>` — archives phase-07/09 + `PUSH-APPROVED` into
   `validation/run-NNN/` and mechanically re-closes the publication gates. Old evidence never
   validates new code.
2. **Collect every comment** — PR thread (`gh pr view <n> --comments`) AND the re-fetched ticket
   (comments may retire or add `S-NN` rows). Resolve each one explicitly: a fix or a reasoned
   reply, never silence. Guideline IDs named in a comment are binding.
3. **Fixer discipline (bounded rework):** attack only the reported findings with the minimum
   change; no opportunistic refactors; no new features; re-run exactly the gate that failed plus
   whatever the patch touches. If the fix requires design changes or exceeds the findings, go
   back to Phase 4/5 — do not improvise inside the rework.
4. **Fix commits on the same branch** (no force-push over reviewed history), then back through
   Phase 7 (affected `S-NN` + smoke) and Phase 9 (fresh markers, new `VALIDATED-SHA`), ask the
   user to re-approve, and **re-deliver** (§10.1b) — it re-attaches only what is new and
   unassigns again for QA.

Day-to-day review conduct:

1. **Notify the reviewer** through the team channel with one line of context and the real urgency.
2. **Respond to every comment**, even just to say "done" or to disagree with an argument. Nothing
   left unanswered.
3. **Disagree well:** with technical reasons, without defending your ego. If after two rounds there
   is no agreement, escalate to a third party instead of continuing in the thread.
4. **Changes in new commits** during the review (do not rewrite history while they are reviewing,
   or give notice if you do).
5. **If a comment reveals a scope gap or a design problem:** go back to the corresponding phase; do
   not patch over it.
6. **Explicitly re-request review** when you finish the changes, summarizing what was adjusted.
7. **Turn out-of-scope comments into tickets** and link them, instead of expanding the PR.
8. **Mind the timing:** team agreement (e.g., first response within one business day). A PR that
   stays open for a week becomes a merge conflict and loses context.

## 10.3 Merge

1. Verify: required approvals, green CI, resolved conversations, up-to-date branch, dependencies
   already merged in the correct order.
2. Use the team's merge strategy consistently — the policy is **squash**, so the PR lands on
   `master` as one clean commit even if the review added fix-up commits (§10.2.4).
3. Merge when you can accompany the deployment — not right before leaving.
4. Delete the branch.
5. Move the ticket to the corresponding status and leave the closing comment.

---

**Artifacts:** documented PR, approvals, history of review decisions.

**Exit criterion:** merged with green CI and the ticket updated.

**Next:** [Phase 11 — Post-merge and closure](phase-11-post-merge.md)
