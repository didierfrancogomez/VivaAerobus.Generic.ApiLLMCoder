# Phase 01 — Code contrast: API-1738 Display Passengers Changes

## Docs-sync status (opens the phase, mandatory)
- ApiLLM local checkout: branch `feat/sync-check-hardening-and-testing-scripts`, `documents/_meta/sync-state.md` anchored at **1431f135** → **STALE** vs code `origin/master`. Not touched (it is the user's tree).
- ApiLLM **`origin/main`** (fetched 2026-09-04): anchor **e004bf9d = code `origin/master` HEAD** → **CURRENT**. Every `documents/**` / `guidelines/**` citation below was read with `git show origin/main:<path>`.
- Code refs: **current state = `origin/master` e004bf9d8**; **implemented state = `origin/feature/API-1738/display-passengers-changes-v3` abe4bb5d8** (the content the user chose as final, Q1). Paths are relative to `VivaAerobus.Generic.Api/src/app/VivaAerobus.Generic.Api/`.

## Work

### 1.1–1.2 Current behavior at master (cited)
| Concern | Evidence |
|---|---|
| Where DisplayPassengers is evaluated | only `Concepts/Booking/GetBooking/ModelBuilders/BookingPassengerOutputBuilder.cs :: Build` :60-62 via `IManageAndCheckinRulesValidator.Validate<BookingOutput>(RuleType.DisplayPassengers, …)`; `maskData = error != null` (`git grep RuleType.DisplayPassengers` → 1 hit) |
| What it masks | :82-116 (adults) and :131-147 (infants): FirstName, LastName, Title, DateOfBirth, CustomerNumber, Affiliations, RedressNumber, KnownTravelerNumber, Nationality, ResidentCountry, HasMexicanResidencePermit, Passport, Visa, GreenCard, Destination, **Phone, EmailAddress** — all to `MASKED_DATA = "***"` (:39) or null. Child customer-number hide runs first (:87-89, `ShouldHideCustomerNumber`) — ApiLLM `documents/concepts/Booking.md` "Masking priority" |
| Booking contacts | `BookingContactsOutputBuilder.cs :: Build` :27-46 — email :38 and five phone types :42-46 returned **in clear**, no rule |
| Creation username | `BookingOutputBuilder.cs` :299 `User = … CreateFromBookingComment(booking) : BookingUserOutput.Create(agent, channel)` — username in clear for every account type |
| Same-account bypass | `Concepts/Booking/Rules/Criteria/Configurable/CreationAccountCriteria.cs :: Verify` :26-28: `EnabledForTheSameAccount && creationAccount.AgentCode == agent.UserName` → `return null` (rule passes) before the org/location/pax-type/agent checks (:30). No contact-email variant |
| Flow gating | `Concepts/Booking/Rules/Validation/ManageAndCheckinRulesValidator.cs :: Validate` :41-45 — returns **null (rule passes)** unless `HttpContext.GetFlowType()` (`Infrastructure/WebApi/HttpContextExtensions.cs` :111, from `Items`) is `Manage` or `CheckIn`. `GetFullBookingHandler.cs` :84 and `SearchBookingHandler.cs` :97 call `SetFlowType(FlowType.Manage)` themselves → **Full/Search always evaluate the rule**; `GetBookingHandler.cs` :94 uses `BuildBasketAware(basket, …)`, the flow comes from the basket (`LoadBookingHandler.cs` :84) → a **Booking-flow basket never masks** (matrix row 4 is pre-existing behavior). `AccountBookingsProvider.cs` :62 and `AccountTrips/_Shared/TripsBaseHandler.cs` :30 set `FlowType.Booking` → this validator can never deny on the account endpoints (root of the reviewer's "fake context" finding, T07) |
| Pending-verification evaluation | `Concepts/_Shared/Booking/BookingVerificationProvider.cs :: IsVerificationRequired` :29-70 — verification config enabled, notification enabled, agent type allowed, OTA org code, verification SSR present, **no `VERIFIED_BOOKING_COMMENT_PREFIX` comment** (:64-66). Same call used by `Booking/Verify/BookingVerifyHandler.cs` :62 (the verify action) and `VerificationRequiredNotification.cs` :34 → the ticket's "same evaluation already used to decide whether booking-verify is available" is **this method** |
| Email masking to reuse | `Infrastructure/Extensions/StringExtensions.cs :: ToMaskedEmail` :104 (callers: `_Shared/BookingComments/CancelComment.cs` :52, `IropCancelComment.cs` :37, `_Shared/Irop/Reimbursement/ReimbursementProvider.cs` :422-435) — the "IROP/Cancel-comment masking" named by the ticket. **No phone masking helper exists** |
| Account / trips email | `Account/GetAccount/ModelBuilders/AccountTripOutputBuilder.cs` :74 (`AccountTripOutput`, used for `upcomingTrip` via `AccountOutputBuilder.cs` :22,46 and for `basket.travelSummary` via `AccountBasketOutputBuilder.cs` :12-14) and `AccountTrips/_Shared/ModelBuilders/TripOutputBuilder.cs` :53 (used by `GetTrips/ModelBuilders/TripsOutputBuilder.cs` and `AddTrip/AddTripHandler.cs`) — `Email = booking.GetPrimaryContact()?.EmailAddress` **in clear** |
| Why the trips list never had an email | `AccountTrips/GetTrips/DotRezApi/RetrieveBookingsRequest.cs` :74-80 projects `contactTypeCode`, `name`, `emailAddress` but **not `distributionOption`**, while `Integration/DotRezApi/Extensions/Booking.cs :: GetContact` :39-45 filters `DistributionOption == Email && ContactTypeCode == …` → `GetPrimaryContact()` is null on the light retrieve → `Email` was **null** on `GET /v1/Account/Trips` |
| Config surface | `Configuration/Parts/BookingRulesConfigPart.cs` :172-174 `CreationAccountCriteriaConfig { EnabledForTheSameAccount, … }`, held by every rule config (:92); schema `Concepts/Admin/ConfigPart/Schema/BookingRulesConfigPartSchema.cs` :177-182; seed `Assets/Seed/AdminPortal/SettingsDocuments/BookingRules.json` — 20 rule entries each with a `creationAccount` block (DisplayPassengers entry :1014-1062, `enabledForTheSameAccount: false`) — ApiLLM `_meta/flags-and-rules.md` §BookingRules |

### 1.3 Archaeology
- Masking of the whole passenger block dates from the original DisplayPassengers rule; API-1574 (b40b03e10) added the child customer-number precedence. API-1670 moved passenger reads to `GetActualPassengers()` (used at :74 here). Nothing in the history documents *why* identity fields were masked — the ticket's Background states the business now wants only contact data protected.

### 1.4 Discrepancies — requested vs current vs implemented (-v3)
| # | Requested (ticket) | Current (master) | Implemented on -v3 (cited) | Status |
|---|---|---|---|---|
| D-01 | Part 1: mask only booking-contact email & phones (all contact types), passenger email & phone, Customer creator username | 20 passenger fields masked; contacts and username never masked | `BookingPassengerOutputBuilder.cs` :85-86 masks only Phone/EmailAddress, identity fields in clear (:58-84, :101-114 infants); `BookingContactsOutputBuilder.cs` :15 `Build(booking, bool maskContactData)`, :39 email, :43-47 + :54-59 phones; `BookingOutput.cs` :147-156 `Create(agent, channel, bool)`, :159-171 `CreateFromBookingComment(booking, bool = false)`, :175-178 `MaskUsernameForCustomerAccount` (Customer only) | ✅ |
| D-02 | Decision made once, reused by the three endpoints | rule evaluated inside the passengers builder | `Concepts/_Shared/Booking/ContactDataMaskingProvider.cs` (new, 54 lines): :39-41 `IManageAndCheckinRulesValidator.Validate(DisplayPassengers…)`, :43-44 pass → false, :47-49 `!IsVerificationRequired`; consumed once in `BookingOutputBuilder.cs` :295 and passed down :296-298 (user), :322-324 (passengers), :326 (contacts); registered `Infrastructure/Ioc/ConceptsSharedRegistry.cs` :463 | ✅ (reviewer's option 2, T19) |
| D-03 | Part 2: `TreatContactEmailMatchAsSameAccount` (default false), second OR bypass before the restriction checks, Customer viewer whose UserName == primary contact email | only creator-match bypass | `CreationAccountCriteria.cs` :31-32 bypass after the existing one, before `Verify` (:34); `IsContactEmailTheSame` :50-58 (Customer only, `GetPrimaryContact()?.EmailAddress`, case-insensitive); config `BookingRulesConfigPart.cs` :175; schema :184-187 (description text); seed: `"treatContactEmailMatchAsSameAccount": false` added to all 20 entries | ✅ |
| D-04 | Part 3: pending-verification candidate never masked; stops after verification | no exception | provider :47-49 uses `IsVerificationRequired` (same method as the verify action, see 1.2); a `VERIFIED` comment makes it return false → masking resumes | ✅ |
| D-05 | Part 4: `GET /v1/Account` (upcomingTrip + basket.travelSummary), `GET /v1/Account/Trips`, `POST /v1/Account/Trips/Add` mask the primary contact email **unconditionally** | in clear (and null on the trips list) | `AccountTripOutputBuilder.cs` :75-77 `…EmailAddress.ToMaskedEmail()` (both account paths share this builder); `TripOutputBuilder.cs` :53-55 same, `maskContactData` parameter removed → `AddTripHandler.cs` :52, `TripsOutputBuilder.cs` :41; `RetrieveBookingsRequest.cs` :77 `distributionOption` projected so the primary contact resolves | ✅ |
| D-06 | Email format = IROP/Cancel-comment masking | — | `ToMaskedEmail` reused (:104) | ✅ |
| D-07 | Phone format = last 4 digits visible, rest `*` | none | `StringExtensions.cs :: ToMaskedPhone` :123-146: masks every digit except the last four, keeps non-digits (`+`, spaces); a phone with ≤4 digits is returned unchanged | ✅ (edge noted as assumption A8) |
| D-08 | GET /Booking gated to Manage/Check-in; Full/Search not flow-restricted | pre-existing (1.2 "Flow gating") | unchanged — provider reuses `IManageAndCheckinRulesValidator` | ✅ no change needed |
| D-09 | Reviewer T12/STY-05: no unnecessary defaults | — | `CreateFromBookingComment(…, bool maskContactData = false)` keeps a default; two other callers rely on it: `Booking/_Shared/Notifications/BookingNotificationsProvider.cs` :172, `Hardcoded/PaxDataCollectorFormNotification.cs` :52 | ⚠️ load-bearing default → keep; explain in the PR reply (Phase 2 R-05) |
| D-10 | PR body must describe the final code | says trips retrieval is "full-booking, sequential" | fan-out removed on 2026-09-02; Trips/Add now in scope | ⚠️ PR description update (P-13) |
| D-11 | Docs | ApiLLM `Booking.md` describes the 20-field masking; `Account.md` has no masking; `flags-and-rules.md` lacks the toggle | — | ⚠️ stale after merge → Phase 11 doc-sync (never written here) |

### Verification of the ticket's reuse assumptions
- "plugs into the same evaluation point the creator-match bypass uses" → `CreationAccountCriteria.cs :: Verify` :26-32 ✅.
- "same evaluation already used to decide whether booking-verify is available" → `BookingVerificationProvider.IsVerificationRequired`, shared with `BookingVerifyHandler.cs` :62 ✅.
- "reuse IROP/Cancel-comment email masking" → `ToMaskedEmail` ✅.

## Ticket comment (pending publication)
Not posted separately — folded into the delivery comment (P-14).

PUBLICATION: pending

## Handoff
- `phase_status`: pass
- `highest_severity`: P3 (D-09 default parameter explanation; D-10 PR text; D-11 doc staleness — none blocks)
- `next_phase`: phase 02
- `blocking_reason`: n/a
- `required_inputs_for_next_phase`: symbol list above; ApiLLM `documents/cross-module/dependency-map.md` (origin/main)
- `evidence_paths`: `git -C ../VivaAerobus.Generic.Api diff origin/master...origin/feature/API-1738/display-passengers-changes-v3` (790 lines, 14 files)
- `delivery_state_updated`: yes
