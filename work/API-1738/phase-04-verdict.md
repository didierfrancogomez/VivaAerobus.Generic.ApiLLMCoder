# Phase 04 — Blockers & assumptions (GATE): API-1738 Display Passengers Changes

## Work

### 4.0 Verdict

VERDICT: ✅

Ready to implement (here: ready to integrate the final code, validate and deliver). Objective, contracts, acceptance criteria (12-row matrix) and impact radius (Phase 2, 17 rows) are clear; zero open hard blockers. Every business question raised during review was answered by VB on 2026-09-02 (answers 1–6, ticket comments), and the execution decisions were taken by the user on 2026-09-05 (continue-plan §7, Q1–Q7).

### 4.1 Classification of the doubts
| Doubt | Type | Handling |
|---|---|---|
| Which code is final (PR head vs -v2 vs -v3) | team technical decision | **decided by the user 2026-09-05 (Q1)**: -v3 content, Luis's commits squashed into the last commit |
| Toggle name (`TreatContactEmailMatchAsSameAccount` vs `EnabledForTheSameEmail`) — T02 | business decision | **answered** VB #2: keep the name |
| Flow scope of the rule — T05 | business decision | **answered** VB #3: Manage + Check-in (pre-existing gating, Phase 1 D-08) |
| upcomingTrip vs basket.travelSummary — T06 | business decision | **answered** VB #4: both |
| Rule criteria on account endpoints — T07 | business decision | **answered** VB #5: always mask, no rule evaluation |
| Trips retrieval performance — T08 | business decision | **answered** VB #6: keep scope of #5 (no fan-out) |
| Trips/Add masking — T18 | domain ambiguity | **resolved by the ticket text**: Part 4 lists `POST /v1/Account/Trips/Add` and states masking on the three endpoints is unconditional (+ VB #5) |
| Default parameter on `CreateFromBookingComment` — T12 spirit | team technical decision | low-risk assumption A4: keep (load-bearing for two notification callers, Phase 2 R-05); explained in the PR reply |
| Build behind the 2026-09-04 evidence (rows 4–9) | documentation/verification gap | **our** verification, not a business question: all 12 rows re-run with newman on the final commit (S-01…S-12) |
| Phone with ≤4 digits unchanged by `ToMaskedPhone` | irrelevant detail / low-risk assumption A8 | documented; validate in review |
| Seed PNR states still valid | verification task | first newman run; regenerate or ask QA if not |
| Coder remote push denied (403 for `DLlano-VA`) | environment | not a task blocker — progress commits are local; user grants access or pushes |

### 4.2 Blocking questions
None. (No `[BLOCKER]` block issued.)

### 4.4 Assumption log
| # | Assumption | Why I assume it | Risk if false | How it is validated | Status |
|---|---|---|---|---|---|
| A1 | The `-v3` tree is the intended final code | user Q1 (2026-09-05); -v3 = PR history rebased + exactly the reviewer's asks (Phase 1 D-01…D-07) | wrong code shipped | `git diff origin/…-v3` empty after P-04b; REVIEW-CODE in Phase 9 | open → P-04b |
| A2 | Rows 4–9 evidence (2026-09-04 18:40) was produced on -v3 content on the user's other desktop | user Q4 | stale evidence attached | newman re-run of all 12 rows on the final commit (S-01…S-12); screenshots re-done for 1–3, 10–12 | open → P-09 |
| A3 | Trips/Add always-mask is what VB wants | ticket Part 4 text + VB #5 | reviewer asks again | cited in the T18 reply; QA runs row 9 | closed (ticket text) |
| A4 | Keeping `CreateFromBookingComment(…, bool = false)` is acceptable | two notification callers depend on it; removing = 2 extra files (PRC-97) | reviewer requests removal | PR reply to T12; reviewer decides | open → P-13 |
| A5 | Master's `BasketTravelChargesOutputBuilder.cs` is the right side of the only conflict | our change there was whitespace-only (Phase 1) | lost change | -v3 already dropped it; empty diff check | closed |
| A6 | Existing Admin `BookingRules` documents deserialize the missing key as `false` | C# bool default; seeder skips existing docs (ApiLLM sync-state 2026-09-04) | toggle unexpectedly on | row 5/6 toggle on/off via `ConfigPartSaveValues`; Phase 8 note | open → S-05/S-06 |
| A7 | Consumers tolerate masked strings in previously-clear fields and a masked (not null) trips email | PR body states it; VB approved scope | client display issues | PR "breaking changes" paragraph for the reviewer/consumers | accepted risk |
| A8 | A phone with ≤4 digits is returned unchanged | `ToMaskedPhone` :128-130 | trivial exposure of a malformed number | reviewer judgment; unit test only with VB agreement (PRC-94) | accepted |
| A9 | Local CI did not run on 5f26398c0 for reasons outside this change | 0 check runs vs Build+Sonar on 5aab3a22e | red pipeline after push | confirm the workflow runs on the new head (P-13); SonarQube QG (PRC-38) | open → P-13 |

### 4.5 Parallel work
Nothing is blocked; execution continues with Phase 5.

## Ticket comment (pending publication)
Folded into the delivery comment (P-14): "Analysis gate ✅ 2026-09-05 — no open questions; assumptions A1–A9 tracked in the workspace."

PUBLICATION: pending

## Handoff
- `phase_status`: pass
- `highest_severity`: none
- `next_phase`: phase 05
- `blocking_reason`: n/a
- `required_inputs_for_next_phase`: guidelines index (ApiLLM origin/main `guidelines/*.md`), `process/change-playbook.md`, matrix rows ↔ collection folders mapping
- `evidence_paths`: `work/API-1738/phase-01-contrast.md`, `phase-02-impact-matrix.md`, `phase-03-feasibility.md`, `continue-plan-2026-09-04.md` §7
- `delivery_state_updated`: yes
