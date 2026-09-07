# API-1738 — how to validate the bookingVerify exception (Part 3, matrix rows 7 and 8)

Code refs: `Concepts/_Shared/Booking/BookingVerificationProvider.cs :: IsVerificationRequired` (:29-70), `Concepts/_Shared/Booking/ContactDataMaskingProvider.cs` (:39-49), `Concepts/Booking/Verify/BookingVerifyHandler.cs` (:62-88), `Constants/BookingVerify.cs:5`.

## What the exception does

When the `DisplayPassengers` rule **denies**, the API normally masks contact data. Before masking, `ContactDataMaskingProvider` asks `IsVerificationRequired(booking, agent)` — the same check that decides whether the booking-verify action is offered. If the booking is still a **pending verification candidate**, nothing is masked. Once the booking is verified, the check returns false and the rule result applies again.

`IsVerificationRequired` is true only when **all** of these hold (each failure adds a message and disqualifies the booking):

| Condition | Where it comes from |
|---|---|
| `BookingVerify.enabled = true` | Admin Portal → BookingVerify |
| `Notifications.BookingNotifications.VerificationRequiredNotification.enabled = true` | Admin Portal → Notifications |
| viewer's account type ∈ `BookingVerify.enabledForAccountTypes` (or the list is empty) | BookingVerify |
| booking creator's organization matches `organizationCodeStartsWith` (or the list is empty) | BookingVerify + the booking's `sales.created` |
| booking has one of `enabledForSsrs` on a journey (or the list is empty) | BookingVerify |
| booking has **no** comment starting with `verifiedAccount:` | the booking itself — written by `POST /v1/Booking/Verify` |

The collection empties `enabledForAccountTypes` and `enabledForSsrs` so only three things matter during the test: the two `enabled` flags and the `verifiedAccount:` comment.

## Test data

| Variable | Value | Role |
|---|---|---|
| `api1738SeedAnonymousMatchingPnr` / `…LastName` | `MC4MXM` / `API04TEST` | anonymous booking whose primary contact email = the QA Customer's username → **pending candidate** (row 7) |
| `api1738SeedAnonymousVerifiedPnr` / `…LastName` | `SJ3ETH` / `API07TEST` | same kind of booking, **already verified** (carries `verifiedAccount:`) → row 8 |
| `api1738QaUsername` | QA Customer account | the viewer in both rows |

Rule configuration applied by the collection so that `DisplayPassengers` **denies** for this viewer: `enabledForAccountTypes = []`, `creationAccount.enabledForTheSameAccount = false`, `creationAccount.disabledForPassengerTypes = ["ADT"]`, `treatContactEmailMatchAsSameAccount = false` (the bookings have adult passengers, so the criteria fails → rule denies → masking would apply if not for the exception).

## Step by step — row 7 (pending candidate → nothing masked)

Collection folder **`TC07 - Pending verification`** (requests 01–11) does exactly this; run it in Postman Runner against `api1738BaseUrl` (local branch build `http://localhost:9050`, or the environment under test):

1. `01 Admin login` — `POST /v1/admin/token` with the Admin-Portal user → bearer for the config calls.
2. `02 Read BookingRules` — `POST /v1/admin/ConfigPartGetValues {"partName":"BookingRules"}`; the script keeps a copy for restoration and prepares the `DisplayPassengers` rule as above.
3. `03 Apply BookingRules` — `POST /v1/admin/ConfigPartSaveValues` with the prepared values and the current `version`.
4. `04 Read BookingVerify` — `POST /v1/admin/ConfigPartGetValues {"partName":"BookingVerify"}`; keeps a copy; sets `enabledForAccountTypes = []`, `enabledForSsrs = []` (leave `enabled = true`; check `Notifications → VerificationRequiredNotification.enabled = true` in the Admin Portal once — the collection does not touch it).
5. `05 Apply BookingVerify` — save.
6. `06 Login as Customer` — `POST /v1/account/login` with the QA Customer (its username equals MC4MXM's primary contact email).
7. `07 Evidence — GET /v1/booking/full?Pnr=MC4MXM&Lastname=API04TEST` (bearer = customer token). **Expected on the branch:** identity fields plain **and** every contact email/phone and passenger email/phone **plain** — the exception overrides the denied rule. The test "Response uses exactly one supported pending-verification contract" reports `CORRECTED` (on master it reports `LEGACY`: identity masked with `***`).
   Optional manual cross-check of the same evaluation: `GET /v1/booking/full` includes `notifications`; the `VerificationRequired` notification is present for this booking (it uses the same `IsVerificationRequired`).
8. `08–11` — restore the original BookingVerify and BookingRules values (read current version, save the saved copy).

Screenshot for evidence: the Runner result with request 07's response open, showing `contacts[0].email` / `passengers[0].emailAddress` in clear while the rule is configured to deny (Solution), versus the `***` identity fields on master (Issue).

## Step by step — row 8 (verified → masking applies again)

Folder **`TC08 - Completed verification`** (requests 01–15): same configuration steps 1–6, then

7. `07 Create basket` — `POST /v1/basket/create` (currency MXN, language es-MX, step Passengers).
8. `08 Load booking` — `POST /v1/basket/loadbooking {basketId, pnr: SJ3ETH, lastname: API07TEST, flowType: "Manage"}` → Manage flow, so `GET /v1/Booking` evaluates the rule.
9. `09` `GET /v1/booking?BasketId=…`, `10` `GET /v1/booking/full?Pnr=SJ3ETH&Lastname=API07TEST`, `11` `GET /v1/booking/search?pnr=SJ3ETH&lastName=API07TEST&includeVoucherDetails=true`. **Expected on the branch:** identity fields plain, contact emails masked (`a***@d***.com` style), phones with only the last 4 digits, `user.username` absent (anonymous creator). On master: identity `***`.
10. `12–15` — restore both config parts.

## If you need a fresh pending / verified pair

`MC4MXM` stays pending only while nobody verifies it. To create your own:

1. Create an **anonymous** booking (no login) whose primary contact email is the QA Customer's username, pay it in the test environment.
2. It is now a pending candidate (row 7) as long as the BookingVerify conditions above hold.
3. To turn it into the row-8 booking, log in as that Customer and call `POST /v1/Booking/Verify` `{"pnr":"<PNR>","lastName":"<last name>"}` (`[Authorize]`). The handler checks `IsVerificationRequired` and that the logged-in user's email equals the booking's primary contact email, then commits the booking with the `verifiedAccount:` comment (and links the trip to the profile when `Accounts.Trips.enabled`). From then on the exception no longer applies.
   Errors you may see: `GENERIC_VALIDATION_ERROR "Verification is not available for provided booking. <messages>"` — the messages list exactly which condition failed; `"Logged in user email doesn't match the contact email"` — wrong viewer.

## Where the collection is

`API-1738-Display-Passenger-Changes.postman_collection.json`, attached to **API-1870** (re-attached 2026-09-05; the link sits under "Postman Collection" in the subtask description). Local copy: `work/API-1738/attachments/…postman_collection.json` (gitignored — it carries the QA credentials as collection variables). Machine runs of TC07/TC08 on the branch and on master: `work/API-1738/attachments/evidence-runs/*-TC07-*`, `*-TC08-*`.
