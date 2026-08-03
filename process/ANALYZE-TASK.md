<!-- MOVED HERE from VivaAerobus.Generic.ApiLLM/llm/ — this file is Coder process methodology.
     Paths like documents/**, guidelines/**, llm/SYNC.md remain RELATIVE TO THE ApiLLM REPO ROOT
     (../VivaAerobus.Generic.ApiLLM/). Knowledge and guidelines stay there; only the procedure moved. -->

# ANALYZE-TASK.md — Requirement Analysis Gate (STEP 2 of every task)

> Called by `../CLAUDE.md` **after `SYNC.md` completes**, whenever the user brings a requirement,
> ticket, bug or change request — **before writing any code**.
>
> **Goal:** analyse the request *in full* against the existing implementation, decide whether it can
> be built safely, and **automatically ask everything needed** to avoid uncontrolled collateral
> damage.
>
> ⚠️ Bound by the **evidence-first rule** (`../CLAUDE.md §Non-negotiable`): reason only from cited
> facts. Where the docs say `unverified`/`unknown`, that is a **gap**, not a fact.
>
> ⛔ **This step produces NO code.** Not a snippet, not a diff, not a "proposed fix". Writing code
> here skips the gate and anchors the reader on a solution before the questions are answered. The
> most this step may output is a 3–6 bullet *plan sketch* (files/areas to touch), and only when the
> verdict is ✅. Code belongs to step 3 (`change-playbook.md`).
>
> **Two kinds of missing information — never confuse them:**
> - **Business gap** → the requester must define it. Becomes a *question*.
> - **Documentation gap** (`unverified` in our docs) → **we** must verify it in code. Becomes a
>   *verification task before estimating*, not a question to the business.

---

## Phase 0 — Report sync status, restate, locate

0. **State the sync status in the first lines of the output — always.** Compare
   `last_documented_commit` in `documents/_meta/sync-state.md` against the code repo's current
   `master` HEAD, and say it explicitly: *in sync*, or *docs are N commits behind — reasoning from
   code, not docs*. Never leave this implicit. If `SYNC.md` could not run (e.g. no shell inside the
   repo), say so in that same line: a silent stale-doc analysis is the failure mode this whole
   pipeline exists to prevent.
1. **Restate the request** in one paragraph, in your own words: what outcome is wanted, for whom.
   If the restatement is impossible without guessing, that alone is a blocking finding.
2. **Locate it** via `../documents/concepts/_catalog.md` (+ `integrations/_catalog.md`). List the
   concept(s), integration(s) and shared areas touched. Open only those docs.
3. **Check it isn't a stub.** Four endpoints exist that return empty output while Swagger promises
   behaviour (`concepts/_catalog.md` § "Known implementation gaps"). If the request assumes one
   works, it is **greenfield, not a modification** — say so.

---

## Phase 1 — Classify the change (cheap questions that change everything)

| Question | Why it matters here |
|---|---|
| **Is this code or configuration?** | 39 Admin Portal config parts govern business rules at runtime (`../documents/_meta/flags-and-rules.md`). Many requests need **no deploy** — and a config change bypasses PR review and tests, which is its own risk. |
| **Which channels and flows?** | Behaviour varies by **Channel** (web, mobile, kiosk, whatsapp, callcenter, express) × **FlowType** (Booking, Manage, CheckIn, Transfer) × **AgentType** (Customer, Staff) × **IsPointsBooking** × **Location**. A request that doesn't say is **underspecified** — it may work on web and break on kiosk. |
| **Which API version(s)?** | V1/V2 pairs coexist (`Account`/`Account2`, `Register`/`RegisterV2`, `AccountVivaCash`/`VivaCash2`). Changing one leaves inconsistent behaviour. |
| **Where does the rule actually live?** | This repo vs **DotRez** vs **Admin Portal config** vs another external service. If it lives outside, the change may **not be implementable here alone** and depends on a vendor's lead time. |
| **Is it a contract change?** | Error codes and response shapes are a **contract** with web/mobile/partners. Adding a code is additive; changing/removing one breaks clients. |
| **Read or write?** | Mutating endpoints inherit the concurrency/idempotency/transaction concerns in Phase 3. |

---

## Phase 2 — Clarity gates (is the request even complete?)

- **Objective** — is the *business* outcome explicit, not just the mechanic? ("add field X" vs "so
  the agent can see Y").
- **Scope boundaries** — what is explicitly **out** of scope.
- **Acceptance criteria** — stated in **testable** terms (given/when/then, or concrete
  input→expected output). If absent, this is blocking.
- **How will we validate it?** — who validates, in which environment, with what data. A change that
  cannot be validated cannot be declared done.
- **Do we know how to test it?** — is it reachable in a test environment at all? Several flows
  depend on **external test systems** (DotRez, PSPs, Hopper, TrenMaya…), so "testable" is not a
  given.
- **Contracts** — for every input the request implies: required/optional, type/unit, range, format,
  default, nullability. Compare against the documented contract; **missing required inputs are a
  blocking question**.
- **Error handling** — what should happen on each failure path, and which error code the caller
  receives.
- **Edge cases** — empty, maximum, expired, duplicated, concurrent, partial.
- **Non-functional expectations** — latency, volume, limits (especially on hot paths such as
  Availability or SeatMaps).
- **Localization / timezone** — culture-dependent logic exists (`IsCultureName`, `IsNonMxCulture`)
  and `TimeZone.Local` vs `Utc` handling.
- **Compliance** — Mexican taxes (TUA), refund rules, PCI if cards are involved, personal-data rules
  (travel documents, CURP, **minors** via child companions).

---

## Phase 3 — Impact analysis (what could this break?)

Drive this from `../documents/cross-module/dependency-map.md` and the concept docs.

1. **Reverse-index everything touched.** For each shared model/service/integration, list the
   consuming concepts. Example already mapped: `_Shared/Basket` is consumed by **61 handlers across
   9 areas** — the highest blast radius in the system.
2. **Does it touch the Basket lifecycle?** Active/Passive/Expired with two independent clocks
   (expiration in days, activity in minutes) gates nearly every endpoint. Changing its semantics
   changes behaviour API-wide.
3. **Shared contracts.** `OutputModel<T>`, the `ErrorCode` enum, DotRez contracts and the
   HttpContext basket context (PNR/token/FlowType/language set on every basket read) are
   high-risk edges.
4. **External consumers.** Web, mobile, partner/GDS surfaces. Is the change backwards compatible?
   If not, who coordinates the client release?
5. **In-flight sessions — the one everybody forgets.** Baskets and bookings created **before** the
   change may be processed **after** it. Does the change break them? Marten documents already stored
   must remain readable (schema tolerance / backfill).
6. **Cache invalidation.** Caching exists with Admin reset endpoints
   (`CacheResetDotRez/Resources/Schedule/Settings/ExternalTokens`). A data/reference change without
   invalidation looks "not applied" in production.
7. **Async side effects.** Insurances, child-companion and comment relocation are **enqueued**;
   their failures are invisible in the response. Also `IDispatcherNotifier` and the confirmation
   email fire after commit. A request assuming immediate confirmation is mis-specified.
8. **Money, points, currencies.** Idempotency and double-charge guards, exchange rates, MXN/USD,
   points brackets and coverage rules. Maximum-sensitivity zone.
9. **Security surface.** Does it touch endpoints already flagged in
   `../documents/operations/security.md`? Does it add PII, or a new unauthenticated route?

---

## Phase 4 — Risk & safety of implementation

- **Transactional integrity.** There is **no transaction boundary** across multi-step handlers
  (Payment writes at several points). Define the intermediate state on failure and how it recovers.
- **Concurrency.** Optimistic concurrency surfaces as `BOOKING_WAS_MODIFIED`; retries regenerate the
  basket transaction id. Does the change interact with that?
- **Idempotency.** Is a repeated call safe? (Critical for anything touching payments or check-in.)
- **Test safety net.** Coverage is uneven (`../documents/operations/testing.md`): strong on payment
  availability rules, currencies and proposed seats; **absent** on Basket, Booking, Checkin, Irop,
  Train, Transfer, Vehicle, Admin, Internal and all integration clients. **Where there are no tests,
  writing them is part of the scope, not optional.**
- **Reversibility.** Can it be switched off without a deploy? Config parts / feature flags are the
  natural kill switch. If there is no way back, say so explicitly.
- **Observability.** What log, metric or trace is added so we can tell **in production** that it
  works — not just that QA passed.
- **Deployment scope.** Which environments and sub-environments; does it need coordination with the
  front-end, a partner, or an external vendor?
- **Data migration.** Backfill or schema tolerance needed for existing Marten documents?
- **Build traps.** Files can exist but be excluded from compilation (`<Compile Remove>` in the
  `.csproj` — e.g. two payment points rules). Never assume a file in the tree is active.
- **Size.** If the analysis reveals several coupled changes, say so and propose splitting it.

---

## Phase 5 — Verdict and questions (the deliverable)

Always end with an explicit verdict — never a vague summary.

| Verdict | Meaning |
|---|---|
| ✅ **Ready to implement** | Objective, contracts, acceptance criteria and impact are clear. Proceed to `change-playbook.md`. |
| ⚠️ **Needs definition** | Implementable here, but blocking items are undefined. **Stop and ask.** |
| ⛔ **Not implementable as stated** | The source of truth is outside this repo, it depends on a stub, or it conflicts with an existing rule/contract. Explain why and what would be required. |

### Question rules

- **You may recommend, but you may never resolve.** When you find an ambiguity or a contradiction
  in the request, state your recommended reading *and* keep it as a `BLOCKING` question. Deciding it
  yourself — even with good reasoning — silently converts a requester's decision into an assumption,
  which is exactly what the evidence rule forbids. Format:
  *"Ticket says X in the body and Y in the test cases. Recommendation: Y, because test cases are the
  acceptance criteria. **Confirm before implementation.**"*
- **Prioritise**: `BLOCKING` (cannot start) vs `NICE-TO-HAVE` (can start, decide later).
- **Each question carries its "why"** — the concrete risk it prevents. Never a bare list; the
  requester must see it is not bureaucracy.
- **Group by owner** where known (product / front-end / DotRez vendor / infra).
- **Keep it short.** Twenty flat questions get ignored; three blocking ones get answered.
- **Separate verification tasks** (our job, in code) from business questions (their job).
- Ask them **automatically** — do not wait to be asked to ask.

### Output template

```markdown
## Analysis — <requirement title>
**Verdict:** ✅ / ⚠️ / ⛔ — <one line>
**Docs sync:** anchor `<sha>` vs code HEAD `<sha>` — <in sync | N commits behind, reasoning from code>

### What is being asked
<restatement in one paragraph>

### Classification
Code / config · channels+flows · versions · source of truth · contract impact

### Affected surface (cited)
| Area | What changes | Doc |

### Impact & risk
- Blast radius: <from dependency-map, with numbers>
- In-flight sessions: <effect>
- Async / transactional: <effect>
- Test coverage: <exists / **absent → writing tests is in scope**>  ← mandatory line
- Unrequested behaviour change: <what visible output changes beyond what was asked, or "none">  ← mandatory line
- Shared helpers touched: <name them and state they must NOT be modified, or "none">
- Reversibility: <flag / none>

### 🔴 BLOCKING questions
1. <question> — *why:* <risk avoided> — *owner:* <who>

### 🟡 Nice-to-have questions
1. <question> — *why:* <…>

### 🔍 Verification tasks (ours, before estimating)
1. Read `<file>` to confirm <unverified item>

### If answered, the plan would be
<3–6 bullets: files to touch, tests to add, rollout>
```

---

## Anti-patterns (do not do this)

- Inventing a missing requirement to be able to proceed.
- **Resolving an ambiguity by deciding instead of asking** (recommend, then still ask).
- **Emitting code** in this step, or ending with "shall I implement?" instead of a verdict.
- Starting the analysis without stating the docs-sync status.
- Proposing a change that alters visible output beyond the request without flagging it.
- Treating an `unverified` doc line as fact.
- Reporting "no impact" without having consulted the reverse index.
- Producing a plan when the verdict is ⚠️ or ⛔.
- Asking questions the docs already answer (read first, ask second).
- Ignoring channels/flows/versions because the ticket didn't mention them.
