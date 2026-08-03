# Phase 8 — Release preparation

> **Question it answers:** can it be deployed and rolled back safely?
> **Support from the LLM repo:** `documents/_meta/flags-and-rules.md` (config parts / kill switch
> per environment) and the Admin cache-reset endpoints cited in Phase 2.3.8 — cache invalidation is
> a runbook step, not a footnote.

**Goal:** make the deployment a non-event and make rollback possible within minutes.

## 8.1 Deployment artifacts

1. **Deployment runbook** with the exact order of steps: migration → deploy service A →
   deploy service B → backfill → turn on the flag → verification.
2. **Migration and backfill scripts** reviewed, idempotent, resumable, with progress logging and
   tested against a copy of real data.
3. **Configuration and secrets provisioned in every environment** before the deployment (a missing
   variable in prod is the most common cause of a failed deployment).
4. **Feature flag created in all environments**, turned off, with an owner and with a documented
   activation criterion.
5. **Deployment order across repositories** and compatibility verified for every intermediate step
   (the system must work *between* deployments, not only at the end).
6. **External dependencies ready**: the other team already deployed, the provider already enabled
   it, the permission already exists.

## 8.2 Observability and operational safety

1. **Dashboards and alerts created and deployed BEFORE the change**, not after. You must be able to
   answer "is it working?" in 30 seconds.
2. **Define the success and failure metrics** and their thresholds: error rate, p95/p99 latency,
   volume of the new operation, business metrics.
3. **Tested rollback plan**: how it is reverted, how long it takes, who executes it, what is lost.
   If anything is irreversible, say so explicitly.
4. **Kill switch** available (the flag / config part) to deactivate without deploying.
5. **Abort criteria:** which concrete signal triggers a rollback without discussion.
6. **Post-deployment verification plan (smoke test):** a short, concrete list of what gets checked
   in production during the first 10 minutes.

## 8.3 Communication and coordination

1. **Release notes / changelog** in user-facing language.
2. **Notify those affected:** support, customer success, sales, operations, other development
   teams, and customers/integrators if there is a contract change (with a grace period).
3. **Update documentation:** public API, internal guides, support knowledge base, manuals, ADRs,
   diagrams. (The technical documentation in `documents/**` is updated by the ApiLLM's pipeline —
   it is scheduled for Phase 11.)
4. **Coordinate the window:** avoid Fridays, end of month/accounting close, campaigns, code
   freezes, peak hours; consider the users' time zones.
5. **Define who is on call** during and after the deployment, and for how long it is monitored.
6. **Formal approvals** if applicable: security, compliance, legal, change management, business
   owner.
7. **Training** for the support team if the change alters what users see or do.

---

**Artifacts:** runbook, release notes, dashboards and alerts, rollback plan, communications sent.

**Exit criterion:** anyone on the team could execute the deployment and the rollback by following
the runbook.

**Next:** [Phase 9 — Pre-review](phase-09-pre-review.md)
