# Delivery state: API-1738 — Display Passengers Changes

<!-- Live board of the task. Updated at the close of every phase (the handoff footer's
     delivery_state_updated field refers to THIS file). This is what gets pasted to Jira
     as the progress comment. -->

- `key`: API-1738
- `branch`: feature/API-1738/display-passengers-changes (PR #2484, EzyWebwerkstaden/VivaAerobus.Generic.Api)
- `rigor`: risky
- `current_phase`: 10 (in review) → 11 after merge
- `current_run`: run-001 (phase-07/09 at the task root; adoption via /continue on 2026-09-05)
- `overall_status`: delivered (PR #2484 re-requested, Jira In review / unassigned)

## /continue approval record
- Plan `continue-plan-2026-09-04.md` **approved with changes by Daniel Llano on 2026-09-05 00:01 -0400** (decisions Q1–Q7 recorded in the plan §7).
- Recovery point: `continue-recovery.md` (local HEAD 5aab3a22e, PR head 5f26398c0, no stash created).

## Phase matrix

| Phase | Artifact | phase_status | highest_severity | blocking_reason |
|---|---|---|---|---|
| 0 Intake | `phase-00-intake.md` | pass (backfilled 2026-09-05) | none | — |
| 1 Contrast | `phase-01-contrast.md` | pass (backfilled 2026-09-05) | P3 | — |
| 2 Impact | `phase-02-impact-matrix.md` | pass (backfilled 2026-09-05) | P2 | — |
| 3 Feasibility | `phase-03-feasibility.md` | pass (backfilled 2026-09-05) | none | — |
| 4 GATE | `phase-04-verdict.md` | pass — VERDICT ✅ (2026-09-05) | none | — |
| 5 Plan | `phase-05-plan.md` | pass — awaiting HUMAN-GATE-OK (risky) | none | human gate |
| 6 Implement | branch/commits | pass — local 1e65eb8a3 (= -v3 tree; user's squash ea9817aa4 + amend for the 2-line delta), not pushed yet | none | — |
| 7 Test | `phase-07-testing.md` | pass — TESTS: GREEN (567/567), 11 folders × 2 builds; F-01 Staff QA account rejected by DotRez (external) | P2 | — |
| 8 Release prep | runbook | pass — release notes + Admin-Portal flag in PR body; rollback = revert; toggle default off (plan §Specific plans) | none | — |
| 9 Pre-review | `phase-09-pre-review.md` | pass — REVIEW-CODE APPROVED, VALIDATED-SHA 1e65eb8a3, COMPLETENESS VERIFIED, DEVIATIONS APPROVED-AND-DOCUMENTED | P2 | awaiting PUSH-APPROVED |
| 10 PR | PR #2484 | **published 2026-09-05 ~01:50 -0400** (PUSH-APPROVED by the user): force-with-lease ea9817aa4 → **1e65eb8a3**; PR body replaced (`pr-description-draft.md`); one status comment for Marcin (issuecomment-5549764368) instead of 20 replies (user's 👍 on each thread); review re-requested from nowakmarcin; `-v2` deleted, Luis's `-v3` kept. Jira delivered: fixed collection re-attached to API-1870 (old one deleted), comment with PR link, `TestComplete` added, → In review, unassigned. Sonar S107 on `BookingOutputBuilder` ctor (26 params, inherited) flagged in the PR comment for the reviewer's call | P2 (Sonar S107 — Build ✅, Sonar ❌ on 1e65eb8a3, inherited ctor size; F-01 withdrawn: Staff login failure was local to this workstation) | reviewer / Sonar decision on S107 |
| 11 Post-merge | doc-sync evidence | pending | | |

## Scenario coverage (from phase-05-plan.md, numbered)

| # | Scenario | Evidence | Result |
|---|---|---|---|
| S-01…S-12 | matrix rows 1–12 | newman Solution (:9050) + Issue (:9051), `attachments/evidence-runs/`; rows 4–9 screenshots from 2026-09-04; rows 1–3, 10–12 screenshots pending (user, `evidence/screenshot-checklist.md`) | PASS (S-03 with external Staff-login gap F-01) |
| S-13 | full NUnit suite | `attachments/dotnet-test-1e65eb8a3.txt` | PASS 567/567 |
| S-14 | tree == -v3, build | git diff empty, 0 errors | PASS |
| S-15 | app start + DotRez login | :9050 up, Customer login 200 | PASS |

## Active blockers / questions

| Severity | What | Owner | Since |
|---|---|---|---|
| — | none open (VB answered 1–6 on 2026-09-02; user decided Q1–Q7 on 2026-09-05) | | |

## Incident — test credentials committed (2026-09-05 → handled 2026-09-07)
- `work/API-1738/evidence/upload/…postman_collection.json` (QA customer, Staff `55162517` and local `ezyadmin` passwords as collection variables) was committed in `1fd03ba`, merged upstream via PR #1 (`1e1770a`) and pushed to the fork `DLlano-VA/VivaAerobus.Generic.ApiLLMCoder`.
- Tree fix pushed (`6d3656f`): file untracked, `.gitignore` covers `work/*/{ticket-snapshots,config-backups,evidence/upload,evidence/screenshots}/`.
- User decision 2026-09-07: **option 1 — rotate the credentials, keep history; delete the fork.** Fork deletion needs the `delete_repo` scope on the `DLlano-VA` token (human step); rotation of the three test credentials is a human/QA step. Both pending the user.

## Human gates

- `HUMAN-GATE-REQUIRED`: yes · `HUMAN-GATE-OK`: **present** — created by Daniel Llano on 2026-09-05 (gate reported open at the "proceed" prompt)
- `PUSH-APPROVED`: pending
