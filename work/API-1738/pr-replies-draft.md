# PR #2484 — draft replies (P-12). DRAFTS ONLY — posted after PUSH-APPROVED, never resolving threads.

`<SQUASH>` = the final squashed commit (P-04b). Citations: VB = Luis Alejandro Moreno Alvarez, Jira API-1738 comment 2026-09-02 (answers 1–6).

| Thread | Reply |
|---|---|
| T01 (BookingOutput.cs, `AccountType` helper) | Done in `<SQUASH>`: the helper is gone; `BookingUserOutput.Create(agent, channel, maskContactData)` and `CreateFromBookingComment(booking, maskContactData)` receive the flag and decide inside (`MaskUsernameForCustomerAccount`, Customer only). |
| T02 (toggle name) | Asked VB (Jira, 2026-09-02, point 2). Answer: keep `TreatContactEmailMatchAsSameAccount` as described in the ticket. Name unchanged. |
| T03 (rename to `IsContactEmailTheSame`) | Renamed in `<SQUASH>` (`CreationAccountCriteria.IsContactEmailTheSame`). |
| T04 (`agent.UserName` never null) | Removed the null/empty check on `agent.UserName` in `<SQUASH>`; the method only checks the account type and the primary contact email. |
| T05 (flow scope) | Asked VB (2026-09-02, point 3). Answer: Manage and Check-in only. That is the existing `ManageAndCheckinRulesValidator` gating, so `GET /v1/Booking` follows the basket flow and `/Full` and `/Search` set Manage themselves — no change needed. |
| T06 (upcomingTrip vs travelSummary) | Asked VB (2026-09-02, point 4). Answer: both. `AccountTripOutputBuilder` serves both paths and masks unconditionally in `<SQUASH>`. |
| T07 (fake currency/IROP context) | Asked VB (2026-09-02, point 5): "always mask information on account APIs (no matter booking rule)". The rule is no longer evaluated on account endpoints, so the fake context is gone (`<SQUASH>`). |
| T08 (GetBookingRequest fan-out) | Asked VB (2026-09-02, point 6): keep the scope of point 5. The per-PNR `GetBookingRequest` is removed; `RetrieveBookingsRequest` now projects `contacts.value.distributionOption` so the primary contact resolves from the light retrieve (`<SQUASH>`). |
| T09 (TripsOutputBuilder passing `true`) | Moot in `<SQUASH>`: the `maskContactData` parameter is gone from `ITripOutputBuilder.Build`; the email is masked unconditionally inside the builder. |
| T10 (`agent` never null in TripOutputBuilder) | Moot in `<SQUASH>`: that code path no longer exists (unconditional masking, no agent check). |
| T11 (BookingContactsBuildResult, upstream decision) | You were right; that change had no reason. `<SQUASH>` restores the round-1 structure: `IContactDataMaskingProvider.ShouldMaskContactData` is resolved once in `BookingOutputBuilder` and the boolean is passed downstream to the contacts, passengers and user builders. `BookingContactsBuildResult` is gone. |
| T12 (default `basket = null`) | Removed from the provider in `<SQUASH>`. One default remains, on `CreateFromBookingComment(booking, bool maskContactData = false)`: `BookingNotificationsProvider` :172 and `PaxDataCollectorFormNotification` :52 call it without the flag and must keep the unmasked username, so the default is load-bearing there. Happy to pass `false` explicitly at both call sites instead if you prefer. |
| T13 (`[UsedImplicitly]`) | Removed in `<SQUASH>`; the provider is registered explicitly. |
| T14 (registration location) | Moved to the shared block of `ConceptsSharedRegistry` (`ForSingletonOf<IContactDataMaskingProvider>()` next to the other `_Shared/Booking` registrations) in `<SQUASH>`. |
| T15 (`AccountBookingsProvider.cs` noise) | Reverted in `<SQUASH>`; the file is no longer in the diff. |
| T16 (`GetTripsHandler.cs` noise) | Reverted in `<SQUASH>`; the file is no longer in the diff. |
| T17 (👍 comment) | Kept, and the same rationale comment now sits on the trips builder too. |
| T18 (Trips/Add) | Confirmed: VB's point 5 covers every account API and the ticket's Part 4 now lists `POST /v1/Account/Trips/Add` explicitly ("masking on these three endpoints is unconditional"). `<SQUASH>` removes the `maskContactData` parameter and masks the email in `TripOutputBuilder` for both the trip list and Trips/Add. Sorry for leaving this one unanswered in the previous round. |
| T19 (`ManageAndCheckinRulesValidator` misuse) | Your option 2. `<SQUASH>` restores `ContactDataMaskingProvider` as it was in round 1 (rule via `IManageAndCheckinRulesValidator` + the pending-verification exemption) and leaves `ManageAndCheckinRulesValidator` untouched — it is back to master. |
| T20 (`ConceptsSharedRegistry.cs` noise) | Reverted in `<SQUASH>`; the only change in the file is the one registration line. |

## PR summary comment (Tech Lead's wording — post verbatim once every statement is true; see phase-05 P-12)

Thanks for the patience on this one. Three rounds in, the pattern is on me. I changed an approach you had accepted, I left a comment unanswered, and I pushed formatting noise twice, because I committed changes without reviewing them properly myself. That stops here.

Final design, and it stays. `ContactDataMaskingProvider` decides once in `BookingOutputBuilder` and the boolean goes down to the contacts, passengers and user builders, your option 2. `ManageAndCheckinRulesValidator` is untouched.

What changed since the commit you reviewed last

- The branch is rebased on the current master. The only conflict was a whitespace-only change of mine in `BasketTravelChargesOutputBuilder`, which is dropped, so that file is no longer part of the PR.
- `POST /v1/Account/Trips/Add` now masks the email as well, through the same builder as the trip list and with no flag. VB made it explicit in the ticket today.
- The rationale comments are back, the end-of-file formatting matches the repo again, and the unused default on `BookingUserOutput.Create` is removed.

Two deliberate differences from the first-round version, in case they stand out. `ShowChildCustomerNumber` is evaluated in `BookingOutputBuilder` so the passengers builder no longer needs the validator, and `RetrieveBookingsRequest` projects `distributionOption`. Without it the trip list never resolved the primary contact, so that email now comes back masked instead of empty.

All 12 test cases from the ticket matrix were re-executed on the final commit. The PR description is updated to match the final code. Every open thread has an answer, I'm leaving them for you to resolve.

## Truth checklist for the summary (tick before posting)
- [ ] rebased on current master (P-04b: `git rev-list --count HEAD..origin/master` = 0)
- [ ] `BasketTravelChargesOutputBuilder.cs` not in `git diff origin/master...HEAD --name-only`
- [ ] Trips/Add masks with no flag (`AddTripHandler.cs:52`)
- [ ] comments back, EOF formatting, `Create` default removed (diff)
- [ ] all 12 rows re-executed on the final commit (phase-07: S-01…S-12 newman on `<SQUASH>`)
- [ ] PR description updated (P-12)
- [ ] all 20 threads answered (this file posted)
