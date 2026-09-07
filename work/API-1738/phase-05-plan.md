# Phase 5 — Plan: API-1738 Display Passengers Changes

Rigor **risky** → `HUMAN-GATE-REQUIRED` present; the human approves this plan by creating `work/API-1738/HUMAN-GATE-OK` by hand. Docs: ApiLLM `origin/main` (anchor e004bf9d). Code refs relative to `VivaAerobus.Generic.Api/src/app/VivaAerobus.Generic.Api/`.

## Design

**Options compared (all three were named by the reviewer in T19, 2026-09-04):**

| Option | Description | Trade-offs |
|---|---|---|
| **A — dedicated provider, decision passed downstream (chosen)** | `Concepts/_Shared/Booking/ContactDataMaskingProvider.cs :: ShouldMaskContactData` evaluates `DisplayPassengers` through `IManageAndCheckinRulesValidator` and the pending-verification exemption once; `BookingOutputBuilder` (:295) passes the boolean to the contacts, passengers and user builders | one decision point, no validator subclassing, reusable from `_Shared` (ARC-10, ARC-14); this is the -v3 content and the reviewer's option 2 — the design he had no comments on in round 1 |
| B — `DisplayPassengersRuleValidator : ManageAndCheckinRulesValidator` overriding `Validate<T>` | keeps everything inside the rule engine | introduces a rule-specific validator type into a generic engine and still needs the verification lookup; more surface than the business asked (ARC-16) |
| C — private method in `BookingOutputBuilder` | smallest | hides a reusable business decision in a 600-line builder; the verification exemption is not a builder concern (ARC-14) |

Justification: A is the simplest design that meets all acceptance criteria, matches the reviewer-accepted round-1 structure, and is what the Tech Lead's final wording describes ("Final design, and it stays"). No ADR: not structural for other teams; the decision record is this plan + the PR summary.

**Guideline IDs the code must honor (normative, GOLDEN RULE 5):** ARC-10 (shared code under `_Shared`), ARC-11/ARC-12 (interface + explicit registration `ConceptsSharedRegistry.cs:463`), ARC-14 (decision in a provider), ARC-16 (no more than asked), ARC-46 (builders receive the boolean, not the whole context), ARC-63 (`ToMaskedEmail` reused, no second email mask), ARC-90 (masking applied at every usage point of the same rule), ARC-95 + PRC-37 (config part ↔ schema ↔ seed 1:1, default false), STY-05 (defaults only where load-bearing — see anti-scope), STY-06, STY-08 (rationale comments only), STY-86 (BOM unchanged), STY-91, ROB-23 (null-safe `?.` on contacts/phones), ROB-45, ROB-78 (existing Admin documents), PRC-30/PRC-31 (commit hygiene), PRC-32 (rebased on master before review), PRC-33/PRC-34 (real data, matrix up to date), PRC-35 (VB answers linked), PRC-36 (release notes present), PRC-38 (Sonar QG), PRC-85 (one fix per comment where new fixes arise), PRC-96, PRC-97 (nothing outside scope), PRC-100 (how to test in the PR), PRC-102/103 (branch/commit/PR naming), PRC-104/105/106 (evidence, labels, In review + unassign).

## Specific plans

- **Data/migration:** n/a — no persisted schema changes. Admin `BookingRules` documents: new optional key, missing → `false` (ROB-78); seeds updated ×20 for fresh environments; existing environments via the Admin Portal (flagged in the PR checklist).
- **Backward compatibility:** response shapes unchanged; values change (masked strings where the rule denies; account trips email masked instead of clear/null). In-flight baskets unaffected (no basket state touched). Old clients keep parsing.
- **Feature flag:** `creationAccount.treatContactEmailMatchAsSameAccount` — default **off**, scope per `BookingRules` rule entry, enabled by VB/ops in the Admin Portal when the contact-email bypass is wanted. It is permanent configuration, not a temporary flag → no cleanup ticket. Parts 1/3/4 have no switch (rollback = revert).
- **Observability:** no new logs (no PII). Post-release watch: 5xx/latency on `GET /v1/Booking`, `/Full`, `/Search`, `GET /v1/Account`, `GET /v1/Account/Trips`, `POST /v1/Account/Trips/Add` (existing Datadog traces carry `vb.api.flow_type`).
- **Rollout / rollback:** normal release; no ordering constraints. Rollback = revert the squash-merged commit; the extra Admin key is harmless if left behind. Irreversible actions: none.
- **Non-functional budget:** zero new DotRez calls; +1 `IsVerificationRequired` per booking output only when the rule denies (in-memory config + comment scan); GraphQL payload +1 scalar per contact on the trips retrieve.
- **Security & permissions:** no auth changes; identity fields are shown to whoever already passed the endpoint's auth/retrieval; contact data masked per rule; account views never expose the trip contact email.

## Implementation steps (numbered, stable)

| # | Step | Guideline IDs | Done |
|---|---|---|---|
| P-01 | Recovery point recorded (`continue-recovery.md`); no stash | — | ✅ 2026-09-05 |
| P-02 | Adoption backfill phases 0–5; `HUMAN-GATE-REQUIRED`; approval recorded in `delivery-state.md` | PRC-35 | ✅ (this file) — **STOP for `HUMAN-GATE-OK`** |
| P-03 | Fetch; verify no review was posted after 5f26398c0 (history-rewrite policy precondition) | — | |
| P-04b | Build the final branch **locally**: `git switch -C feature/API-1738/display-passengers-changes origin/…-v3`, then squash the last 4 commits (759ffd61a, cf54f2a90, f2b962b36, abe4bb5d8) into one commit reusing 759ffd61a's message/author (`git reset --soft 9b1983007 && git commit -C 759ffd61a`) → 7 commits on top of `origin/master`. Verify `git diff origin/…-v3` is **empty**; `dotnet build` | PRC-30, PRC-31, PRC-32, PRC-102 | |
| P-05 | Grep callers of `CreateFromBookingComment` (done: 2 notification callers) → **no code change**; record the reason for the T12 reply | STY-05, PRC-97 | ✅ analysed |
| P-06 | Stop PID 7148 (user Q2); build + run the branch on :9050 (record PID); login through the API to confirm DotRez QA (≤2 attempts) | — | |
| P-07 | Phase 7: `dotnet test` full suite on the final HEAD → `TESTS: GREEN` only if green | PRC-33 | |
| P-08 | Evidence run: newman over the Jira-attached collection (11 folders) against the branch build (Solution) and against a `master` build (Issue, via a second worktree — no checkout switch of the main tree); Admin config `get` backed up to `config-backups/` before any `set` and restored after; htmlextra reports rendered to PNG with Chrome headless as an aid; per-row checklist handed to the user for the Postman screenshots of rows 1–3 and 10–12 (`API-1738_TC<row>_Issue_<slug>.png` / `_Solution_<slug>.png`) | PRC-104, PRC-34 | |
| P-09 | Phase 9: `process/REVIEW-CODE.md` on `origin/master...HEAD` → APPROVED; completeness audit (12 rows + VB 1–6 ↔ P-NN ↔ diff); `DEVIATIONS: APPROVED-AND-DOCUMENTED`; `VALIDATED-SHA` = HEAD | all IDs above | |
| P-10 | `/defend-changes API-1738` → dossier + draft replies T01–T20 | — | |
| P-11 | Publication gate: show `git log origin/master..HEAD --stat`; wait for `PUSH-APPROVED` (user); re-verify no new review on 5f26398c0; `git push --force-with-lease=feature/API-1738/display-passengers-changes:5f26398c0 origin feature/API-1738/display-passengers-changes` | PRC-32 | |
| P-12 | PR #2484: update description (final code; Trips/Add; no fan-out); post the Tech Lead's summary comment; reply on all 20 threads (fix SHA / VB decision + date); never resolve; re-request review from nowakmarcin; confirm Build + Sonar ran (PRC-38) | PRC-100, PRC-103, PRC-38 | |
| P-13 | Delete `origin/…-v2` and `origin/…-v3` (user Q7) after P-11 succeeds | — | |
| P-14 | Jira: `deliver API-1738 --evidence <new PNGs> --results 1=PASS…12=PASS --evidence-note … --pr 2484 --comment … --dry-run` → show → run on the user's yes (evidence, matrix results, comment, `TestComplete`, In review, unassign) | PRC-105, PRC-106 | |
| P-15 | `save-progress.sh API-1738 "continue"`; report recovery/process status | — | |

## Test scenarios (numbered, stable — the acceptance criteria, one-to-one)

Collection = `API-1738-Display-Passenger-Changes.postman_collection.json` attached to API-1870 (2026-09-04 19:35, 11 folders). Row → folder mapping: rows 1–9 → TC01–TC09; row 10 → TC09 (GET /Account/Trips + GET /Account after Add); row 11 → TC10; row 12 → TC11.

| # | Scenario (matrix row) | Type | Closes AC | Evidence expected |
|---|---|---|---|---|
| S-01 | Row 1 — rule passes: all fields plain on GET /Booking, /Full, /Search (TC01) | e2e newman + manual | Part 1 baseline | **new** Issue/Solution PNG (user) + newman report |
| S-02 | Row 2 — rule denies, Customer creator: identity fields plain; contacts email/phones, passenger email/phone, `user.username` masked (TC02) | e2e + manual | Part 1 | **new** PNG pair + newman |
| S-03 | Row 3 — rule denies, Staff creator: username plain, contact data masked (TC03, Staff creds from QA) | e2e + manual | Part 1 | **new** PNG pair + newman |
| S-04 | Row 4 — Booking-flow basket on GET /Booking: nothing masked (TC04) | e2e | flow gating | 2026-09-04 evidence kept + newman |
| S-05 | Row 5 — toggle on, viewer username == primary contact email: nothing masked (TC05) | e2e | Part 2 | kept + newman |
| S-06 | Row 6 — toggle on, mismatch: masked (TC06) | e2e | Part 2 | kept + newman |
| S-07 | Row 7 — pending verification candidate: nothing masked (TC07) | e2e | Part 3 | kept + newman |
| S-08 | Row 8 — verification completed: masking resumes (TC08) | e2e | Part 3 | kept + newman |
| S-09 | Row 9 — POST /Account/Trips/Add response email masked (TC09) | e2e | Part 4 | kept + newman |
| S-10 | Row 10 — trip linked via Add: GET /Account + GET /Account/Trips email masked (TC09 steps 08–09) | e2e + manual | Part 4 | **new** PNG pair (user) + newman |
| S-11 | Row 11 — basket.travelSummary email masked (TC10) | e2e + manual | Part 4 | **new** PNG pair + newman |
| S-12 | Row 12 — rule passes, genuinely owned trip: account endpoints still mask (TC11) | e2e + manual | Part 4 | **new** PNG pair + newman |
| S-13 | Full NUnit suite green on the final HEAD (`src/tests/VivaAerobus.Generic.Api.Tests`) | unit/integration | regression | `dotnet test` output in phase-07 |
| S-14 | Final tree equals `origin/…-v3` (empty diff) and builds | build | A1, A5 | command output in phase-07 |
| S-15 | App starts on :9050 with the new registration; Customer login reaches DotRez QA | smoke | R-04 | startup log + login 200 |

## Anti-scope
- No rename of `TreatContactEmailMatchAsSameAccount` (VB #2). No masking of the account profile's own `contactDetails.emailAddress` (comment 2026-09-02). No removal of the `CreateFromBookingComment` default (two notification callers, R-05). No new unit tests (PRC-94). No refactor beyond the reviewer's asks; `ManageAndCheckinRulesValidator` untouched. No change to the main Postman collection (matrix says "Postman update? No"). No changes to files outside the 14 in the -v3 diff.

## Risks

| Risk | Prob. | Impact | Mitigation |
|---|---|---|---|
| Force-with-lease rejected (remote moved) | low | none | fetch first; if moved, stop and re-plan (never plain force) |
| Reviewer objects to the history rewrite | medium | another round | TL (Luis) drafted the summary and prepared -v3 himself; reviewed commits are rebased copies, threads keep their anchors |
| Seed PNR states changed (e.g. `MC4MXM` already verified) | medium | rows 5–7 fail | regenerate with the QA Customer account; else ask hectorcervantes — not a code blocker |
| DotRez QA unreachable / accounts locked | low | evidence blocked | ≤2 attempts, then report as blocker |
| Semantic drift (name matching) breaks retrieval in the collection | low | rows fail | rows re-run on the rebased HEAD; a failure is a finding, not a workaround |
| CI does not run on the new head | low | red gate | check after push; trigger via re-request if needed |
| Admin config left modified after evidence | low | wrong local behaviour | get-backup + restore verified |

## Deviations (approved)

| When | What changed vs the process/plan | Why | Approved by |
|---|---|---|---|
| 2026-09-05 | CLAUDE.md §9.3 "ONE squashed commit" and `/continue` §10.2.4 "fix commits stay, no force-push" are replaced by: -v3 history (7 commits, rebased on master, Luis's fixes squashed into the last) published with `--force-with-lease` under the history-rewrite policy (head 5f26398c0 unreviewed) | user's instruction Q1 ("everything should be squashed on last commit push amend"); Tech Lead's wording states "rebased on the current master" | Daniel Llano (chat, 2026-09-05 00:01 -0400) |
| 2026-09-05 | Rows 4–9 evidence not re-captured as screenshots (kept from the user's other desktop); all rows still re-executed with newman | user Q3/Q4 | Daniel Llano (same) |

## Handoff
- `phase_status`: pass (awaiting `HUMAN-GATE-OK`)
- `highest_severity`: none
- `next_phase`: 6 (P-03, P-04b)
- `blocking_reason`: human gate — `work/API-1738/HUMAN-GATE-OK` must be created by the user
- `required_inputs_for_next_phase`: `HUMAN-GATE-OK`; Coder remote push access (403 for `DLlano-VA`) is a housekeeping item, not a blocker
- `evidence_paths`: `work/API-1738/phase-0{0,1,2,3,4}-*.md`, `continue-plan-2026-09-04.md`, `continue-recovery.md`
- `delivery_state_updated`: yes
