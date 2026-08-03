# Phase 10 — Create the PR and manage the review

> **Question it answers:** transfer context and obtain approval.
> **Precondition:** APPROVED verdict from the Phase 9 gate (`llm/REVIEW-CODE.md`) and green CI.

**Goal:** transfer all the context from phases 0–9 to the reviewer with the least possible effort
on their part.

## 10.1 Building the PR

1. **Title:** `KEY-123: imperative, concrete description`. It should be understandable without
   opening the PR.
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

## 10.2 Managing the review

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
2. Use the team's merge strategy (squash / merge commit / rebase) consistently.
3. Merge when you can accompany the deployment — not right before leaving.
4. Delete the branch.
5. Move the ticket to the corresponding status and leave the closing comment.

---

**Artifacts:** documented PR, approvals, history of review decisions.

**Exit criterion:** merged with green CI and the ticket updated.

**Next:** [Phase 11 — Post-merge and closure](phase-11-post-merge.md)
