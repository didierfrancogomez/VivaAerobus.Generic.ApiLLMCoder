# Annex A — One-page checklist (daily use)

> Compressed version of the full process. Each block maps to its phase (`phase-NN-*.md`).
> The gate is still alive here: if the **Blockers** block is not clean, you do not move on to
> **Plan**. **Every block closes with `tools/save-progress.sh <KEY> "<phase>"`** and telling the
> user the folder (`work/<KEY>/`) — progress that only lives on one disk is not progress.

**Understand** (Phase 0)
- [ ] `tools/new-task.sh <KEY>` ran: scaffold + ticket fetched + `ready` gate (blockers → ask, don't start)
- [ ] I read the ticket, comments, history, attachments and epic (matrix authority = evidence subtask; comments retire rows)
- [ ] I know the business problem and the expected observable outcome
- [ ] The ticket meets the Definition of Ready
- [ ] I searched for related tickets, duplicates and previous attempts
- [ ] I classified the type of work and the rigor level (trivial/normal/risky)

**Contrast with the code** (Phase 1)
- [ ] I synced the LLM repo (llm/SYNC.md) and stated the docs status
- [ ] I located and read the actual code and its tests
- [ ] I ran it / reproduced the bug
- [ ] I reviewed the history (why it is the way it is)
- [ ] I documented the discrepancies between the ticket and reality, with citations

**Impact radius** (Phase 2)
- [ ] Callers, callees, implementations, text references, generated code
- [ ] I consulted the reverse index of the LLM repo's dependency-map
- [ ] Contracts and consumers (incl. old mobile versions), events, webhooks
- [ ] Data: schema, real volume, indexes, legacy data, backfill, caches, reports
- [ ] Non-functional: performance, concurrency, security, per-role permissions, observability,
      i18n, accessibility
- [ ] Operational: per-environment configuration, infra, jobs, CI/CD, deployment order, support,
      analytics
- [ ] Impact matrix written and validated by another person

**Coverage and feasibility** (Phase 3)
- [ ] Every row of the matrix: covered / sibling ticket / explicitly discarded
- [ ] I verified that the sibling tickets actually cover it
- [ ] Dependency graph and deployment order defined
- [ ] Feasibility conclusion written (and scope renegotiated if it changed)

**Blockers — THE GATE** (Phase 4)
- [ ] Questions classified and written in the ticket with options and a recommendation
- [ ] Zero open hard blockers
- [ ] Assumptions recorded with their validation method
- [ ] Explicit verdict issued: ✅ continue / ⚠️⛔ **STOP**

**Plan** (Phase 5)
- [ ] Steps `P-NN` and scenarios `S-NN` numbered (template `_templates/plan.md`)
- [ ] Two options evaluated and one chosen with justification (ADR if applicable)
- [ ] Plans written: data/migration, compatibility, flag, observability, tests,
      rollout/rollback
- [ ] Guideline IDs (STY/ARC/ROB/PRC) the code must honor, cited in the plan
- [ ] Work split into vertical steps and separate PRs
- [ ] Risks and anti-scope defined
- [ ] Plan reviewed and approved

**Implement** (Phase 6)
- [ ] Suite green before starting
- [ ] Failing test first (bugs)
- [ ] Small commits, standards and linters applied
- [ ] Observability, configuration and i18n updated in the same change
- [ ] Both paths of the flag work
- [ ] Out-of-scope findings → new tickets, not in this diff

**Test** (Phase 7)
- [ ] Every acceptance criterion tested
- [ ] Negative cases, edges, concurrency, idempotency, roles and permissions
- [ ] Regression over every point of the impact radius
- [ ] `S-NN` matrix complete: every plan scenario executed or justified n/a; ladder respected (xUnit → PS1 → Postman/newman; Issue/Solution evidence)
- [ ] Old-client/new-server compatibility and vice versa
- [ ] Migration applied and reverted; performance with realistic volume
- [ ] Full suite and CI green; tested in a production-like environment
- [ ] `phase-07-testing.md` recorded with `TESTS: GREEN` + the suite output
- [ ] Test notes handed to QA; QA/PO acceptance

**Prepare the release** (Phase 8)
- [ ] Runbook with the exact order of steps
- [ ] Configuration and secrets in all environments; flag created and off
- [ ] Dashboards and alerts ready before the deployment
- [ ] Rollback defined and tested; clear abort criteria
- [ ] Release notes and communication to support/business/customers
- [ ] Window and on-call agreed

**Pre-review** (Phase 9)
- [ ] I read the full diff as a reviewer
- [ ] No noise, no secrets, no accidental files
- [ ] Acceptance criteria and impact matrix walked through one by one
- [ ] Completeness re-validated: Jira task + plan + code, nothing left uninvolved
- [ ] Deviations audited: none, or user-approved AND documented in the plan
- [ ] Clean build from scratch; branch **squashed to ONE clean commit**
- [ ] Reasonable PR size
- [ ] REVIEW-CODE.md of the LLM repo → **APPROVED**
- [ ] The four marker lines recorded: `REVIEW-CODE: APPROVED`, `VALIDATED-SHA:`,
      `COMPLETENESS: VERIFIED`, `DEVIATIONS:`

**PR** (Phase 10)
- [ ] Publication summary presented to the user; **user approved** (`PUSH-APPROVED` exists —
      created by the user, never by the agent)
- [ ] Title with the ticket key; description with the full template
- [ ] Evidence attached; bidirectional links
- [ ] Correct reviewers; non-obvious parts self-annotated
- [ ] CI green before requesting review
- [ ] Comments answered; review re-requested when done

**Rework** (if comments/QA return)
- [ ] `tools/new-run.sh <KEY>` archived the previous evidence (gates re-closed)
- [ ] Minimal fix only; every comment resolved; re-approved and re-delivered

**Post-merge** (Phase 11)
- [ ] Smoke test in production; monitoring during the window
- [ ] Migration/backfill verified; flag enabled progressively
- [ ] ApiLLM docs re-synced (doc-sync) and anchor advanced
- [ ] Ticket closed with evidence; debt and flag cleanup scheduled
- [ ] Learning documented
