# /continue plan — API-1711 (2026-09-22)

Status: **AWAITING USER APPROVAL** — nothing below has been executed. Mode: **adoption** (no
`work/API-1711/` existed before this run; the only writes so far are this file and the gitignored
snapshot `ticket-snapshots/2026-09-22-1625.txt`).

## 1. Status summary (Stage A, read-only)

| Area | Finding | Evidence |
|---|---|---|
| Preflight | `jira_sync.py doctor`: 0 hard failures; WARN docker daemon not running | doctor output 2026-09-22 (run by the orchestrator) |
| Ticket | **Done**, Test Flow TEST COMPLETE, labels `Daniel, TestCaseReady, TestComplete, Wędzicha`, assignee Arturo Cesar Garza Alvarez, devoluciones **2**, time 66h (Piotr 18h, daniel.llano 48h) | `ticket-snapshots/2026-09-22-1625.txt` |
| Comments | 4 total. Last is Arturo (QA) 2026-09-07 "tested and it is working as expected" + 9 screenshots (VAAB/VAAC services, admin toggle "Group Charges By Price Type"). **No comment after that; nothing reopens the ticket** | snapshot; `API-1711_attachments/API-1711_{1..9}.png` |
| Evidence subtask API-1833 | Status **Backlog**, unassigned, 0 comments, while the parent is Done. 5 matrix rows with evidence; TC01–TC04 images uploaded **2026-08-12 09:08**, TC05 images **2026-08-28 15:00** | `jira_sync.py ticket API-1833` dump, Attachments section |
| PRs on the key | **#2451** `feature/API-1711/extend-basket-charges` MERGED 2026-08-05 (merge `fec279033`, approved wielinskip) — the priceType/remainingBalance contract. **#2463** `feature/API-1711/group-basket-charges-by-pricetype` MERGED 2026-09-03T15:10:25Z (merge `ffa792bce`, head `21d281965`). (#1711 in the search is an unrelated 2024 PR number match.) | `gh pr list -R … --search API-1711 --state all` |
| PR #2463 reviews | piotrwedzicha: CHANGES_REQUESTED 08-26 + 08-27, **APPROVED 09-03** ("You forgot to update PR description"). All 5 review threads `isResolved: true`. PR body `lastEditedAt 2026-09-07T14:02:57Z` (after merge) and now describes the per-charge toggle ⇒ the approval note was addressed | `gh api …/pulls/2463/reviews`, GraphQL `reviewThreads`, `lastEditedAt` |
| PR #2463 CI | Build SUCCESS; **SonarQube Quality Gate FAILED — "2 New issues"** at merge time; issue content `unknown` (dashboard not read) | `statusCheckRollup`, sonar bot comment 2026-09-03T15:10:07Z |
| Merged diff (#2463) | 3 files: `Configuration/Parts/BasketConfigPart.cs` (+1, `BasketChargeConfig.GroupChargesByPriceType`), `Concepts/Admin/ConfigPart/Schema/BasketConfigPartSchema.cs` (+3), `Concepts/_Shared/Charges/BasketTravelChargesOutputBuilder.cs` (+108/−55). **No test project change** | `gh pr view 2463 --json files`; `git diff --stat ff81efcba...21d281965` |
| Master since merge | `ffa792bce` and `fec279033` are ancestors of `origin/master` `9c2ccad2`; **no commit after the merge touches the 3 files** | `git merge-base --is-ancestor`; `git log ffa792bce..origin/master -- <3 files>` (empty) |
| Docs (ApiLLM) | Published `origin/main` anchor `last_documented_commit: 9c2ccad2` = current `origin/master` ⇒ **FRESH**; `ffa792bce` is its ancestor and `documents/concepts/Basket.md` §"Changes at e004bf9d" §1 + `_meta/flags-and-rules.md` :52/:136/:141 document PR #2463 ⇒ **Phase 11 doc-sync already done** | `git -C ApiLLM show origin/main:documents/_meta/sync-state.md`; `git grep GroupChargesByPriceType origin/main -- documents` |
| Docs-sync hook "288 STALE" | Measured from the ApiLLM working tree on `feat/sync-check-hardening-and-testing-scripts`, not published `origin/main`. Not a real staleness | `git -C ApiLLM rev-parse --abbrev-ref HEAD` |
| Code repo tree | On `feature/API-771/Admin-Panel-Roles-And-Security-with-Microsoft-SSO` @ `c8b7680e`, `global.json` modified, 33 untracked paths, 3 pre-existing stashes. **Not API-1711's; will not be touched.** The Bash guard resolves the task to API-771 from that branch | `git status --porcelain`, `git stash list` |
| This repo | `.claude/hooks/lib-gate.sh` modified and `work/API-1858/`, `work/API-1738/continue-plan-…` untracked — **not this run's**; `work/_active` = `API-1738` | `git status --porcelain` |

### Spec deltas (no earlier snapshot ⇒ compared ticket ↔ subtask ↔ merged code)

| # | Delta | Evidence |
|---|---|---|
| SD-1 | Description matrix has **4 rows**; the subtask matrix has **5** (TC05 "included mixed charge not grouped", added 08-28 per the 08-28 comment). Description never got TC05 | snapshot, "Test Case Matrix" vs "Subtasks" sections |
| SD-2 | Description bullets **"Expose stored priceType for … seat charges"** and **"Extend loyaltySummary.remainingBalance with services and seat price"** are **not delivered on master for seats**: seat charges are built without a `priceType` argument (`Concepts/_Shared/Charges/ServiceChargesConverter.cs :: GetExtendedSeatCharges`, the `ExtendedServiceCharge.Create(… newestSeatFee.SsrNumber)` call, default `priceType = null` per `Basket/GetBasket/ExtendedServiceCharge.cs :38`). Commit `c4afd4b43` ("Expose seat priceType and include Points seats in remaining balance") was reverted inside the PR by `96ba0f947` (net diff over those files empty — ApiLLM `Basket.md` :268-273). Reviewer thread 3861922810: seat price belongs to **API-1664** (PR #2423, still **OPEN**). Services part: `remainingBalance` is numeric `int?` (`BasketOutputBuilder.cs :120`) and the minimum includes Points services (`PointsMinimumProvider.cs :: GetRequiredPointsServiceAmount`, from `97d912c1d` API-1662) ⇒ delivered | `git show origin/master:…`; PR threads |
| SD-3 | TC01–TC04 expected results are **seat-based** ("Points-priced seats return priceType: Points", "baseline − servicePoints − seatPoints", "mixed seats", "homogeneous Points seats"). With seat `PriceType == null` on master, `ShouldGroupByPriceType` requires every charge to have non-null `PriceType` (ApiLLM `Basket.md` :244-248, code `BasketTravelChargesOutputBuilder.cs :397-411`) ⇒ seats can never be grouped on the merged code | as above |

### Evidence coverage (vs last code change `21d281965`, authored 2026-08-28T10:47 −04:00)

| Row | Evidence date | Verdict |
|---|---|---|
| TC01, TC02 | 2026-08-12 (before `96ba0f947` authored 08-26 reverted the seat scope) | **Stale + contradicted**: produced on code that was not merged; not reproducible on master (SD-2) |
| TC03, TC04 | 2026-08-12 | **Stale**: seat-based, pre-rework; grouping of seats impossible on master (SD-3) |
| TC05 | 2026-08-28 15:00 | Post-dates last code change → covered |
| QA (Arturo) | 2026-09-07, post-merge | Covers grouping with **services** (VAAB/VAAC) — de-facto evidence that the merged feature works; not mapped to a matrix row. Observation: screenshot 9 shows a VAAC row with `isIncluded: true` and `priceType: "Points"` (not `null`); whether that contradicts TC05 depends on why it is included (config `ShowAsIncluded` vs overridden-as-included) — **unknown** |

## 2. Classified deltas

| # | Delta | Class |
|---|---|---|
| D-1 | Ticket Done, PR merged, docs synced; nothing reopened | none — informational |
| D-2 | SD-2: seat priceType + seat part of remainingBalance not delivered; deferred by the reviewer to API-1664 (PR #2423 open) but the ticket description still promises it | **question** (Q1) — a requirement moved; no code from this ticket |
| D-3 | SD-1/SD-3 + evidence: matrix TC01–TC04 describe seat behaviour and their evidence is from pre-rework code | **question** (Q2) — ticket/evidence hygiene, needs requester/QA decision |
| D-4 | Evidence subtask API-1833 in Backlog while parent Done | bounded Jira hygiene (only with your ok) — folded into Q2 |
| D-5 | Sonar Quality Gate failed (2 new issues) at merge | **question** (Q3), non-blocking |
| D-6 | No unit tests in PR #2463 for `ShouldGroupByPriceType` / split path | gap — record in Phase 11; new ticket only if you want (Q3) |
| D-7 | No `work/API-1711/` pipeline record at all | bounded pipeline closure (adoption record, no code) |

No bounded code rework on API-1711: nothing was reported against the merged code.

## 3. Open gaps and questions

- **Q1 (blocking for "API-1711 complete per its description") — where does the seat scope live?**
  Options: (a) API-1664 owns seat priceType + seats in `remainingBalance` + seat grouping; API-1711
  is closed as delivered-with-scope-moved, and the ticket gets a note saying so; (b) API-1711 is
  reopened to deliver the seat part (contradicts the reviewer's 🐛 thread 3861922810);
  (c) a new ticket. **Recommendation: (a)** — it matches the reviewer's explicit decision and the
  open PR #2423; confirm with Piotr/Arturo that API-1664 carries it.
- **Q2 — test matrix + evidence hygiene.** TC01–TC04 (seat-based, 2026-08-12 evidence) are not
  reproducible on master. Options: (a) leave Jira as is and record the gap only in the local
  Phase 11 record; (b) with your ok, post a comment stating TC01–TC04 seat assertions moved to
  API-1664 and that the post-merge QA run (09-07, services) is the effective evidence, add TC05 to
  the description, and move API-1833 out of Backlog; (c) re-run TC01–TC04 with services instead of
  seats and attach fresh evidence. **Recommendation: (b)** — cheapest honest fix; (c) only if QA
  asks. Any Jira write goes through `deliver … --dry-run` first.
- **Q3 — Sonar 2 new issues + no unit tests.** Recommendation: record in Phase 11; open a small
  debt ticket only if the Sonar issues are 🐛/❗ (content currently `unknown` — you or I can read
  the dashboard; I have not).
- **Q4 — production:** deployed / enabled anywhere? `groupChargesByPriceType` is absent from the
  seed (`flags-and-rules.md` :141 — ships inert); live Admin Portal values are outside the repo.
  Arturo's screenshot shows the toggle in some Admin Portal (environment `unknown`).
  Recommendation: record `unknown` unless you confirm.
- **Q5 — adoption depth.** The code is merged, so gate artifacts (phases 0–9) would unlock nothing.
  Options: (a) lightweight: `delivery-state.md` + `phase-11-post-merge.md` only, stating the
  adoption and that phases 0–10 ran outside the pipeline; (b) full retro-backfill of 0–9.
  **Recommendation: (a)**.
- **Q6 — Stop gate:** ApiLLM tree on your feature branch makes the docs gate report STALE; I will
  not touch it. Switch it to `main` when convenient, or accept refusals / `VIVA_SYNC_GATE_OFF=1`.

## 4. Steps (this repo only unless Q2=(b); no code repo, no PR writes)

| # | Step | Touches |
|---|---|---|
| P-01 | Create `delivery-state.md` from `process/_templates/delivery-state.md` **by hand** (not `tools/new-task.sh`, which would repoint `work/_active` away from API-1738): adoption on 2026-09-22, PRs #2451/#2463, merge `ffa792bce`, phases 0–10 "outside pipeline — not claimed", this plan's approval record | `work/API-1711/delivery-state.md` |
| P-02 | Write `phase-11-post-merge.md` from `_templates/phase-artifact.md`: merges `fec279033`/`ffa792bce`; docs already synced (anchor `9c2ccad2`, `Basket.md`/`flags-and-rules.md`); flag ships inert; SD-1..3 + evidence verdicts; seat scope per Q1; Sonar/tests per Q3; prod per Q4; retro note (evidence uploaded before review rework was never refreshed → caught only now); handoff footer | `work/API-1711/phase-11-post-merge.md` |
| P-03 | Only if Q2=(b): `jira_sync.py deliver API-1711 … --dry-run`, show you the exact comment/matrix change, execute only on your yes | Jira API-1711 / API-1833 |
| P-04 | Only if Q3 says so: draft (not create) a debt-ticket text for Sonar issues / missing unit tests | this plan's follow-up |
| P-05 | `tools/save-progress.sh API-1711 "continue"` — commits + pushes `work/API-1711/` (snapshot stays gitignored) and regenerates `work/README.md`. ⚠️ must stage only `work/API-1711/` + `work/README.md`, not the foreign `lib-gate.sh` / `work/API-1858/` changes — I will verify what the script stages before running it | this repo, `origin/main` |

## 5. Git preservation plan

- Code repo: **not touched** (no checkout, fetch, stash). Recovery point irrelevant; for the record: `feature/API-771/…` @ `c8b7680e`, 34 porcelain lines, stashes @{0..2}.
- This repo: on `main` @ `8ab35c0`; foreign dirty paths (`.claude/hooks/lib-gate.sh`, `work/API-1858/`, `work/API-1738/continue-plan-2026-09-22.md`) are left untouched and unstaged.

## 6. Risks / rollback

- P-01/P-02: text only; rollback = `git revert` of the progress commit.
- P-03: Jira comment/description edit is visible to the team; rollback = edit/delete own comment (human). Dry-run first.
- P-05: pushes to this repo's `origin/main`; risk = staging foreign changes → mitigated by checking the script's staging scope first; rollback = revert commit.
