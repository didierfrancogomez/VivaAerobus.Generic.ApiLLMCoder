## Code review — API-1738 Display Passengers Changes (process/REVIEW-CODE.md, local validator)
**Verdict:** ✅ APPROVED — every acceptance criterion maps to code; no 🐛/❗ finding; two ✋ observations justified below.
**Docs sync:** ApiLLM `origin/main` anchor `e004bf9d` vs code base `origin/master` `e004bf9d8` — in sync (local ApiLLM checkout STALE at 1431f135, not used).
**Reviewed:** `feature/API-1738/display-passengers-changes` @ **1e65eb8a3** (1 commit on top of `origin/master`; tree identical to `origin/…-v3`) · `git diff origin/master...HEAD` · 14 files, +214/−87 · guidelines loaded (STY 15 / ARC 31 / ROB 23 / PRC 26 from `origin/main`).

### Purpose alignment
| Acceptance criterion (ticket) | Implemented by | Status |
|---|---|---|
| Part 1 — only contact data masked when DisplayPassengers denies: booking contacts email + phones (all types) | `Concepts/Booking/GetBooking/ModelBuilders/BookingContactsOutputBuilder.cs:15,39,43-47,54-59` | ✅ |
| Part 1 — passenger-level email + phone masked, identity fields in clear | `BookingPassengerOutputBuilder.cs:58-86` (adults), `:101-114` (infants) — `MASKED_DATA`, `Array.Empty` affiliations, null DoB/documents removed | ✅ |
| Part 1 — creation username masked only for Customer creators | `Concepts/_Shared/Models/Output/BookingOutput.cs:147-156,159-171,175-178` (`MaskUsernameForCustomerAccount`) | ✅ |
| Decision taken once, shared by GET /Booking, /Full, /Search | `Concepts/_Shared/Booking/ContactDataMaskingProvider.cs:10-19,21-53`; consumed `BookingOutputBuilder.cs:295` and passed down `:296-298,322-324,326`; registration `Infrastructure/Ioc/ConceptsSharedRegistry.cs:463` | ✅ |
| Flow gating: GET /Booking Manage/Check-in only; Full/Search evaluate always | pre-existing `ManageAndCheckinRulesValidator.cs:41-45` (untouched) + `GetFullBookingHandler.cs:84` / `SearchBookingHandler.cs:97` `SetFlowType(Manage)` | ✅ no change needed |
| Part 2 — `TreatContactEmailMatchAsSameAccount`, default false, OR-bypass before restrictions, Customer viewer username == primary contact email | `Concepts/Booking/Rules/Criteria/Configurable/CreationAccountCriteria.cs:31-32,50-58`; `Configuration/Parts/BookingRulesConfigPart.cs:175`; `Concepts/Admin/ConfigPart/Schema/BookingRulesConfigPartSchema.cs:184-187`; seed `Assets/Seed/AdminPortal/SettingsDocuments/BookingRules.json` ×20 `false` | ✅ |
| Part 3 — pending-verification candidate not masked; resumes after verification | `ContactDataMaskingProvider.cs:47-49` via `IBookingVerificationProvider.IsVerificationRequired` (same method as `BookingVerifyHandler.cs:62`) | ✅ |
| Part 4 — GET /Account (upcomingTrip + basket.travelSummary), GET /Account/Trips, POST /Account/Trips/Add mask the primary contact email unconditionally | `Concepts/Account/GetAccount/ModelBuilders/AccountTripOutputBuilder.cs:75-77`; `Concepts/AccountTrips/_Shared/ModelBuilders/TripOutputBuilder.cs:53-55` (no flag; both callers `TripsOutputBuilder.cs:41`, `AddTripHandler.cs:52` untouched vs master); `Concepts/AccountTrips/GetTrips/DotRezApi/RetrieveBookingsRequest.cs:77` `distributionOption` | ✅ |
| Email format = IROP/Cancel-comment masking | `StringExtensions.ToMaskedEmail` reused (`:104`) | ✅ |
| Phone format = last 4 digits visible | `Infrastructure/Extensions/StringExtensions.cs:123-146` `ToMaskedPhone` | ✅ |

Scope creep: **none**. Every hunk maps to a criterion or to a reviewer comment (T01, T03, T04, T11–T14, T17–T20). `ShowChildCustomerNumber` evaluation moved from the passengers builder to `BookingOutputBuilder.cs:300-302` — consequence of removing the validator from the passengers builder (T19 option 2), behaviour unchanged (`showChildCustomerNumber` still passed, `ShouldHideCustomerNumber` first at `:66`).

### Blocking findings (🐛/❗)
None.

### Non-blocking findings (🏭/✋ — fix or justify before the human PR)
1. ✋ STY-05 · `Concepts/_Shared/Models/Output/BookingOutput.cs:159` — `CreateFromBookingComment(…, bool maskContactData = false)` keeps a default. **Justified, not fixed:** `Booking/_Shared/Notifications/BookingNotificationsProvider.cs:172` and `Hardcoded/PaxDataCollectorFormNotification.cs:52` call it without the flag and must keep the unmasked username; removing the default means editing two notification files outside the reviewer's asks (PRC-97). Stated in the reply to T12; the reviewer can ask for explicit `false` at both call sites.
2. ✋ STY-08 · `AccountTripOutputBuilder.cs:75-76`, `TripOutputBuilder.cs:53-54`, `ContactDataMaskingProvider.cs:47` — three rationale comments. **Kept on purpose:** the reviewer explicitly approved the first one (T17 "this comment makes sense here") and asked for the behaviour to be documented; they explain a business decision, not the code mechanics.

### Observations (no rule — never block)
- `ToMaskedPhone` returns a phone with ≤4 digits unchanged (`:128-130`) — consistent with "last 4 digits visible"; a 4-digit extension would show in clear. Documented as assumption A8.
- `GET /v1/Account/Trips` `email` changes from `null` to a masked value (the light retrieve now projects `distributionOption`). Behaviour change for consumers that relied on null — stated in the PR text (R-10).
- Sonar reported "1 New issue" on ea9817aa4 (the content minus the two lines fixed in 1e65eb8a3). The rule/file is not readable from this machine (auth); the re-analysis after the push settles it (PRC-38 must be green before re-requesting review).

### Functional correctness (ROB) walk
- Null paths: `booking.GetPrimaryContact()?.EmailAddress.ToMaskedEmail()` — extension handles null (`ToMaskedEmail` returns input when empty per existing implementation; `ToMaskedPhone` guards `IsNullOrEmpty` `:125`). `contactAddress?.Phone.ToMaskedPhone()` idem. `agent?.AgentTypeCode != Customer` short-circuits before `agent.UserName` (`CreationAccountCriteria.cs:52-57`).
- Failure paths: no new external calls; `IsVerificationRequired` reads admin config only. No new error codes.
- Rule engine: bypass runs only when the toggle is true (`:31`), after the existing creator match (`:27-29`), before `Verify` (`:34`) — ordering matches the ticket.

### Blast radius (Phase 2 matrix R-01…R-17 re-checked on the final diff)
- Only callers of changed signatures are inside the diff (`git grep` at HEAD); `BookingUserOutput.CreateFromBookingComment` extra callers rely on the kept default. DI: one explicit registration. Config: schema/part/seed 1:1 (ARC-95, PRC-37). Contract: no shape change; values change as requested. In-flight baskets unaffected.

### Design & architecture (ARC)
- Provider in `_Shared/Booking` (ARC-10/14), interface + singleton registration (ARC-11/12), builders receive booleans (ARC-46), `ToMaskedEmail` reused (ARC-63), all rule usage points updated (ARC-90). No `new` of services, no domain-model logic added beyond factory methods on the output DTO.

### Style (STY)
- Naming per T03; no dead code; EOF newlines restored (f2b962b36); constant `UNMASKED_PHONE_DIGITS` (STY-02); `static` helpers (STY-91); early returns (STY-93).

### Tests
- No NUnit spec references the changed types (grep over `src/tests`), so nothing to update; no new unit tests (PRC-94 — no agreement with VB). Acceptance coverage: the 12-row Postman matrix (Phase 7, S-01…S-12) + full suite S-13.

### Security & data
- No secrets, no new logs; masking reduction on identity fields is the ticket's explicit request (PR privacy checkbox deliberately unticked and explained).

### Process & delivery (PRC)
- One commit, ticket key + gitmoji + why (PRC-102/PRC-31); rebased on master (PRC-32); release notes + Admin-Portal flag (PRC-36/96); PR title to be rewritten by hand (PRC-103, P-12); Sonar QG to re-verify after push (PRC-38).
