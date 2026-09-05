# PR #2484 — description draft (P-12). Title stays: `API-1738 ✨ Limit DisplayPassengers masking to contact data and extend creationAccount` (PRC-103; current title "feature/API-1738/Display Passengers masking changes" is branch-derived and gets replaced).

## About

API-1738 changes what the `DisplayPassengers` booking rule masks. Previously a failed rule evaluation masked the whole passenger block (names, documents, nationality, customer number, addresses, contact data). Now the affected booking responses mask **contact data only** — booking contacts' email and phone numbers (all contact types), passenger-level email and phone — and the creation username when the creator is a **Customer** account; usernames of Staff, Agency, Enterprise and Customer-Agent creators stay visible. Email masking reuses the existing protected-email format; phone masking keeps only the last four digits.

The decision is taken once per booking output by `ContactDataMaskingProvider` (`Concepts/_Shared/Booking`) and passed down to the contacts, passengers and user builders. A booking that is still a pending candidate for account verification (the same evaluation the booking-verify action uses) is not masked; once verified, the normal rule result applies again. `ManageAndCheckinRulesValidator` is unchanged, so `GET /v1/Booking` follows the basket flow (masking applies in Manage and Check-in only) while `GET /v1/Booking/Full` and `GET /v1/Booking/Search` keep evaluating the rule as before.

The shared `creationAccount` criteria gain `TreatContactEmailMatchAsSameAccount` (default `false`). When enabled on a rule, a logged-in Customer whose username equals the booking's primary contact email is treated as the same account, independently of who created the booking — a second OR condition next to the existing creator match, evaluated before the organization/location/passenger-type/agent restrictions.

`GET /v1/Account` (`upcomingTrip` and `basket.travelSummary`), `GET /v1/Account/Trips` and `POST /v1/Account/Trips/Add` mask the trip's primary contact email **unconditionally**, without evaluating the rule (VB decision, ticket 2026-09-02). A trip can be linked to a profile by a match weaker than ownership, so the account views never expose that email. `RetrieveBookingsRequest` now projects `contacts.value.distributionOption`; without it the primary contact never resolved on the trip list, so that email comes back masked instead of empty. No per-PNR booking retrieval is added.

There are no endpoint, request, response-shape or data-type changes. Existing string fields may carry masked values where the rule fails; consumers reading `contacts[].email`, `contacts[].phoneNumbers.*`, `passengers[].emailAddress`/`phone` or `user.username` should expect masked content, not a changed shape. Existing `EnabledForTheSameAccount` behavior is untouched.

### How to test (PRC-100)
Postman collection `API-1738-Display-Passenger-Changes.postman_collection.json` attached to API-1870 (11 folders → the 12 matrix rows; TC09 covers rows 9 and 10). Each folder applies the exact `BookingRules`/`BookingVerify` configuration through `admin/ConfigPartSaveValues`, runs the evidence requests against `{{api1738BaseUrl}}` (local :9050) and restores the previous configuration. Rows 1–3, 5–8 use Customer/Staff logins and pre-generated PNRs; rows 9–12 use the QA Customer account's trips.

## Checklist

- [ ] This code change has breaking changes in our api
- [x] Admin portal changes need to be done manually after the release (structure or other changes)
- [x] This code change does not compromise or affect in any way current PCI-certified endpoints, including and not limited to the payment process endpoint.
- [ ] This code change does not compromise the privacy of Viva Aerobus customers by exposing or manipulating sensitive customer/user information outside the VivaAerobus infrastructure or by increasing the risk of this data being accessible by unauthorized users. Sensitive data includes names, date of birth, gender, contact information, and geolocation.
- [ ] This code change might affect the performance of some endpoints. Monitoring is recommended.

**Privacy checkbox — left unticked deliberately.** The ticket asks for a reduction in masking: passenger names, date of birth, travel documents, nationality, resident country, customer number and destination address were masked when the rule failed and are now returned in clear. Scope defined and approved in API-1738; the privacy impact stays explicit for review.

**Breaking changes — left unticked.** No shape or type changes; values in existing string fields may now be masked (booking endpoints when the rule fails; account endpoints always). `GET /v1/Account/Trips` returned `email: null` before (the light retrieve could not resolve the primary contact) and returns a masked value now.

**Performance — unticked.** No new DotRez calls: the per-PNR retrieval of the previous revision is gone; one extra scalar is projected on the grouped trips retrieve.

## Release Notes

```
* Limits DisplayPassengers masking to contact data and protects account-trip contact emails (API-1738)
  - When the DisplayPassengers rule fails, only booking-contact email/phones, passenger email/phone and Customer creator usernames are masked; other passenger fields are returned in clear.
  - Bookings pending account verification are not masked until verification completes.
  - New optional same-account bypass: a Customer whose username matches the booking's primary contact email.
  - GET /v1/Account (upcomingTrip, basket.travelSummary), GET /v1/Account/Trips and POST /v1/Account/Trips/Add always mask the trip's primary contact email.

* API contract changes
  - No endpoint, request, response-shape or data-type changes. Existing string fields may contain masked email/phone values.

* Configuration changes
  - Adds `creationAccount.treatContactEmailMatchAsSameAccount` (default `false`) to every BookingRules rule entry.

* Admin portal changes: Settings > BookingRules > Rules > <rule> > creationAccount > treatContactEmailMatchAsSameAccount
  - Enable on the rule entries where the contact-email same-account bypass is wanted (DisplayPassengers in particular).
```
