# Phase 02 — Impact radius: API-1738 Display Passengers Changes

Docs: ApiLLM `origin/main` (anchor e004bf9d, CURRENT; local checkout STALE — not used). Code: `origin/master` e004bf9d8 vs `origin/feature/API-1738/display-passengers-changes-v3` abe4bb5d8. Paths relative to `VivaAerobus.Generic.Api/src/app/VivaAerobus.Generic.Api/`. Callers found with `git grep` on the -v3 tree over `src/` (app **and** tests).

## Work — impact matrix

| # | What moves | Evidence (callers / consumers) | Kind | Risk | Addressed by / tested by |
|---|---|---|---|---|---|
| R-01 | `BookingOutput` values on **`GET /v1/Booking`, `GET /v1/Booking/Full`, `GET /v1/Booking/Search`** | `IBookingOutputBuilder` consumers: `Booking/GetBooking/GetBookingHandler.cs` :94, `Booking/Full/GetFullBookingHandler.cs` :132, `Booking/Search/SearchBookingHandler.cs` :158 (grep at master) | contract **values** (shape unchanged): identity fields now clear when the rule denies; `contacts[].email`, `contacts[].phoneNumbers.*`, `passengers[].emailAddress/phone`, `user.username` (Customer) now carry masked strings | HIGH (every web/mobile consumer) | requested by the ticket (Parts 1–3); PR body "breaking changes" paragraph; S-01…S-08 |
| R-02 | `IBookingPassengersOutputBuilder.Build` signature (−agent/currency/basket/irop/paymentPlan, +`maskContactData`, +`showChildCustomerNumber`) and ctor (−validator) | single caller `BookingOutputBuilder.cs` :322-324; no test references (`grep` over `src/tests`: none); registered by scan convention (`[UsedImplicitly]`) | internal API | LOW | compile (P-04b build), S-01/S-02 |
| R-03 | `IBookingContactsOutputBuilder.Build(booking, bool)` | single caller `BookingOutputBuilder.cs` :326 | internal API | LOW | compile, S-02 |
| R-04 | New `IContactDataMaskingProvider` injected into `BookingOutputBuilder` | explicit registration `Infrastructure/Ioc/ConceptsSharedRegistry.cs` :463 (ARC-12) | DI | LOW | app start (P-08), S-01 |
| R-05 | `BookingUserOutput.Create(agent, channel, bool)` (default removed) / `CreateFromBookingComment(booking, bool = false)` | `Create`: only `BookingOutputBuilder.cs` :298. `CreateFromBookingComment`: `BookingOutputBuilder.cs` :297 (passes the flag), **`Booking/_Shared/Notifications/BookingNotificationsProvider.cs` :172** and **`Hardcoded/PaxDataCollectorFormNotification.cs` :52** (no flag → username unmasked, unchanged behavior) | shared model | LOW — the default is load-bearing for two notification callers; removing it means touching two files outside the reviewer's asks (PRC-97) | decision: keep the default; explain in the reply to T12 (Phase 5 anti-scope) |
| R-06 | `CreationAccountCriteria.Verify` gains the second bypass | criteria evaluated for **every** `BookingRules` rule entry carrying a `creationAccount` block (`BookingRulesConfigPart.cs` :92, 20 seed entries) | rule engine | MEDIUM — but gated by `TreatContactEmailMatchAsSameAccount` (default `false`, seeded false ×20) → no behavior change until an operator enables it per rule | S-05/S-06 (toggle on/off); PRC-37 seed+schema |
| R-07 | Config part + schema + seed | `BookingRulesConfigPart.cs` :175, `BookingRulesConfigPartSchema.cs` :184-187, `BookingRules.json` ×20 (ARC-95 1:1 kept) | configuration / data | LOW — stored Admin documents without the key deserialize to `false` (C# default; `AdminPortalDatabaseSeeder` skips existing docs — ApiLLM `_meta/sync-state.md` 2026-09-04 note); no migration; Admin-Portal manual step flagged (PR checkbox, PRC-96; release notes present, PRC-36) | S-05 exercises the toggle via `admin/ConfigPartSaveValues` |
| R-08 | `StringExtensions.ToMaskedPhone` (new) / `ToMaskedEmail` (reused) | `ToMaskedPhone`: callers only in the two booking builders; `ToMaskedEmail`: existing callers `CancelComment.cs` :52, `IropCancelComment.cs` :37, `ReimbursementProvider.cs` :422-435 untouched | shared infra | LOW | S-02 (formats) |
| R-09 | **`GET /v1/Account`** (`upcomingTrip.email`, `basket.travelSummary.email`), **`GET /v1/Account/Trips`**, **`POST /v1/Account/Trips/Add`** — primary contact email always masked | `AccountTripOutputBuilder` ← `AccountOutputBuilder.cs` :22,46 and `AccountBasketOutputBuilder.cs` :12-14; `TripOutputBuilder` ← `TripsOutputBuilder.cs` :41, `AddTripHandler.cs` :52 | contract **values** | MEDIUM (consumers of the account views) | VB decision #5 (2026-09-02); S-09…S-12 |
| R-10 | `RetrieveBookingsRequest` projects `distributionOption` | `Account/_Shared/AccountBookingsProvider.cs` :105 → used by `GetAccountHandler.cs` and `GetTripsHandler.cs`; `GetContact` filter (`Integration/DotRezApi/Extensions/Booking.cs` :43) now resolves the primary contact | DotRez projection / behavior | LOW-MEDIUM — `GET /v1/Account/Trips` `email` was **null** before and is now a masked value (a consumer that relied on null changes behavior); one extra scalar per contact in the GraphQL payload | stated in the PR ("that email now comes back masked instead of empty"); S-10 |
| R-11 | Runtime cost | per booking output: one rule validation (already existed) + one `IsVerificationRequired` (in-memory admin config + comment scan) only when the rule denies; account endpoints: no rule evaluation, no extra DotRez calls (fan-out removed on 2026-09-02) | non-functional | LOW | PR body performance note revised (P-13) |
| R-12 | Automated tests | `src/tests/VivaAerobus.Generic.Api.Tests` (54 `*_specs.cs`): none reference `BookingPassengersOutputBuilder`, `BookingContactsOutputBuilder`, `TripOutputBuilder`, `AccountTripOutputBuilder`, `CreationAccountCriteria`, `BookingUserOutput`, `StringExtensions`, `RetrieveBookingsRequest` (grep) → compile-safe; no new unit tests (PRC-94 — none agreed with VB); acceptance via the 12-row Postman matrix | tests | LOW | S-13 full suite green |
| R-13 | Semantic drift from master since fork (20 commits) | ApiLLM `dependency-map.md` §`ILastNameValidator` (row "HIGH"): retrieval by PNR + last name rewritten (API-1847/1849) — used by `/Full`, `/Search`, `Basket/LoadBooking`, `AccountTrips/AddTrip` which every evidence row drives; `BasketTravelChargesOutputBuilder.cs` rewritten (API-1711) — our whitespace touch dropped; `Search.json` seed + `SearchConfigPartSchema` new `NameConnectors` | integration | MEDIUM | all 12 rows re-run on the rebased final commit (S-01…S-12) + S-13 |
| R-14 | Notifications / emails | `BookingUserOutput.CreateFromBookingComment` callers in notifications keep the unmasked username (R-05) — no change | side effect | none | — |
| R-15 | Logging / PII | no new log statements in the diff; masked values only in responses | observability | none | — |
| R-16 | Security / privacy | requested reduction of masking on identity fields (ticket Background) — PR privacy checkbox deliberately unticked and explained | privacy | accepted by VB | PR body kept |
| R-17 | Documentation | ApiLLM `documents/concepts/Booking.md` (masking §), `Account.md` (trips), `_meta/flags-and-rules.md` (creationAccount) become stale after merge | docs | — | Phase 11 `doc-sync` |

## 2.2 Contracts and integrations
- No endpoint, route, request field, response field or type changes (verified on the -v3 diff: `*Output` classes gain no members; `BookingUserOutput.Create*` are factories).
- DotRez: +1 projected field on `RetrieveBookingsRequest` (GraphQL); no new requests.

## 2.3 Data
- No persistence change. Admin documents: new optional boolean, default false (R-07). Seeds only reach fresh environments; the Admin-Portal manual step covers existing ones.

## 2.4 Non-functional — see R-11.

## 2.5 Operational
- Kill switch for Part 2: the toggle itself (default off). Parts 1/3/4 have **no** switch — a rollback is a revert of the PR (Phase 8 / plan §Rollout).

## Ticket comment (pending publication)
Folded into the delivery comment (P-14).

PUBLICATION: pending

## Handoff
- `phase_status`: pass
- `highest_severity`: P2 (R-10 null→masked value on the trips list must be stated to consumers — it is, in the PR text)
- `next_phase`: phase 03
- `blocking_reason`: n/a
- `required_inputs_for_next_phase`: this matrix; ticket Parts 1–4; VB answers 1–6
- `evidence_paths`: `git -C ../VivaAerobus.Generic.Api grep -n <symbol> origin/feature/API-1738/display-passengers-changes-v3 -- VivaAerobus.Generic.Api/src`
- `delivery_state_updated`: yes
