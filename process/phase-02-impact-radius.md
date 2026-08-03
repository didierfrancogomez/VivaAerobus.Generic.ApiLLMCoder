# Phase 2 — Identify the impact radius

> **Question it answers:** what moves if I touch this?
> **MANDATORY support from the LLM repo:**
> - `documents/cross-module/dependency-map.md` — **reverse index**: for every shared model/service
>   touched, the list of consuming concepts. Never report "no impact" without having consulted it.
> - `llm/ANALYZE-TASK.md` §Phase 3 — the list of impacts specific to this system (Basket
>   lifecycle, shared contracts `OutputModel<T>`/`ErrorCode`, in-flight sessions, cache with reset
>   endpoints, queued side effects, money/points/currencies, security surface).
> - `documents/cross-module/error-codes.md` if the change touches error codes.
> - `documents/_meta/flags-and-rules.md` if the change touches configuration.

**Objective:** exhaustively enumerate everything that moves, directly or indirectly. This is the
phase that prevents incidents.

## 2.1 Code impact (static)

1. **Upwards (callers):** who invokes what I'm about to change. Search for references across the
   whole monorepo/organization, not just the open file.
2. **Downwards (callees):** what I depend on and whether my change alters how I use it.
3. **Interfaces, abstract classes, traits, shared types:** are there other implementations that
   must change too?
4. **Dependency injection / service registration / factories:** is there wiring to update?
5. **Inheritance and polymorphism:** subclasses that override the behavior.
6. **Reflection, magic strings, convention-based names, serialization:** references the compiler
   and the IDE do **not** find. Do a plain-text search for the old name across the whole repo.
7. **Shared internal libraries:** if the change is in a library, who consumes it and on which
   version.
8. **Other repositories / other services** that depend on this.
9. **Generated code** (API clients, DTOs, ORMs, GraphQL codegen): does it need regenerating?

## 2.2 Impact on contracts and integrations

1. **REST/GraphQL/gRPC APIs:** is the change *additive* (compatible) or *breaking*?
   - Breaking: removing a field, renaming, changing a type, changing semantics, making an optional
     field required, changing an error code, changing default ordering/pagination.
2. **Known and unknown consumers:** web frontend, mobile app (⚠️ **old installed versions you
   cannot force to update**), third-party integrations, internal scripts, reporting, someone's
   Postman/Zapier.
3. **Events and messaging:** event schemas, topics, queues, message ordering, idempotency, existing
   consumers, messages already in flight during deployment, DLQs.
4. **Outgoing and incoming webhooks.**
5. **Contracts with external providers** (`documents/integrations/_catalog.md`), rate limits,
   quotas, SLAs.
6. **Versioning:** do I need a v2 of the endpoint? deprecation with a grace period? a version
   header? ⚠️ In this API, V1/V2 pairs coexist (`Account`/`Account2`, `Register`/`RegisterV2`…) —
   changing one leaves inconsistent behavior.
7. **Bidirectional compatibility during deployment:** old client + new server, and new client + old
   server (rollback).

## 2.3 Data impact

1. **Schema:** tables, columns, types, nullability, constraints, foreign keys, default values.
   (This system's persistence: `documents/architecture/data-persistence.md` — Marten/Postgres.)
2. **Migrations:** is it reversible? does it lock the table? how long does it take on real
   production volume?
3. **Real volume:** run the count in production. A migration that is instant on 100 rows can be a
   40-minute incident on 80 million.
4. **Indexes:** does the new query use them? do I need a new one? can the new index be created
   concurrently?
5. **Inconsistent existing data:** is the new rule valid for historical data? do I need a backfill?
   what do I do with rows that don't comply? ⚠️ Marten documents already stored must remain
   readable (schema tolerance / backfill).
6. **Backfill:** strategy, batching, idempotency, resumable, estimated time, load impact.
7. **Integrity and duplication:** can the change create duplicates or orphans?
8. **Caches:** invalidation, cache keys, TTL, caches in the CDN, in the client, in the ORM, in
   Redis, in process memory. ⚠️ This API has Admin reset endpoints
   (`CacheResetDotRez/Resources/Schedule/Settings/ExternalTokens`) — a reference-data change
   without invalidation looks "not applied" in production.
9. **Read replicas and replication lag** (reading right after writing).
10. **Data warehouse / ETL / reports / dashboards** that read those tables directly (you break
    reports without noticing).
11. **Backups and retention:** can it be restored if this goes wrong?
12. **Personal data (PII):** does the change add, move or expose sensitive data? Privacy
    implications, encryption, anonymization, retention policies. (Baseline:
    `documents/operations/security.md`.)

## 2.4 Non-functional impact

1. **Performance:** new queries, N+1, calls in a loop, larger payloads, response time, CPU/memory
   usage, unindexed queries. Known hot paths: Availability, SeatMaps.
2. **Concurrency:** race conditions, locks, deadlocks, long transactions, simultaneous executions
   of the same job. ⚠️ Optimistic concurrency surfaces as `BOOKING_WAS_MODIFIED`.
3. **Scalability:** does it withstand the peak? what happens at 10x the traffic?
4. **Security:** authentication, authorization (roles and permissions for every existing role),
   IDOR, injection, XSS, CSRF, secrets, privilege escalation, data exposure in responses and in
   logs.
5. **Multi-tenancy / isolation between customers** if applicable.
6. **Observability:** what logs, metrics, traces and alerts do I need to know whether this works in
   production?
7. **Resilience:** timeouts, retries, circuit breakers, graceful degradation, what happens if the
   service I depend on is down.
8. **Internationalization:** new texts, date/number/currency formats, time zones, RTL.
   ⚠️ There is culture-dependent logic (`IsCultureName`, `IsNonMxCulture`) and
   `TimeZone.Local` vs `Utc` handling.
9. **Accessibility:** contrast, focus, screen readers, keyboard navigation, labels.
10. **UI compatibility:** browsers, screen sizes, devices, dark mode.
11. **Costs:** new calls to paid services, storage, egress, licenses.
12. **Regulatory compliance / audit:** audit trails, legal, accounting or regulatory requirements.
    ⚠️ This API's domain: Mexican taxes (TUA), refund rules, PCI if cards are involved, personal
    data (travel documents, CURP, **minors** via child companions).

## 2.5 Operational and environment impact

1. **Configuration:** new environment variables, feature flags, parameters, secrets — **in every
   environment** (local, dev, QA, staging, prod). ⚠️ 39 Admin Portal config parts govern business
   rules at runtime (`documents/_meta/flags-and-rules.md`) — a config change **goes through neither
   PR nor tests**, which is its own risk.
2. **Infrastructure:** new resources, IAM permissions, queues, buckets, cron, networking, memory
   limits.
3. **CI/CD pipeline:** new steps, build times, new dependencies and their
   licenses/vulnerabilities.
4. **Deployment order** between services and between back/front/mobile.
5. **Scheduled jobs, batch, nightly processes** that touch the same thing.
6. **Internal tools and support:** admin panels, back-office tools, the support team's manual
   processes.
7. **Documentation and training:** user manuals, support guides, sales scripts, knowledge base.
   (The system's technical documentation is updated by the ApiLLM pipeline in Phase 11 — here you
   only record WHAT will need re-documenting.)
8. **Analytics and tracking:** product events, funnels, active A/B experiments on that screen.

## 2.6 Build the impact matrix

Mandatory table, one row per impacted element:

| Element | Type (code/data/contract/config/non-functional) | How it is affected | Is it in the ticket? | Is there another ticket? | Owner | Action | Risk (H/M/L) |
|---|---|---|---|---|---|---|---|

**Golden rule:** every row with "Is it in the ticket? = No" and "Is there another ticket? = No" is
a gap that gets resolved in Phase 3 or becomes a blocking question in Phase 4.

---

**Artifacts:** `work/<KEY>/phase-02-impact-matrix.md` (also pasted as a comment on the ticket),
every row cited against the code or the dependency-map.

**Exit criterion:** someone else on the team reviews the matrix and does not add missing elements
(10-minute cross-validation).

**Next:** [Phase 3 — Coverage and feasibility](phase-03-coverage-feasibility.md)
