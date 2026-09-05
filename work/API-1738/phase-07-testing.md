# Phase 7 Testing: API-1738 — run-001 (2026-09-05, code 1e65eb8a3)

Code under test: `feature/API-1738/display-passengers-changes` @ **1e65eb8a3** (local; = `origin/…-v3` tree; 1 commit on `origin/master` e004bf9d8). Base for Issue captures: `origin/master` e004bf9d8 (detached worktree `C:\VivaAerobus.Generic.Api-master`).

## Execution

| Command / check | Result | Evidence |
|---|---|---|
| `dotnet build VivaAerobus.Generic.Api.sln -c Debug` (SDK 3.1.426) | 0 errors, 16 warnings — all pre-existing, none in the 14 changed files | build output 01:19 -0400 |
| `dotnet test src/tests/VivaAerobus.Generic.Api.Tests --no-build -c Debug` | **Test Run Successful — total 658, executed/passed 567, failed 0, 91 not executed (Ignored/Explicit per trx `outcome="NotExecuted"`)** | `work/API-1738/attachments/dotnet-test-1e65eb8a3.txt`; `src/tests/…/TestResults/API-1738-run1.trx` |
| Branch API on :9050 (PID 3132), master API on :9051 (PID 25700), both env Development | both answer 200 on `/`; Customer QA login reaches DotRez QA (TC01 `06 Login` 200) | `attachments/api-9050-1e65eb8a3.log`, `api-9051-master.log` |
| Admin config backup before any `set` | `BookingRules` (60 554 B) + `BookingVerify` (399 B) saved from both APIs; every folder restores what it changed (steps 12–15 green in each run) | `work/API-1738/config-backups/20260905-0124*-port905{0,1}-*.json` |
| newman (6.2.2 + htmlextra) — collection attached to API-1870 (2026-09-04 19:35), 11 folders, run **twice**: Solution = :9050, Issue = :9051 | table below | `attachments/evidence-runs/<stamp>-TC<nn>-<side>/{cli.txt,run.json,report.html,report.png}`, `evidence-runs/summary.txt` |

### newman results (assertions executed / failed)

| Folder | Solution (branch) | Issue (master) | Reading |
|---|---|---|---|
| TC01 rule passes | 46 / 0 | 46 / 0 | regression guard — identical on both |
| TC02 rule fails, Customer creator | 49 / 0 | 49 / 0 | the collection validates "either supported contract"; on master it detects the legacy full mask, on the branch the contact-only mask — both recorded in the reports |
| TC03 rule fails, Staff creator | 47 / **1** | 47 / **1** | the single failure on both sides is `06 Login as Staff…` → `ACCOUNT_CREDENTIALS_INVALID` (DotRez QA: `nsk-server:AgentAuthentication: The agent (WWW/55162517) failed authentication`); credentials identical to those QA posted 2026-08-27. **External dependency, 2 attempts → reported, not retried.** All content assertions pass (creator username plain, contact data masked) |
| TC04 Booking-flow basket | 47 / 0 | 47 / 0 | pre-existing gating — identical |
| TC05 contact-email match | 49 / 0 | 49 / 0 | contract-agnostic assertions |
| TC06 contact-email mismatch | 49 / 0 | 49 / 0 | idem |
| TC07 pending verification | 33 / 0 | 33 / 0 | idem |
| TC08 verification completed | 49 / 0 | 49 / 0 | idem |
| TC09 Trips/Add + account views (rows 9, 10) | 12 / **1** with the attached collection → **13 / 0 after fixing the stale assertion** (step 02 asserted "returned unmasked (out of scope)"; ticket Part 4 / row 9 / VB #5 say masked) | 12 / 3 (attached) · **13 / 4 (fixed)** — master returns the email in clear | **Issue ≠ Solution: the change is the cause** |
| TC10 basket.travelSummary (row 11) | 11 / 0 | 11 / **2** | master leaves the email plain → Issue ≠ Solution |
| TC11 owned trip, rule passes (row 12) | 10 / 0 | 10 / **3** | master leaves the email plain → Issue ≠ Solution |

Collection fix (the only edit): `TC09 / 02 Link booking through Account Trips Add` test renamed to "Account Trips Add response returns the trip contact email masked (API-1738 Part 4, matrix row 9)" and asserts a masked address. Original kept as `attachments/…postman_collection.jira-2026-09-04.orig.json`; the fixed file is the one to re-attach to API-1870 (Q6: a change was needed).

## Scenario coverage (against phase-05-plan.md, numbered)

| # | Scenario | Test executed | Result | Notes |
|---|---|---|---|---|
| S-01 | Row 1 — rule passes, all plain | TC01 Solution + Issue | PASS | screenshots pending (user, checklist) |
| S-02 | Row 2 — Customer creator, contact-only masking | TC02 Solution (+ Issue shows legacy mask) | PASS | screenshots pending |
| S-03 | Row 3 — Staff creator, username plain | TC03 Solution: content assertions PASS; Staff **login** rejected by DotRez QA | PASS with external gap | see finding F-01; screenshots pending |
| S-04 | Row 4 — Booking-flow basket unmasked | TC04 | PASS | 2026-09-04 evidence kept |
| S-05 | Row 5 — toggle on, email match → unmasked | TC05 | PASS | kept |
| S-06 | Row 6 — toggle on, mismatch → masked | TC06 | PASS | kept |
| S-07 | Row 7 — pending verification → unmasked | TC07 | PASS | kept |
| S-08 | Row 8 — verified → masked again | TC08 | PASS | kept |
| S-09 | Row 9 — Trips/Add response email masked | TC09 step 02 (fixed) Solution PASS, Issue FAIL (plain) | PASS | kept (2026-09-04 pair) |
| S-10 | Row 10 — linked trip masked on GET /Account + /Trips | TC09 steps 03–04 Solution PASS, Issue FAIL | PASS | screenshots pending |
| S-11 | Row 11 — basket.travelSummary masked | TC10 Solution PASS, Issue FAIL | PASS | screenshots pending |
| S-12 | Row 12 — owned trip, rule passes, still masked | TC11 Solution PASS, Issue FAIL | PASS | screenshots pending |
| S-13 | Full NUnit suite green | `dotnet test` | PASS (567/567 executed) | |
| S-14 | Tree == `origin/…-v3`, builds | `git diff origin/…-v3 HEAD` empty; build 0 errors | PASS | |
| S-15 | App starts with the new registration; DotRez QA reachable | :9050 up in 4 s; Customer login 200 | PASS | Staff account rejected (F-01) |

## Findings

| Severity | Rule (STY/ARC/ROB/PRC or process) | Where | Issue | Fix |
|---|---|---|---|---|
| P2 (process/external) | PRC-33 (real data) | TC03 step 06, both builds | Staff QA account `55162517` rejected by DotRez QA (`Credentials:Failed`) — worked on 2026-09-01 | F-01: ask QA (hectorcervantes) for a working Staff/Agency account; row-3 content evidence stands meanwhile, gap stated in the delivery comment |
| P2 (test asset) | PRC-34 (matrix up to date) | attached collection TC09/02 | assertion encoded the pre-VB-#5 scope ("Trips/Add out of scope") | fixed in the working copy; re-attach with the evidence |
| P3 (environment) | — | launch | port 9050 lives only in `launchSettings.json`; running the exe needs `ASPNETCORE_URLS` | documented in `continue-recovery.md` |

## Plan alignment

- Deviations found vs `phase-05-plan.md`: none beyond those already recorded in its §Deviations (user 2026-09-05): single squashed commit (the user's own force-push, plus the local amend for the -v3 two-line delta), rows 4–9 screenshots reused.

## Gate markers

TESTS: GREEN

(Full suite: 658 total, 567 executed, 0 failed — `attachments/dotnet-test-1e65eb8a3.txt`. Matrix: S-01…S-15 above, all PASS on the branch; the only red assertion on the Solution side is the external Staff login, F-01.)

## Handoff
- `phase_status`: pass
- `highest_severity`: P2 (F-01 external Staff account; collection assertion fixed)
- `next_phase`: 9
- `blocking_reason`: n/a
- `required_inputs_for_next_phase`: `review-code-1e65eb8a3.md` (REVIEW-CODE run on the same SHA), `defend-2026-09-05.md`
- `evidence_paths`: `work/API-1738/attachments/evidence-runs/`, `attachments/dotnet-test-1e65eb8a3.txt`, `config-backups/`, `evidence/screenshot-checklist.md`
- `delivery_state_updated`: yes
