# Phase 00 — Intake: API-1738 Display Passengers Changes

> Adoption backfill (Annex C / `/continue` Stage C step 11): the implementation started on 2026-08-25 outside this pipeline (PR #2484, 3 review rounds). This phase re-reads the ticket as it stands on 2026-09-05 and classifies the work; it does not rubber-stamp the existing diff.

## Work

### 0.0 Scaffold + fetch + readiness gate
- `tools/new-task.sh API-1738` run 2026-09-05 00:01 -0400 → `work/API-1738/delivery-state.md`, `work/_active`.
- Ticket fetched to `tools/jira-sync/jira_tickets/Others/API-1738.txt` (gitignored) and snapshotted at `work/API-1738/ticket-snapshots/2026-09-04-2326.txt` (gitignored). Evidence subtask **API-1870** fetched with its 23 attachments (22 evidence PNG + the reviewer's screenshot) — the collection JSON attached 2026-09-04 19:35 was not listed by the tool at the time (format filter; fixed in `tools/jira-sync/jira_sync.py` this run).
- `jira_sync.py ready API-1738` → **READY**: label `TestCaseReady` present, matrix of **12 rows** in the subtask description (authoritative, PRC-105) — identical to the description's matrix. No comment retires a row; the 2026-09-02 comment by daniel.llano ("rows 8–9 need to be updated") predates the current matrix text, which already reflects the always-mask decision (rows 9–12).

### 0.1 Reading and classification
- **Requester / business owner:** Luis Alejandro Moreno Alvarez (VB). **QA contact:** hectorcervantes (test credentials in the 2026-08-27 comment — kept in the gitignored dump only). **Reviewer:** Marcin Nowak (nowakmarcin). **Assignee:** daniel.llano. **Tech lead helping on 2026-09-04:** guillermoplus (Luis) — pushed `feature/API-1738/display-passengers-changes-v3`.
- **Type of work:** modification of existing behavior (what the `DisplayPassengers` booking rule masks, and where) **+ configuration change** (new boolean `TreatContactEmailMatchAsSameAccount` in the shared `creationAccount` criteria block) **+ behavior extension** (unconditional email masking on three Account endpoints).
- **Rigor level: RISKY** (`../CLAUDE.md` table: *contract* — output field values change for every consumer of `GET /v1/Booking`, `/Full`, `/Search`, `GET /v1/Account`, `GET /v1/Account/Trips`, `POST /v1/Account/Trips/Add`; *flags* — a new Admin-Portal booking-rules toggle; privacy surface — a requested *reduction* of masking on passenger identity fields). "When in doubt, one level up." → `work/API-1738/HUMAN-GATE-REQUIRED` created; the human signs the Phase 5 plan by creating `HUMAN-GATE-OK`.
- **The "why" in one sentence:** when the DisplayPassengers rule denies, hide only what lets a stranger *contact* the passengers (emails, phones, a Customer creator's username) instead of blanking the whole passenger profile, and never expose a trip's contact email through the account views, because a trip can be linked to a profile by a match weaker than ownership.
- **Actors:** logged-in Customers (Manage / Check-in flows), non-Customer creators (Staff/Agency/Enterprise/CustomerAgent, whose usernames stay visible), web/mobile consumers of the six endpoints, Admin-Portal operators (new toggle), QA (matrix), DotRez (unchanged upstream; one extra projected field on the trips retrieve).
- **Observable outcome:** with the rule denying, the three booking endpoints return names/documents/nationality/etc. in clear and email/phones masked (`ToMaskedEmail`, phone = last 4 digits visible); a Customer creator's username is masked; a booking pending account verification is not masked; a Customer whose username equals the booking's primary contact email is treated as the same account when the toggle is on; the three account endpoints always return a masked primary contact email. Verified by the 12 matrix rows.

### 0.2 Definition of Ready — checklist
| Item | State |
|---|---|
| Problem described, not only the solution | ✅ Background section |
| Explicit acceptance criteria | ✅ 12-row matrix + Parts 1–4 + masking formats |
| UI mockups | n/a |
| API contract | ✅ "no shape change; string fields may carry masked values" (PR body) — consumers not listed in the ticket (assumption A7, Phase 4) |
| Test data / real cases | ✅ seed PNRs in the Postman collection (API-1870 attachment); QA credentials in comment 2026-08-27 |
| Dependencies identified | ✅ Admin-Portal document update after release (PR checkbox) |
| Estimated | ✅ 8d (7.2d logged) |
| Priority / business owner | ✅ VB (Luis Alejandro Moreno Alvarez) |
| Anti-scope stated | ⚠️ partially: account profile's own `contactDetails.emailAddress` out of scope (comment 2026-09-02) — recorded in Phase 5 anti-scope |
| Domain terms unambiguous | ✅ `DisplayPassengers`, `creationAccount`, `EnabledForTheSameAccount`, `bookingVerify` resolve in ApiLLM `documents/concepts/Booking.md` (masking §, Verify §) and `_meta/flags-and-rules.md` (BookingRules) — read from `origin/main` (see Phase 1 sync status) |

### 0.3 Literal request vs real need
- No reinterpretation. The six clarifications raised in review were answered by VB on 2026-09-02 (scope kept incl. Part 4; toggle name kept; Manage + Check-in; both `upcomingTrip` and `basket.travelSummary`; account APIs always mask; no per-PNR fan-out). The ticket description was updated to match (Part 4 lists Trips/Add and says "unconditional").
- The reviewer's suggestion to split Part 4 into another ticket was declined by VB (#1) — in scope.

### 0.4 Historical and organizational context
- Same area, recent: **API-1574** (`ShowChildCustomerNumber`, masking priority in `BookingPassengerOutputBuilder`, commit b40b03e10 — ApiLLM `Booking.md` "Masking priority"), **API-1670** (`GetActualPassengers`, 68 consumers), **API-1847/1849** (name matching rewrite in `LastNameValidator`, merged on master after this branch forked — semantic drift to re-test through retrieval by PNR + last name).
- Not attempted/reverted before. Three review rounds on PR #2484 (2026-09-02, 09-03, 09-04); the reviewer's standing objections are design churn between rounds and unanswered threads — the process cost this pipeline exists to avoid.
- Who else touches the area now: guillermoplus prepared `-v3` (rebase + 3 fix commits) on 2026-09-04; master moved 20 commits since the fork (1 textual conflict, whitespace-only on our side).

### Initial doubts (carried to Phase 4)
1. Final code = `-v3` content, squashed per the user's 2026-09-05 instruction (decision taken by the user).
2. Which build produced the 2026-09-04 18:40 evidence for rows 4–9 (user: other desktop) → all rows re-run with newman on the final commit anyway.
3. `BookingUserOutput.CreateFromBookingComment(…, bool maskContactData = false)` keeps a default (STY-05) — two other callers rely on it (Phase 2 R-05).

## Ticket comment (pending publication — posted with the delivery, P-14)

API-1738 — intake (Coder pipeline, adoption 2026-09-05). Classified as a modification of existing behavior + configuration change, rigor **risky** (contract values + new booking-rules toggle + privacy surface). Understanding: when DisplayPassengers denies, only contact data is masked (booking contacts' email/phones, passenger email/phone, Customer creator username); a booking pending account verification is exempt; a Customer whose username equals the booking's primary contact email counts as the same account when `TreatContactEmailMatchAsSameAccount` is on; `GET /v1/Account`, `GET /v1/Account/Trips` and `POST /v1/Account/Trips/Add` always mask the trip's primary contact email. VB's 2026-09-02 answers (1–6) are the closed decisions. Workspace: https://github.com/didierfrancogomez/VivaAerobus.Generic.ApiLLMCoder/tree/main/work/API-1738

PUBLICATION: pending

## Handoff

- `phase_status`: pass
- `highest_severity`: none
- `next_phase`: phase 01
- `blocking_reason`: n/a
- `required_inputs_for_next_phase`: ticket dump + snapshot; ApiLLM docs from `origin/main` (anchor e004bf9d); the `-v3` diff against master
- `evidence_paths`: `work/API-1738/ticket-snapshots/2026-09-04-2326.txt`; `tools/jira-sync/jira_tickets/Others/API-1870.txt` (+ `_attachments/`); `work/API-1738/continue-plan-2026-09-04.md`
- `delivery_state_updated`: yes
