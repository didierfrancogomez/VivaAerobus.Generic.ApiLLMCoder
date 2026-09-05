# Phase 03 — Coverage & feasibility: API-1738 Display Passengers Changes

## Work

### 3.1 Ticket coverage (requirement → implementation → matrix row)
| Requirement | Implemented (-v3, Phase 1 D-xx) | Matrix rows |
|---|---|---|
| Part 1 masked-field replacement (contacts email/phones, passenger email/phone, Customer creator username) | D-01, D-02 | 1, 2, 3 |
| Flow gating: GET /Booking only in Manage/Check-in; Full/Search always | D-08 (pre-existing) | 4 |
| Part 2 `TreatContactEmailMatchAsSameAccount` OR-bypass, default false | D-03 | 5, 6 |
| Part 3 pending-verification exception, ends after verification | D-04 | 7, 8 |
| Part 4 account endpoints always mask (Account, Trips, Trips/Add; upcomingTrip + basket.travelSummary) | D-05 | 9, 10, 11, 12 |
| Masking formats (email reuse, phone last-4, username Customer-only) | D-06, D-07, D-01 | 2 (formats visible), 9 |
| Release note + Admin-Portal manual change | PR body (PRC-36/PRC-96) | — |

Gaps in the **ticket**: none open — the six review questions were answered by VB (2026-09-02) and the description already carries the answers (Part 4 text, "Affected endpoints" note). Gaps in the **evidence** (not in the code): rows 1–3 evidence predates the code (2026-09-01); rows 10–12 have no `Execution Result`; rows 4–9 evidence produced on the user's other desktop (build unverifiable from here) → handled in Phase 5 (S-01…S-12 re-run; new screenshots for 1–3 and 10–12).

### 3.2 Sibling tickets
- None required. Related merged work already on master: API-1574 (child customer number), API-1670 (`GetActualPassengers`), API-1847/1849 (name matching). No duplicate/overlapping open ticket found in the fetched context (Jira search not performed — the ticket, its subtask and the PR are the sources here).
- Candidate follow-up (not created — needs VB agreement per PRC-94): unit specs for `ToMaskedPhone` / `ToMaskedEmail` edge cases (≤4 digits, empty, null).

### 3.3 Dependencies and sequencing
| Dependency | State | Owner |
|---|---|---|
| master integration (20 commits, 1 whitespace-only conflict) | resolved on -v3 (rebased, 0 behind) | this run (P-04b) |
| Admin-Portal document update after release (new toggle key) | flagged in PR checklist + release notes | ops / VB |
| QA seed PNRs (`W8TMQI`, `XEFKMG`, `MC4MXM`, `AC34QJ`, `SJ3ETH`, `YG4MJQ`) and accounts (Customer QA user, Staff) | in the attached collection; state re-verified on the first newman run | QA (hectorcervantes) if regeneration needed |
| Local runtime: docker stack up; API instance PID 7148 (stale build) | user authorized stop/restart (Q2) | this run (P-08) |
| DotRez QA reachability | unverified by curl (000) — verified by the API login in P-08, ≤2 attempts | — |
| Reviewer re-review | after push + replies + re-request | nowakmarcin |

### 3.4 Feasibility
**Feasible as specified.** Every part has code on -v3 that matches the ticket text and VB's answers; no source of truth outside the repo is needed; no stub is involved; nothing contradicts an existing rule or contract (the flow gating is pre-existing behavior). Constraints honored: no history rewrite beyond the user's explicit instruction (Q1), no force-push without `--force-with-lease` and a re-verified unreviewed head, one PR = one ticket (PRC-32).

### 3.5 Scope and estimate
- Scope unchanged (VB #1). Anti-scope recorded in Phase 5.
- Remaining effort: ~0.5d integration + Phase 9, ~0.5d evidence (6 rows of screenshots by the user, newman for all 12), PR replies and Jira delivery.

## Ticket comment (pending publication)
Folded into the delivery comment (P-14).

PUBLICATION: pending

## Handoff
- `phase_status`: pass
- `highest_severity`: none
- `next_phase`: phase 04
- `blocking_reason`: n/a
- `required_inputs_for_next_phase`: Phase 1 D-09/D-10/D-11, Phase 2 R-05/R-10/R-13, user decisions Q1–Q7 (2026-09-05)
- `evidence_paths`: `work/API-1738/phase-01-contrast.md`, `work/API-1738/phase-02-impact-matrix.md`, `work/API-1738/continue-plan-2026-09-04.md` §7
- `delivery_state_updated`: yes
