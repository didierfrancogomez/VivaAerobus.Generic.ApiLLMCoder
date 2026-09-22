# /continue plan — API-1834 (2026-09-22)

Status: **AWAITING USER APPROVAL** — nothing below has been executed. Mode: **adoption** (no
`work/API-1834/` existed; the only Stage A write is `ticket-snapshots/2026-09-22-1626.txt`, gitignored).

## 1. Status summary (Stage A, read-only)

| Area | Finding | Evidence |
|---|---|---|
| Preflight | `jira_sync.py doctor`: 0 hard failures; WARN docker daemon not running | doctor output 2026-09-22 (run by caller) |
| Ticket | **Done**, Test Flow TEST COMPLETE, labels `Daniel, TestCaseReady, TestComplete`, assignee Arturo Cesar Garza Alvarez, devoluciones **2**, time 68h (daniel.llano 57h, Piotr 11h). Ticket `PR` field lists only #2491 | `ticket-snapshots/2026-09-22-1626.txt` |
| Evidence subtask API-1879 | Status **Backlog** (parent is Done). Rows 1–5 all `PASS` with evidence; attachments dated 09-07, 09-11 (TC01–03) and **09-17 08:27** (TC04/05) + 2 Postman collections (09-07, 09-17) | `jira_sync.py ticket API-1879` (dump in `jira_tickets/Others/API-1879.txt`) |
| Spec deltas | No earlier snapshot ⇒ no snapshot diff possible. Matrix = 5 rows (rows 4–5 = the journey-level `loyalty: null` rule). Comment trail: 08-17/08-21 remainingBalance removal agreed (row 3 added); **09-15 QA rejection** (Regular fare + Regular bundles: journey `loyalty` must not be affected) → fixed by PR #2505 (09-17); **09-18 QA retest ✅** for Regular/Regular and Mixed/Regular; Piotr "Approved, please merge" 09-18. No comment after 09-18 | snapshot, Comments section |
| PR #2491 | **MERGED** 2026-09-14T15:05:58Z, merge `9f4f9f43f`, 3 files (`BasketModels.cs`, `BasketTravelOutputBuilder.cs`, `PointsMinimumProvider.cs`), +67/−20. Piotr CHANGES_REQUESTED 09-11 → APPROVED 09-14; both threads (Misconfigured charges, `includePointsServices` flag → overloads) answered with code changes. CI Build + Sonar SUCCESS (0 new issues) | `gh pr view 2491`, `…/pulls/2491/{reviews,comments}` |
| PR #2505 | **MERGED** 2026-09-18T14:12:12Z, merge `1b7f4ec89`, 2 files, +42/−15. Piotr CHANGES_REQUESTED 09-18 (🐛 missing `fare.IsGoverning`) → fixed in `1151f6bfb` (extract `IsGoverningPointsFare`) → APPROVED 09-18. CI Build + Sonar SUCCESS | `gh pr view 2505`, reviews/comments |
| Other PRs on the key | None (`gh pr list --search API-1834 --state all` → only #2491, #2505) | gh output |
| Master | Both merge commits are ancestors of `origin/master` (`9c2ccad2`). All 7 API-1834 commits on master: `c9cc87ff4, 706eca767, 57a416c73, 7b25f9704, 4ca17e15c, b52cf4657, 1151f6bfb`; no later commit touches the 3 files | `git merge-base --is-ancestor`, `git log 9f4f9f43^1..origin/master -- <3 files>` |
| Remote branches | `origin/feature/API-1834/Loyalty-excluded-amount-is-being-affected-incorrectly` **still exists** at `58299661` with 3 commits NOT in master (`8ed51a76e, e4d4603f0, 58299661`, pre-rewrite copies of the merged work). #2505's branch is deleted | `git log origin/master..origin/feature/API-1834/…` |
| Docs (ApiLLM, published `origin/main` `5d3d1c3a`) | Anchor `last_documented_commit: 9c2ccad2` == `origin/master` ⇒ **FRESH**. #2491 documented in sync row 2026-09-14 (`9f4f9f43`); #2505 in sync row 2026-09-22 ("per-journey `Loyalty` returns null…"); `concepts/Basket.md` §2 documents the contract change and `IsGoverningPointsFare`. ⇒ Phase 11 doc-sync **already done** | `git show origin/main:documents/_meta/sync-state.md`, `…:documents/concepts/Basket.md :592-611, :738` |
| Docs-sync hook "288 STALE" | Measured from the ApiLLM working tree on `feat/sync-check-hardening-and-testing-scripts`, not published main. Not real staleness; the Stop gate may still refuse | `git -C ApiLLM branch --show-current` |
| Code repo working tree | On `feature/API-771/Admin-Panel-Roles-And-Security-with-Microsoft-SSO` (ahead 53 / behind 181), HEAD `c8b7680e`, `global.json` modified, 34 porcelain entries, 3 pre-existing stashes. **Not API-1834's; will not be touched** | `git status --porcelain --branch`, `git stash list` |
| Test coverage | **Neither PR adds or changes a test file**. `concepts/Basket.md :738`: "No spec covers `HasPointsPricedFareOrBundle` / the null per-journey `Loyalty`". The matrix header requires `[AUTOMATED]` cases "implemented as integration tests in the PR and added to the Postman collection"; row 1 is `[AUTOMATED]`, `Postman update? No`. A Postman collection is attached to API-1879 (not committed to `docs/Postman/`) | PR file lists; ApiLLM Basket.md; ticket matrix |

### Evidence coverage (row → evidence post-dating the last code change `1151f6bfb`, 2026-09-18)

| Row | Dev evidence (API-1879) | QA evidence | Verdict |
|---|---|---|---|
| 1 SSR Points excluded from journey minimum | 09-07 / 09-11 (pre-#2505) | QA 09-15 "Correct test cases" ✔ (pre-#2505) | Behaviour not touched by #2505 except `IsGoverning` on L1 fares; **no automated test** → gap G-1 |
| 2 SSR Regular excluded from journey excludedAmount | 09-07 / 09-11 | QA 09-15 ✔ | same as row 1 (no post-#2505 evidence; low risk) |
| 3 remainingBalance only in loyaltySummary | 09-07 / 09-11 | QA 09-15 ✔ | covered (code unchanged by #2505 in `BasketModels.cs`) |
| 4 Regular fare + Regular bundles → journey `loyalty: null` | 09-17 08:27 — **predates `1151f6bfb`** | QA 09-18 ✅ (Regular/Regular) | covered by QA retest; build under test `unknown` → gap G-2 |
| 5 Mixed roundtrip | 09-17 08:27 — predates `1151f6bfb` | QA 09-18 ✅ (Mixed/Regular) | same as row 4 |

## 2. Classified deltas

| # | Delta | Class |
|---|---|---|
| D-1 | QA rejection 09-15 → PR #2505 → QA ✅ 09-18 → merged | none — closed rework loop (informational) |
| D-2 | Contract change `GET /Basket`: `travel.journeys[].loyalty` now `null` without points-priced fare/bundle; `remainingBalance` removed from journey loyalty | none — it IS rows 3–5 of the spec; recorded for Phase 11 |
| D-3 | Row 1 `[AUTOMATED]` has no automated test in the repo (G-1) | **question** Q1 |
| D-4 | TC04/05 dev evidence predates last commit; QA retest build unknown (G-2) | **question** Q2 (non-blocking) |
| D-5 | Evidence subtask API-1879 still in Backlog while parent Done | **question** Q3 (Jira write) |
| D-6 | Stale remote branch of #2491 with 3 unmerged pre-rewrite commits | **question** Q4 (remote delete = user's) |
| D-7 | No `work/API-1834/` pipeline record (adoption) | bounded pipeline backfill (no code) |
| D-8 | 2nd devolución: cause `unknown` (only the 09-15 one is explained in comments) | informational; recorded as `unknown` |

No scope/design change pending. No code change planned unless Q1 = (b).

## 3. Open gaps and questions

- **Q1 — Row 1 `[AUTOMATED]` without a test (G-1).** Options: (a) accept as-is — QA/Piotr approved and
  merged without it; record the gap in Phase 11. (b) open a **new** ticket for specs covering
  `GetMinimumForPoints(…, journeyKey)` + `HasPointsPricedFareOrBundle` (+ committing the Postman
  collection), run through `/implement` on that key. (c) reopen API-1834. **Recommendation: (b)** —
  the matrix contract is unmet and the docs flag zero coverage, but the ticket is Done; a new ticket
  keeps this one closed (Phase 6.4). Needs your ok to create it (Jira write).
- **Q2 — TC04/05 evidence vs `1151f6bfb` (G-2).** Recommendation: accept QA's 09-18 retest as
  the post-fix evidence; record "build under test: unknown". No re-run (docker down, change is a
  stricter predicate only).
- **Q3 — API-1879 in Backlog.** Options: (a) you/QA transition it; (b) I transition it via jira-sync
  with your explicit yes. Recommendation: (a) — the subtask belongs to QA's flow.
- **Q4 — Stale branch `origin/feature/API-1834/Loyalty-excluded-amount-is-being-affected-incorrectly`.**
  Recommendation: you delete it on GitHub (its 3 commits are superseded copies; the merged content is
  `c9cc87ff4…4ca17e15c`). I will not delete remote refs.
- **Q5 — Production:** deployed/verified in prod? `unknown`. Recommendation: record `unknown`
  until you confirm.
- **Q6 — Stop gate:** ApiLLM checkout on your feature branch makes the docs gate report STALE.
  Options: (a) switch that checkout to `main` when convenient; (b) accept refusals /
  `VIVA_SYNC_GATE_OFF=1` for the session. I will not touch that tree.

None of Q1–Q6 blocks the pipeline-record steps below; Q1 (b) only adds a follow-up ticket.

## 4. Steps (this repo only; no code repo, no Jira, no PR writes)

| # | Step | Touches |
|---|---|---|
| P-01 | Scaffold `work/API-1834/delivery-state.md` from `process/_templates/delivery-state.md` (manually, **not** `tools/new-task.sh`, which would repoint `work/_active` away from API-1738 and re-fetch) | `work/API-1834/delivery-state.md` |
| P-02 | Backfill phases 0–5 as a **retrospective adoption record** from `_templates/phase-artifact.md`, level **Normal** (API contract change, no data impact): 00 intake (matrix rows 1–5, comments); 01 contrast with `DOCS-ANCHOR: 9c2ccad2 FRESH` (published anchor); 02 impact (`BasketTravelOutputBuilder`, `PointsMinimumProvider` + its callers per ApiLLM dependency-map); 03 feasibility; 04 verdict (retrospective, states it was reconstructed after merge); 05 plan mapping P-NN ↔ the 7 commits, `## Deviations (approved)` = review-driven changes (journeyKey last param; IsGoverning). Every claim cited | `work/API-1834/phase-00…05-*.md` |
| P-03 | Phase 7/9 **records without gate markers** (no `TESTS: GREEN` / `REVIEW-CODE: APPROVED` — no suite run by this pipeline; writing them would falsify the gate): CI Build + Sonar SUCCESS, reviewer approvals, evidence table §1, gaps G-1/G-2 | `work/API-1834/phase-07-testing.md`, `phase-09-pre-review.md` |
| P-04 | `phase-11-post-merge.md`: merges `9f4f9f43f` / `1b7f4ec89`; docs re-synced (ApiLLM rows 2026-09-14, 2026-09-22; Basket.md §2); QA env verification 09-18; prod per Q5; test gap per Q1; subtask per Q3; branch per Q4; retro note: 2nd devolución avoidable (Regular/Regular case was in the matrix rows 4–5 but not covered before first merge) + no spec added in either PR; handoff footer | `work/API-1834/phase-11-post-merge.md` |
| P-05 | Update `delivery-state.md`: phases table, `current_phase: 11`, this plan's approval record, Q answers | `work/API-1834/delivery-state.md` |
| P-06 | `tools/save-progress.sh API-1834 "continue"` (commit + push `work/API-1834/`, regenerate `work/README.md`) | this repo, `origin/main` |

Conditional (only with your explicit yes): P-07 create the follow-up test ticket (Q1 b) via
jira-sync — dry-run shown first. P-08 transition API-1879 (Q3 b).

## 5. Git preservation plan

- Code repo: **not touched** (no checkout, fetch, stash). Recovery point irrelevant; recorded state:
  branch `feature/API-771/…`, HEAD `c8b7680e`, 3 stashes, 34 porcelain entries.
- This repo: `main` @ `8ab35c0`; pre-existing untracked `work/API-1738/continue-plan-2026-09-22.md`
  is not staged by P-06: `tools/save-progress.sh :21` stages only `work/$KEY` + `work/README.md`.

## 6. Risks / rollback

- P-01..P-05: text only; rollback = delete files / `git revert` of the progress commit.
- P-06: pushes to this repo's `origin/main`; rollback = revert commit.
- P-07/P-08: Jira writes, only after dry-run + your yes; rollback = delete ticket / re-transition.
