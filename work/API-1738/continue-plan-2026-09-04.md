# /continue plan — API-1738 "Display Passengers Changes" — 2026-09-04

Status: **DRAFT — awaiting the user's explicit approval (Stage B §10). Nothing below has been executed.**
Machine time at writing: 2026-09-04 23:35 -0400. Jira timestamps below are shown as returned by Jira (-0600).

## 1. Status summary (Stage A, read-only)

### 1.1 Preflight / environment
| Check | Result |
|---|---|
| `jira_sync.py doctor` | 0 hard failures, 0 warnings (Jira token valid, gh authenticated with push access, dotnet 10.0.201 + **3.1.426**, docker up) |
| Console encoding | `jira_sync.py ticket` fails under the default cp1252 console; works with `PYTHONIOENCODING=utf-8` (tooling note, not a code change) |
| Docker (`vbgeneric-development-*`) | 12 containers up ~30 h: db :9500, cache :9502, identity STS :9505, admin :9506, adminportal :9507, portainer :9508 |
| Local API | `VivaAerobus.Generic.Api.exe` PID **7148**, listening :9050 (the Postman collection's `api1738BaseUrl`), started 2026-09-03 17:40 -0400 from a **build dated 2026-09-03 16:28 -0400** (`bin/Debug/netcoreapp3.1`), parent process gone (orphan of an earlier session). That build predates every commit after `5aab3a22e`. Not started by this run ⇒ stopped only with the user's OK |
| DotRez QA `dotrezapi.test.vb.navitaire.com` | `curl` to the root returned `000` (no HTTP answer) → **reachability unverified**; `api-gw-test.vivaaerobus.io/vb` answers 403 (reachable). Real check = a login through the API in Stage C (bounded to 2 attempts) |
| .NET SDK | Repo pins `3.1.200` (`global.json` at HEAD, no rollForward); machine has `3.1.426` → the **local, uncommitted `global.json` change** (3.1.426 + `rollForward: latestPatch`) is what makes local builds work. It must never be staged |

### 1.2 ApiLLM docs sync (CLAUDE.md step 1)
- Local checkout `../VivaAerobus.Generic.ApiLLM` is on branch `feat/sync-check-hardening-and-testing-scripts`, **4 ahead / 12 behind `origin/main`**, with an uncommitted change to `tools/jira-sync/jira_sync.py`. Its `documents/_meta/sync-state.md` anchors **1431f135** → **STALE** vs code `origin/master`.
- `origin/main` of ApiLLM (fetched, not checked out) anchors **e004bf9d = code `origin/master` HEAD** (sync of 2026-09-04 22:35Z) → **CURRENT**.
- Decision for this task: read `documents/**` and `guidelines/**` from `origin/main` via `git show origin/main:<path>` (no checkout, the user's tree untouched). Stated in every artifact. Recommendation to the user (their call, not done here): bring that checkout back to `main` when convenient.
- Neither `origin/main` docs nor guidelines mention API-1738 yet (expected: unmerged).

### 1.3 Ticket (fresh dump → `work/API-1738/ticket-snapshots/2026-09-04-2326.txt`, gitignored; first snapshot, so no diff)
- Status **In Progress**, labels `Daniel`, `TestCaseReady`; assignee daniel.llano; **3 devoluciones**; PR **#2484 OPEN**; estimate 8d, logged 7.2d.
- `ready` gate: **READY** (matrix of 12 rows found in subtask **API-1870**, the authoritative matrix — identical to the description's).
- Business answers already given by VB (Luis Alejandro Moreno Alvarez, 2026-09-02) to the 6 questions raised from review: (1) keep ticket scope incl. Part 4; (2) keep the name `TreatContactEmailMatchAsSameAccount`; (3) DisplayPassengers evaluated in **Manage and Check-in** only; (4) mask email in **both** `upcomingTrip` and `basket.travelSummary`; (5) **always mask on account APIs** regardless of the rule; (6) keep scope of 5 (no per-PNR fan-out).
- Part 4 in the description now explicitly lists `POST /v1/Account/Trips/Add` and says masking on the three account endpoints is unconditional.
- QA credentials for Agency/Enterprise/Staff were posted in a comment (2026-08-27) — they stay in the gitignored dump and are never copied into tracked files.
- Spec deltas vs the PR body: the PR description still says `GET /v1/Account/Trips` "retrieves the full booking information … intentionally sequential" — **outdated** (the fan-out was removed on 2026-09-02); Part 4 scope now includes Trips/Add. The PR body needs an update (step P-13).

### 1.4 PR #2484 (`feature/API-1738/display-passengers-changes` → `master`)
- Head **5f26398c0** (7 commits), base master. `mergeable: false / dirty` → **conflicts with master**. Files touched by both sides: exactly one — `Concepts/_Shared/Charges/BasketTravelChargesOutputBuilder.cs` (the branch's own change there is **whitespace-only**: 2 blank-line trims + EOF newline; master rewrote the method in the meantime).
- Reviews by **nowakmarcin**: CHANGES_REQUESTED ×3 (2026-09-02 on ba3120948; 2026-09-03 on 99b609265; **2026-09-04 11:16Z on 46ccc9840** — still standing; no review after head 5f26398c0 was pushed at 15:01Z).
- **20 review threads, zero replies from the author** on GitHub (T18 has the reviewer's follow-up: "it seems like you've ignored this comment"). Decisions were communicated via Jira instead. Every thread needs a reply (step P-13).
- CI: check-runs for 5f26398c0 = **none** (last runs: Build + SonarQube success on 5aab3a22e); SonarQube quality gate passed on 2026-09-04 00:26Z (for 46ccc9840). No PR exists for the -v2/-v3 branches.

Thread → state on the -v3 content (verified by reading the diff):

| Thread | Reviewer ask | State in -v3 | Reply to post |
|---|---|---|---|
| T01 | pass `maskContactData` into `BookingUserOutput.Create/CreateFromBookingComment` | done (`BookingOutput.cs`: `MaskUsernameForCustomerAccount`) | fix ref |
| T02 | ask VB about toggle name | VB: keep the name (Jira 2026-09-02 #2) | decision ref |
| T03 | rename to `IsContactEmailTheSame` | done (`CreationAccountCriteria.cs`) | fix ref |
| T04 | `agent.UserName` never null | done (check removed) | fix ref |
| T05 | flow scope question | VB: Manage + Check-in (#3) | decision ref |
| T06 | upcomingTrip vs travelSummary | VB: both (#4) | decision ref |
| T07 | fake currency/IROP context | moot: account APIs always mask, no rule evaluation (#5) | fix ref |
| T08 | GetBookingRequest fan-out perf | removed; `RetrieveBookingsRequest` projects `distributionOption` (#6) | fix ref |
| T09 | check provider in TripsOutputBuilder | moot: parameter removed, always mask | fix ref |
| T10 | `agent` never null in TripOutputBuilder | moot: code removed | fix ref |
| T11 | revert `BookingContactsBuildResult` upstream design | done: decision back in `BookingOutputBuilder`, passed downstream (identical shape to ee14bce2e) | fix ref |
| T12 | drop `basket = null` default | done in provider; **`CreateFromBookingComment(…, bool maskContactData = false)` still carries a default** → candidate finding (P-06) | fix ref / decision |
| T13 | drop `[UsedImplicitly]` | done | fix ref |
| T14 | register provider in Shared | done (`ConceptsSharedRegistry.cs:463`) | fix ref |
| T15/T16 | revert AI noise in `AccountBookingsProvider.cs` / `GetTripsHandler.cs` | done (files no longer in the diff) | fix ref |
| T17 | 👍 keep the comment | kept (also added to `TripOutputBuilder`) | ack |
| T18 | Trips/Add must mask; "have you discussed with VB?" | done in cf54f2a90; VB #5 + ticket Part 4 text cover Trips/Add | fix + decision ref |
| T19 | remove `ShouldMaskContactData` from `ManageAndCheckinRulesValidator` (option 2: provider as before) | done in 5f26398c0 (validators back to master) | fix ref |
| T20 | revert noise in `ConceptsSharedRegistry.cs` | done (+1 line only) | fix ref |

### 1.5 Branch state (code repo, read-only)
| Ref | Tip | Notes |
|---|---|---|
| local `feature/API-1738/display-passengers-changes` (checked out) | **5aab3a22e** (2026-09-03) | **2 behind** `origin/…` (46ccc9840, 5f26398c0 were pushed from elsewhere); 20 behind master |
| `origin/feature/API-1738/display-passengers-changes` | 5f26398c0 | PR head; 7 commits; conflicts with master in 1 file |
| `origin/…-v2` | ea9817aa4 (DLlano-VA, 2026-09-04 14:56 -0400) | 1 squashed commit on top of master (0 behind) |
| `origin/…-v3` | abe4bb5d8 | the 7 PR commits **rebased onto master** (committer guillermoplus) + **3 commits authored by `guillermoplus` <luisgal93@hotmail.com>** (GitHub: Clouding Studio; appears as a developer in the ApiLLM guidelines' PR evidence): cf54f2a90 Trips/Add always masks (T18), f2b962b36 rationale comments + EOF formatting, abe4bb5d8 drop default on `BookingUserOutput.Create` + blank line. **0 behind master, no conflicts.** v3 − v2 = those last 2 lines |
| `origin/master` | e004bf9d8 | |

Content delta PR-head → -v3 on the branch's files: Trips/Add + `TripsOutputBuilder` now always mask (parameter removed), comments, EOF newlines, `Create` default removed, and the whitespace-only touch on `BasketTravelChargesOutputBuilder.cs` dropped. Nothing else.

### 1.6 Working-tree hazards (code repo)
- Modified tracked: `VivaAerobus.Generic.Api/global.json` (SDK 3.1.426 + rollForward — **needed to build locally**), `appsettings.Development.json` (Yuno timeout + `Security.PasswordEncryption.PrivateKeyPem` — local env for another ticket). Master did **not** touch these files since the fork ⇒ a merge will not collide with them. Plan: **leave them in place, never stage them**.
- Untracked: ~35 paths from other tickets (`docs/API-*`, `docs/Postman/API-*`, `scripts/`, `docker/*.ps1`, …) — the developer toolkit that is untracked on purpose (ApiLLM `llm/testing-scripts.md` §6). Includes `docs/Postman/API-1738-Display-Passenger-Changes.postman_collection.json` (mtime 2026-09-02 23:13; **contains QA/Staff/Admin passwords as collection variables**). Left untouched; never staged.
- Stashes: `stash@{0}` (API-1624 seed edits), `stash@{1}` (API-1598) — **pre-existing, never popped or dropped**.
- Checked-out branch is the ticket's own branch (no foreign branch).

### 1.7 Evidence coverage (subtask API-1870 — 12 rows; 22 PNG + collection JSON attached)
Evidence style observed: Postman **Runner GUI screenshots** with red (Issue) / green (Solution) annotations, named `API-1738_TC<nn>_<slug>_Postman.png` (pairs, but not the literal `Issue`/`Solution` tokens of PRC-104). Reviewer's own screenshot (`image-20260904-100651.png`) shows matrix row 4, flagged as missing at the time.

| Row | Case | Result in subtask | Evidence files | Freshness vs code |
|---|---|---|---|---|
| 1–3 | rule true / Customer creator / non-Customer creator | PASS | TC01–TC03 pairs, uploaded **2026-09-01 17:40** | **STALE** — predates ee14bce2e, 99b609265, 5aab3a22e, 46ccc9840, 5f26398c0 and -v3 |
| 4–9 | booking-flow basket / email match / mismatch / pending verify / verified / Trips/Add | PASS | TC04–TC09 pairs, uploaded **2026-09-04 18:40** | timestamp is after the -v3 tip (17:21 -0600), but the **build that produced them is unknown** — this machine's API instance runs a 2026-09-03 build. UNVERIFIED |
| 10 | linked trip, DP=false → GET /Account + /Trips masked | **blank** | none dedicated (TC09 pair shows GET account/trips after Add) | GAP |
| 11 | basket.travelSummary masked | **blank** | TC10 pair (names say "BasketTravelSummary") | GAP (result not recorded; numbering off by one) |
| 12 | DP=true, genuinely owned trip still masked | **blank** | TC11 pair (names say "OwnedCustomerTrip") | GAP (result not recorded; numbering off by one) |

Postman collection has 9 TC folders (TC01–TC09) whose numbering is shifted from the matrix from row 4 on (collection TC04 = matrix row 5 …) and has **no case for row 4 (booking-flow basket) or row 10**. The reviewer explicitly asked (2026-09-03 and 2026-09-04) that all cases be re-executed after the code changes and that new/changed cases be in API-1870.

## 2. Classified deltas (Stage B §8)

| # | Delta | Class | Handling |
|---|---|---|---|
| D1 | Local checkout 2 commits behind the PR head | bounded | fast-forward (P-03) |
| D2 | PR conflicts with master (1 file, whitespace-only on our side) | bounded | merge `origin/master`, keep master's version of that file (P-04) |
| D3 | Reviewer findings T18/T19/T20 + formatting, already implemented on `-v3` by another author | bounded rework | bring the -v3 commits onto the PR branch as fix-forward commits, authorship preserved (P-05). Force-push/rebase of the reviewed branch is **not** an option (§10.2.4, safety protocol) |
| D4 | Remaining default parameter on `CreateFromBookingComment` (T12 spirit / abe4bb5d8 spirit) | bounded (conditional) | Phase 9 checks callers; fix commit only if every caller passes the flag (P-06) |
| D5 | 20 unanswered review threads | bounded | reply to every one with fix SHA or VB decision (P-13) |
| D6 | PR description outdated (fan-out paragraph; Trips/Add) | bounded | edit PR body (P-13) |
| D7 | Evidence stale (rows 1–3), unverified build (4–9), missing results (10–12), collection numbering ≠ matrix, row 4/10 cases missing | test gap | rebuild collection to 12 rows, re-run all rows on the final code, Issue/Solution per PRC-104 (P-08, P-09) |
| D8 | VB's 6 answers (2026-09-02) | scope settled | no rework; cite them in the PR replies and the artifacts |
| D9 | No `work/API-1738/` pipeline state | adoption | backfill phases 0–5 (P-02) |
| D10 | Rigor level | classification | **risky** (new booking-rules toggle + output values change + privacy surface — CLAUDE.md table: "contract, flags"; when in doubt, one level up) → `HUMAN-GATE-REQUIRED`; the user signs `HUMAN-GATE-OK` after reading `phase-05-plan.md` |
| D11 | Squash policy: CLAUDE.md §9.3 says ONE squashed commit; §10.2.4 and this command say fix commits stay on the reviewed branch, squash at merge | process deviation | recorded up front in `phase-05-plan.md` §Deviations as approved with this plan |

## 3. Open gaps and questions (none blocks writing the plan; the approval settles them)

- **Q1 (decision)** — Is the `-v3` branch the intended final content, and is `guillermoplus` a teammate whose three commits should land with their authorship? Recommendation: yes — -v3 is the PR history rebased on master plus exactly the reviewer's asks; nothing else changed.
- **Q2 (permission)** — May this run stop the orphan API instance PID 7148 (:9050, 2026-09-03 build) and start a fresh build of the branch on the same port for evidence?  Recommendation: yes; it cannot produce evidence for the current code.
- **Q3 (decision)** — Evidence scope: (A) re-run **all 12 rows** on the final code with Issue (master build) / Solution (branch build) captures — recommended, it is what the reviewer asked twice and rows 10–12 have no result; (B) only rows 1–3 and 10–12, keeping today's 4–9 uploads. B is defensible only if you can confirm which build produced today's 18:40 uploads (see Q4).
- **Q4 (information)** — Which machine/build produced the evidence uploaded 2026-09-04 18:40 and the collection uploaded 19:35? Not this machine's running instance.
- **Q5 (decision, evidence format)** — The team's evidence is Postman Runner screenshots. I can run every case with `newman` and record results in `phase-07-testing.md`, but the annotated PNGs are a human step: (A) you capture the screenshots from Postman using the prepared collection (I hand you a per-row checklist with exact file names) — recommended; (B) newman HTML reports attached instead of screenshots (departs from what QA/reviewer have accepted so far).
- **Q6 (hygiene)** — The collection JSON uploaded to API-1870 today likely carries the QA/Staff/Admin passwords as variables (the local copy does). Recommendation: the re-uploaded collection has credential variables emptied and a separate, untracked environment file holds them. Your call whether to also delete today's attachment in Jira (outward action, done by you or with your explicit OK).
- **Q7 (optional)** — After the PR branch equals -v3, the `-v2`/`-v3` remote branches become redundant. Deleting them is outward and one was pushed by someone else → only if you say so; default: leave them.
- Note — `work/API-1738/ticket-snapshots/` is not covered by the repo `.gitignore`; I placed a `.gitignore` (`*`) inside it so `save-progress.sh` cannot version a dump with credentials. Process owners may want the root `.gitignore` to cover the folder.

## 4. Steps (P-NN) — executed only after approval; each closes by updating `delivery-state.md`

| # | Step | Touches |
|---|---|---|
| P-01 | Recovery point: write branch, HEAD `5aab3a22e`, `status --porcelain`, `stash list` to `work/API-1738/continue-recovery.md`. **No stash**: dirty files are local build prerequisites, untouched by master, never staged | `work/API-1738/continue-recovery.md` |
| P-02 | Adoption backfill: `tools/new-task.sh API-1738` (with `PYTHONIOENCODING=utf-8`), then phases 0–5 artifacts from `process/_templates/` against ticket + existing diff, docs read from ApiLLM `origin/main` (anchor e004bf9d; local checkout stated STALE), rigor **risky** → create `HUMAN-GATE-REQUIRED`; Phase 4 verdict written only after the analysis; Phase 5 plan with `P-NN`/`S-NN` (S-01..S-12 = matrix rows) and guideline IDs; `## Deviations (approved)` pre-seeded with D11. `save-progress.sh` after each phase. **STOP for `HUMAN-GATE-OK`** (you create it by hand) | `work/API-1738/*` only |
| P-03 | Fast-forward local branch to `origin/feature/API-1738/display-passengers-changes` (5f26398c0): `git pull --ff-only` | code repo, branch pointer only |
| P-04 | `git merge origin/master` into the branch; expected single conflict `Concepts/_Shared/Charges/BasketTravelChargesOutputBuilder.cs` → keep master's version (our side was whitespace-only); merge commit `API-1738 🔀 Merge origin/master into feature/API-1738/display-passengers-changes`; `dotnet build` | code repo (merge commit) |
| P-05 | `git cherry-pick cf54f2a90 f2b962b36 abe4bb5d8` (authorship preserved); verify `git diff origin/…-v3 --stat` is **empty**; `dotnet build` | `AddTripHandler.cs`, `TripsOutputBuilder.cs`, `TripOutputBuilder.cs`, `AccountTripOutputBuilder.cs`, `BookingContactsOutputBuilder.cs`, `BookingOutputBuilder.cs`, `BookingPassengerOutputBuilder.cs`, `CreationAccountCriteria.cs`, `ContactDataMaskingProvider.cs`, `BookingOutput.cs` |
| P-06 | Conditional: grep callers of `BookingUserOutput.CreateFromBookingComment`; if all pass the flag, one fix commit dropping the `= false` default; otherwise record "no change, reason" in Phase 9 | `Concepts/_Shared/Models/Output/BookingOutput.cs` (only if confirmed) |
| P-07 | Phase 7 (automated): `dotnet test` full suite in `src/tests` on the integrated HEAD; `TESTS: GREEN` only if green | `work/API-1738/phase-07-testing.md` |
| P-08 | Local runtime for evidence (needs Q2): stop PID 7148, build + run the branch on :9050 (PID recorded), verify a login reaches DotRez QA (≤2 attempts, else blocker); for the Issue side, run a `master` build the same way (worktree or second checkout — no checkout switch of the main tree) | processes started by this run; `work/API-1738/continue-recovery.md` |
| P-09 | Test assets: download the collection attached to API-1870 (19:35 upload), compare with the local copy, base on the newer; restructure to **12 folders = 12 matrix rows** (add row 4 booking-flow basket case and row 10 linked-trip case; renumber); move credentials to an untracked environment file; run every row with `newman` twice (master = Issue, branch = Solution); hand you the per-row checklist for the screenshots (`API-1738_TC<row>_Issue_<slug>.png` / `_Solution_<slug>.png`, PRC-104). Admin config mutations (BookingRules/BookingVerify) are `get`-backed-up into `work/API-1738/config-backups/` before any `set` and restored after | `docs/Postman/API-1738-*.json` (stays untracked), `work/API-1738/evidence/`, `work/API-1738/config-backups/` |
| P-10 | Phase 9: `process/REVIEW-CODE.md` on `origin/master...HEAD` → must be APPROVED; completeness audit ticket (12 rows + VB's 6 answers) ↔ plan ↔ diff; `DEVIATIONS: APPROVED-AND-DOCUMENTED` (D11); `VALIDATED-SHA` = HEAD | `work/API-1738/phase-09-pre-review.md` |
| P-11 | `/defend-changes API-1738` → dossier + draft replies for T01–T20 | `work/API-1738/defend-<date>.md` |
| P-12 | Publication gate: show `git log origin/<branch>..HEAD --stat`; **WAIT for `work/API-1738/PUSH-APPROVED`** (you create it); `git fetch` right before; `git push origin feature/API-1738/display-passengers-changes` (never force); if the remote advanced, integrate and re-run P-07/P-10 | remote branch |
| P-13 | PR: reply on all 20 threads (fix SHA or VB decision + Jira date), never resolve/dismiss; edit the PR body (fan-out paragraph, Trips/Add); post a one-paragraph "what changed since 46ccc9840" summary; re-request review from nowakmarcin; confirm CI ran on the new head | PR #2484 |
| P-14 | Jira: `jira_sync.py deliver API-1738 --evidence … --pr 2484 --comment … --dry-run` → show → deliver on your yes (evidence + credential-free collection to API-1870, comment with PR link, `TestComplete` added keeping `TestCaseReady`, transition, unassign for QA per PRC-106); fill Execution Result for rows 1–12 in the subtask matrix (via the bridge if supported, else I hand you the exact text) | Jira API-1738 / API-1870 |
| P-15 | `tools/save-progress.sh API-1738 "continue"`; report recovery status and the folder | Coder repo `work/API-1738/` |

Anti-scope: no toggle rename (VB), no change to the account profile's own `contactDetails.emailAddress`, no refactors beyond the reviewer's asks, no changes outside the file list above; any out-of-scope finding becomes a new ticket (Phase 6.4).

## 5. Git preservation plan
- Recovery point (recorded in P-01 before any mutation): branch `feature/API-1738/display-passengers-changes`, HEAD **5aab3a22e**; remote head **5f26398c0**; dirty tracked files `global.json`, `appsettings.Development.json`; 35 untracked paths; stashes `stash@{0}`, `stash@{1}` (pre-existing, never touched).
- No stash is created: nothing dirty overlaps the plan's paths or master's changes.
- Staging is by explicit path only; before P-12 the staged/committed file list is reconciled against §4 — anything outside stops the run.
- Forbidden throughout: `reset --hard`, `clean`, `checkout -- <tracked paths>`, stash drop/pop, any history rewrite, force-push.

## 6. Risks and rollback (per mutating step)
| Step | Risk | Mitigation / rollback |
|---|---|---|
| P-03/P-04/P-05 | wrong conflict resolution or cherry-pick drift | proof = `git diff origin/…-v3` empty + build; all local until P-12 — rollback = move the local branch back to the recorded SHA (a rewrite, so only with your explicit OK) |
| P-04 | semantic drift from the 20 master commits (e.g. name-matching rewrite in `BookingRetriever`/`LastNameValidator`, `Search.json` seed) | full suite (P-07) + all 12 rows re-run (P-09) on the integrated HEAD |
| P-06 | touching a caller outside the plan | conditional; only the one file; else no change |
| P-08 | stopping the wrong process; DotRez QA unreachable or QA accounts locked | PID recorded; ≤2 attempts then blocker report — no retry loops, no shared-state workarounds |
| P-09 | seed PNRs (`W8TMQI`, `XEFKMG`, `MC4MXM`, `AC34QJ`, `SJ3ETH`, `YG4MJQ`) no longer in the required state (e.g. pending-verification PNR already verified) | detect on first run; regenerate where we can (Customer/anonymous), otherwise a question to QA (Hector) — not a blocker for the code steps |
| P-09 | admin config left modified | `get` backup before `set`, restore in a finally step, verified after the run |
| P-12 | remote branch advanced meanwhile | fetch-before-push; integrate, re-run P-07/P-10, re-ask approval |
| P-13/P-14 | outward writes | only after `PUSH-APPROVED` / deliver `--dry-run` shown and accepted |

## 7. Approval
**APPROVED WITH CHANGES by Daniel Llano (daniel.llano@techandsolve.com) on 2026-09-05 00:01 -0400** (chat reply to the plan). Recorded in `delivery-state.md` at P-02. Changes to the plan, binding from here on:

| Q | User decision | Effect on steps |
|---|---|---|
| Q1 | Luis (guillermoplus) helped; his work must be **squashed into the last commit (amend)** and force-pushed; double-check no conflict with any part first | **P-04/P-05 replaced by P-04b**: final history = the `-v3` history (already rebased on master) with its last 4 commits (759ffd61a + cf54f2a90 + f2b962b36 + abe4bb5d8) squashed into one commit (message/author of 759ffd61a, DLlano-VA). Verify tree == `origin/…-v3` (empty diff) and build before any push. Push with `--force-with-lease` under the history-rewrite policy: pre-rewrite SHA 5f26398c0 recorded, HEAD unreviewed re-verified immediately before the push (last review 2026-09-04T11:16Z is on 46ccc9840). Protocol tension noted and accepted by the user: the six earlier commits get new SHAs (rebased copies), as Luis's -v3 already did. |
| Q2 | yes | P-08 may stop PID 7148 and restart the API as needed |
| Q3/Q4 | re-do everything only where really needed; today's evidence came from the user's other desktop (not wired to the Coder) | P-09: **all 12 rows re-executed with newman on the final commit** (record); **new screenshots only for rows 1–3 (stale, 2026-09-01) and 10–12 (no result recorded)**; rows 4–9 keep the 2026-09-04 evidence |
| Q5 | recommended (user captures Postman screenshots from the prepared collection) + install free tooling to ease evidence collection | P-09 adds newman HTML reports (htmlextra) rendered to PNG as an aid; user's Postman captures remain the Jira evidence |
| Q6 | leave the Jira collection as is unless it must change | the collection attached 2026-09-04 19:35 (11 folders; covers all 12 rows — TC09 covers rows 9+10, TC10 = row 11, TC11 = row 12) is the base; no re-upload unless a case must change |
| Q7 | clean up | P-13b: delete `origin/…-v2` and `origin/…-v3` **after** the PR branch push succeeds and equals -v3 |
| + | fix jira-sync to support all formats with fallbacks | P-00: Coder `tools/jira-sync/jira_sync.py` — UTF-8 console/file fallbacks, non-image attachments listed, any format gaps found while delivering |
| + | Luis (Tech Lead) supplied PR wording | P-13 uses it verbatim as the PR summary comment once every statement in it is true (rebased on master ✓, Trips/Add ✓, formatting ✓, 12 rows re-executed on the final commit ✓ after P-09, PR description updated ✓, every thread answered ✓) |

Any further deviation returns to this gate with the delta.

### 7.1 Refresh 2026-09-05 ~00:50 -0400 — the user executed P-04b by hand (outside the pipeline)
- `origin/feature/API-1738/display-passengers-changes` was **force-updated 5f26398c0 → ea9817aa4**: ONE squashed commit on top of `origin/master` e004bf9d8 (identical to `-v2`), message `API-1738 ✨ Mask contact data instead of passenger identity under DisplayPassengers`, 14 files, +214/−88. PR #2484 now: 1 commit, `mergeable: true`, state `blocked` (review/QG). No review or thread activity after the push (last review still 2026-09-04T11:16Z on 46ccc9840).
- **Delta vs `-v3` = 2 lines** (Luis's last commit abe4bb5d8 not included): `BookingOutput.cs :: BookingUserOutput.Create(…, bool maskContactData = false)` still has the default (single caller passes it → STY-05 "unnecessary default", and the TL summary text claims it is removed); missing blank line before `ShouldHideCustomerNumber` in `BookingPassengerOutputBuilder.cs`.
- **CI on ea9817aa4: Build ✅, SonarQube Quality Gate ❌ — "1 New issue"** (the QG passed with 0 new issues on 46ccc9840). The Sonar API needs authentication (no token on this machine); the issue text must be read from the dashboard link in the PR comment.
- Local checkout still at 5aab3a22e (5 ahead / 21 behind the new remote — the old lineage); tree unchanged; stashes untouched. PID 7148 still serving the 2026-09-03 build.
- Ticket/subtask unchanged (snapshot diff empty); evidence state as in §1.7.
- Plan effect: P-03/P-04b become "re-point the local branch to `origin/…` ea9817aa4" (local-only rewrite of an already-superseded local branch; old SHAs recorded in `continue-recovery.md`); a **fix step is added** for the Sonar issue + the 2-line delta — by amend + `--force-with-lease` (head ea9817aa4 unreviewed) if the user confirms, else fix-forward; the TL summary's "unused default … removed" line is true only after that fix. `HUMAN-GATE-OK` still pending.
