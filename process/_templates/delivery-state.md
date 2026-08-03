# Delivery state: <KEY> — <ticket title>

<!-- Live board of the task. Updated at the close of every phase (the handoff footer's
     delivery_state_updated field refers to THIS file). This is what gets pasted to Jira
     as the progress comment. -->

- `key`: <KEY>
- `branch`: <type/KEY-123-slug | none yet>
- `rigor`: <trivial | normal | risky>
- `current_phase`: <NN>
- `current_run`: <validation/run-NNN | none>
- `overall_status`: <analysis | blocked | implementing | validating | awaiting-user-approval | delivered | closed>

## Phase matrix

| Phase | Artifact | phase_status | highest_severity | blocking_reason |
|---|---|---|---|---|
| 0 Intake | `phase-00-intake.md` | | | |
| 1 Contrast | `phase-01-contrast.md` | | | |
| 2 Impact | `phase-02-impact-matrix.md` | | | |
| 3 Feasibility | `phase-03-feasibility.md` | | | |
| 4 GATE | `phase-04-verdict.md` | | | |
| 5 Plan | `phase-05-plan.md` | | | |
| 6 Implement | branch/commits | | | |
| 7 Test | `phase-07-testing.md` | | | |
| 8 Release prep | runbook | | | |
| 9 Pre-review | `phase-09-pre-review.md` | | | |
| 10 PR | PR link | | | |
| 11 Post-merge | doc-sync evidence | | | |

## Scenario coverage (from phase-05-plan.md, numbered)

| # | Scenario | Evidence | Result |
|---|---|---|---|
| S-01 | | | |

## Active blockers / questions

| Severity | What | Owner | Since |
|---|---|---|---|

## Human gates

- `HUMAN-GATE-REQUIRED`: <yes/no> · `HUMAN-GATE-OK`: <present/pending/n-a>
- `PUSH-APPROVED`: <present/pending>
