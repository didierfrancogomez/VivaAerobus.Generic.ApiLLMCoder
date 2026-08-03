# tools/jira-sync — the Jira bridge for the ticket lifecycle

Reads a ticket (description, comments, subtasks, attachments) into a flat text file the AI can load,
and writes the delivery back (evidence, comment, label, status).

Used by the Coder pipeline: Phase 0 (`ticket` + `ready` intake gate), Phase 10 (`deliver`, only after the user's `PUSH-APPROVED`/publication approval — always `--dry-run` first and show the user the plan).

---

## Setup — once per machine

```powershell
cd tools/jira-sync
.\setup.ps1                # checks EVERYTHING; installs what is safe to install
```

`setup.ps1` verifies python (3.10+), creates `.venv` and installs the python deps, scaffolds `.env`
from `.env.example`, checks node and **installs the global newman** when missing, and verifies
`gh` (+auth), `dotnet` and docker — printing the exact `winget`/`gh auth login` command for anything
it will not install for you. It ends by running `doctor`, so the last line is the same verdict the
`/implement` flow gates on. Idempotent; `-CheckOnly` audits without touching anything.

Manual equivalent (Linux/macOS, or by preference):

```bash
python -m venv .venv && .venv/bin/pip install -r requirements.txt
cp .env.example .env                               # then fill it in
npm install -g newman
```

`.env` needs `JIRA_BASE_URL`, `JIRA_EMAIL`, `JIRA_API_TOKEN`
([create a token](https://id.atlassian.com/manage-profile/security/api-tokens)); optionally
`JIRA_PROJECT_KEY`, `OUTPUT_DIR`, `GITHUB_REPO`, `TRACKING_LABEL`, `AUTO_TRANSITION_UAT`.

**`.env`, `.venv/` and `jira_tickets/` are gitignored — never commit any of them.** Ticket dumps
routinely contain test-user credentials pasted into comments.

PR-status lookups shell out to `gh`, so run `gh auth login` once.

## Adoption notes (Coder repo)

Vendored from ApiLLM PR #1 (@DLlano-VA) after a full security/code review (verdict:
ADOPT-WITH-FIXES). Fixes applied on adoption:

1. `TRACKING_LABEL` now defaults to **blank** — the plain `sync` verb is genuinely read-only
   unless a label is explicitly configured (it used to write a `Daniel` label to every ticket).
2. `deliver` **aborts** if the evidence subtask cannot be resolved or any upload fails — it no
   longer proceeds to comment/label/transition/unassign on partial evidence.
3. A failed status transition stops the unassign step (no unassigned-but-In-Progress tickets).
4. Dead worklog helpers removed (including the only DELETE call in the tool).
5. A subcommand missing its issue key, or an unknown subcommand, now errors out instead of
   silently falling through to a full sync.
6. Dry-run fetches the assignee field, so step 5's report is accurate.

Known limits (accepted, documented by the review): re-running `deliver` can duplicate
attachments/comments (label/transition/unassign/subtask ARE idempotent); the PR repo slug parsed
from Jira comments is only used for read-only `gh pr view`.

> **This folder is the canonical home of `jira_sync.py`.** If an older standalone checkout of the
> tool exists on your machine, replace its `jira_sync.py` with a shim that imports this one (and move
> your `.env` here) — two live copies drift.

---

## Commands

| Command | Effect |
|---|---|
| `.\setup.ps1 [-CheckOnly]` | **Install what's missing** (venv, python deps, newman) and verify the rest; chains into `doctor` |
| `python jira_sync.py doctor` | **Toolchain preflight**: .env keys, Jira auth, python deps in *this* interpreter, gh CLI + repo push access, node, global newman, dotnet, git, docker, `VIVA_CODE_REPO`. Exit code = hard failures |
| `python jira_sync.py ready API-9999` | **Intake gate**: blocks (exit 1) unless `TestCaseReady` is present **and** the evidence subtask holds a matrix; warns on odd status/assignee/`TestComplete`; detects research tickets |
| `python jira_sync.py` | Sync every ticket ever assigned to you, current month |
| `python jira_sync.py --from 2026-01-01 [--to …]` · `--all` | Same, other date ranges |
| `python jira_sync.py ticket API-9999` | Fetch **one** ticket regardless of assignee → `jira_tickets/Others/` |
| `python jira_sync.py deliver API-9999 …` | Write the delivery back — see below |
| `python jira_sync.py timesheet …` | Worklog Excel report |

### `deliver`

```bash
python jira_sync.py deliver API-9999 \
    --evidence path/to/evidence-dir \
    --pr 2395 \
    --comment "TC01 and TC02 executed in VB-TEST; evidence attached." \
    [--status "In review"] [--no-label] [--no-transition] [--keep-assignee] [--dry-run]
```

In order: **evidence** → the `Test Cases, execution and evidences` subtask (created if absent) ·
**comment** with the PR link · **add `TestComplete`** (keeping `TestCaseReady`) · **transition** the
parent · **unassign** so QA can grab it (`--keep-assignee` only for an agreed direct handback).

Ordered so a mid-way failure leaves the ticket truthful — evidence without the label is recoverable,
a completion label with no evidence is not. Every step is idempotent. **Always `--dry-run` first.**

---

## Reading a fetched ticket

The header answers most questions without opening the body:

```
Ticket       : API-9999
Status       : Feedback
Test Flow    : TEST CASES READY — execution + evidence still pending
Labels       : Daniel, TestCaseReady
PR           : #2395 (EzyWebwerkstaden/VivaAerobus.Generic.Api)
PR Status    : OPEN
```

`Test Flow` is derived from the labels, which are the real workflow signal — the Jira *status* says
nothing about whether test cases exist or were run.

Then `Subtasks (test cases / evidence)` carries each subtask's **full description**, including the
test-case matrix rendered as labelled rows. That matrix — not the ticket description — is
authoritative.

---

## Notes for maintainers

- **ADF rendering.** Jira Cloud v3 returns rich text as ADF. `adf_to_text` handles tables (wide ones
  become one labelled block per row, because a pipe join of a 9-column matrix is unreadable), media
  (`[image: name]` — dropping them loses screenshots the criteria refer to), mentions, lists,
  headings, panels and code blocks.
- **Comments are paginated.** The embedded `comment` field is capped; `fetch_all_comments` falls back
  to the dedicated endpoint when `total` exceeds what came inline.
- **Attachment upload** needs `X-Atlassian-Token: no-check` **and** no explicit `Content-Type` —
  `requests` must set the multipart boundary itself.
- **Transitions are status-dependent.** Jira only offers transitions valid from the *current* status,
  so a failure usually means the workflow forbids that jump, not that the name is wrong;
  `jira_list_transitions` prints what is actually available.
- **Labels use the `update` verb**, not a `fields` overwrite, so a concurrent edit is not clobbered.

### Known gap

`AdminPortalDatabaseSeeder`-style idempotency does not apply here, but one thing is worth knowing:
`process_issue` writes ticket files and may add `TRACKING_LABEL` to a ticket that has no labels, and
`AUTO_TRANSITION_UAT=true` will move merged-PR tickets to UAT. Both are off by default in
`.env.example`; enable them deliberately.
