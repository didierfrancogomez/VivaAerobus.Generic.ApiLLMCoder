# Annex D — Agent execution map: who does what, and how Jira is reached

> The process files are written for the whole team — human developers AND the agent. But several
> steps name capabilities the agent does not have (posting to Jira, talking to the tech lead,
> watching production). This annex removes the ambiguity: for every step, **who executes it**, and
> what the agent does when the owner is a human. Without this map the agent would either skip
> steps silently or claim them done — both violate the evidence rule.

## D.1 The one rule

**The agent never claims a human-owned step happened.** In every phase artifact, each human-owned
step is recorded with one of exactly three states:

- `DONE-BY-HUMAN: <who>, <when>` — the user told the agent it happened (cite the conversation).
- `HANDED-OFF: <what was delivered to the user>` — the agent prepared the material; execution
  pending on the human side.
- `N/A: <why it does not apply to this task>`.

An artifact that presents a human-owned step as simply "done" with no source is a falsified
artifact — same severity as writing a gate marker without doing the work.

## D.2 Jira access — wired via `tools/jira-sync/`

The vendored bridge (`tools/jira-sync/README.md` — adopted from ApiLLM PR #1 after security
review, fixes applied) covers Jira. The rules per direction:

1. **Input (READ — automated, no approval needed):** `new-task.sh` / `jira_sync.py ticket <KEY>`
   fetch the full ticket to disk (description, labels, **subtasks with descriptions — the
   authoritative matrix**, every comment) and `ready <KEY>` runs the intake gate. Ticket dumps
   land in `jira_tickets/` (gitignored — they routinely contain credentials pasted in comments).
   **Fallback** when the tool is not configured: the user provides the ticket content; the agent
   asks for what it cannot see.
2. **Output (WRITE — always behind the user):** evidence upload, comments, labels, status
   transitions and unassignment happen ONLY through `deliver` (Phase 10 §10.1b), covered by the
   same explicit approval that signs `PUSH-APPROVED`, and always `--dry-run` first with the plan
   shown to the user. Ad-hoc Jira writes outside `deliver` do not exist.
3. **Comment texts** are still drafted in the phase artifact under `## Ticket comment (pending
   publication)` with the `PUBLICATION:` line — `deliver --comment` (or the user posting by
   hand) flips it to `posted <date>`.
4. **Other state changes** ("mark it Blocked") remain explicit requests to the user.

## D.3 Persistence — progress is versioned and resumable

`work/` **is versioned and pushed** (same model as psyco-api's feature workspaces): closing any
phase ends with `tools/save-progress.sh <KEY> "<phase>"`, and the agent tells the user, every
time, **where the progress lives** — `work/<KEY>/` with `delivery-state.md` as the resumable
board — and how to resume: `/implement <KEY>` from any clone, any machine, any session.

What is NEVER versioned (`.gitignore`): human signatures (`PUSH-APPROVED`, `HUMAN-GATE-OK`,
`_PROCESS-CHANGE-OK` — a committed signature would open a gate on a clone whose user never
approved), the per-machine `_active` pointer, and ticket dumps / raw attachments (they routinely
carry client data and test-user credentials). The authored artifacts are safe to version
precisely because Phase 0 §0.0.3 forbids copying credentials into them — that rule is what the
versioning rests on; check it before every save.

- Never delete or prune `work/<KEY>/` while the ticket is open.
- Artifacts are written self-contained (full comment text inside, not references to chat).

## D.4 Ownership map (per phase)

| Phase | Agent executes | Human-owned (agent prepares + hands off) |
|---|---|---|
| 0 Intake | Read/classify what it was given; catalog lookups; draft the doubts | Providing full ticket content, history, epic; posting the comment |
| 1 Contrast | Sync the LLM repo; read code/tests; run locally **if feasible** (else state so — §1.2) | Credentials/sandboxes the agent lacks |
| 2 Impact | Static analysis, dependency-map, the matrix | The 10-minute cross-validation by another person (`DONE-BY-HUMAN` or `HANDED-OFF`) |
| 3 Feasibility | Coverage walk, gaps, feasibility conclusion | Reading sibling tickets the agent cannot see; PO/tech-lead agreement on scope |
| 4 Gate | Classify doubts, write questions with options + recommendation, the verdict | **Answering** the questions (PO/tech lead/QA/vendor owner) |
| 5 Plan | Options, trade-offs, the specific plans, guideline IDs | Design review with tech lead; QA sign-off on the test plan; `HUMAN-GATE-OK` (risky) |
| 6 Implement | Code, tests, checkpoints commits | Approving any deviation from the plan (§6.4.3) |
| 7 Test | Unit/integration suites, evidence, `TESTS: GREEN` | Manual exploratory on external systems; QA execution; PO functional acceptance |
| 8 Release | Draft runbook, release notes, config lists | Provisioning environments; creating dashboards/alerts; approvals; the window |
| 9 Pre-review | Full self-review, squash, REVIEW-CODE.md, the four marker lines | Nothing — this phase is fully the agent's |
| 10 PR | Draft PR title/description; after approval: push + PR + respond to review | **`PUSH-APPROVED`** (the user's explicit yes, §10.0); the review itself; merge decision |
| 11 Post-merge | Invoke the ApiLLM `doc-sync`; draft closure comment; debt tickets list | Production monitoring, smoke test, flag rollout, closing the ticket |

## D.5 Session model — ONE entry point, zero extra setup per task

**Every implementation session opens in THIS repo (the Coder) and starts with
`/implement <KEY>`.** That is the whole developer effort — the command scaffolds `work/<KEY>/`,
fetches the ticket, runs the gates and walks the phases; the hooks only enforce here, so a
session opened in the code repo or the ApiLLM is **unprotected** for implementation work and is
not a supported entry point (the ApiLLM is entered by the pipeline itself for sync/doc-sync;
the code repo is written *from here*, gated). `.claude/settings.json` pre-authorizes the two
sibling working directories so the pipeline crosses repos without permission friction.

## D.6 What this annex does NOT change

The gates stay exactly as enforced: human-owned steps being pending never justifies skipping a
gate, and the agent asking the user to sign a gate file (`HUMAN-GATE-OK`, `PUSH-APPROVED`,
`_PROCESS-CHANGE-OK`) is the mechanism working, not a blocker to route around.
