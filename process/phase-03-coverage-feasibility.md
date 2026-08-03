# Phase 3 — Do the ticket and its siblings cover the impact radius? Is it feasible?

> **Question it answers:** do the ticket (and its siblings) cover everything? is it feasible?
> **Support from the LLM repo:** `llm/ANALYZE-TASK.md` §Phase 4 (implementation risk and safety:
> transactional integrity, concurrency, idempotency, test net, reversibility, observability,
> deployment scope, data migration, build traps, size) — those criteria feed directly into the
> feasibility determination of 3.4.

**Objective:** verify coverage and feasibility *before* writing code. This is where it is decided
whether the work can be done, how it gets split and in what order.

## 3.1 Ticket coverage analysis

1. Walk the impact matrix row by row against the description and the acceptance criteria.
2. Mark each row as: **explicitly covered / implicitly covered / not covered / contradicted**.
3. "Implicitly covered" is a trap: it must be made explicit, because nobody is going to test it.
4. Produce the **list of gaps**: everything not covered or contradicted.
5. For each gap decide: (a) it goes into this ticket, (b) a new ticket is created, (c) a ticket
   already exists, (d) it is explicitly decided not to do it (and the decision and its risk are
   documented).
6. Also check the reverse direction: **does the ticket ask for things that no longer apply or that
   are outside the real radius?** Cutting is as valuable as adding.

## 3.2 Sibling ticket analysis

1. Open the **entire epic** and list all related tickets.
2. Map: identified gap → ticket that covers it. Leave the mapping written down.
3. Verify that the sibling tickets **actually cover** the gap (read them, don't trust the title).
4. Detect **overlaps**: two tickets that will touch the same function → risk of conflict and of
   duplicated work. Coordinate with the other owner.
5. Detect **gaps between tickets**: each ticket covers its part but nobody covers the integration
   between them.
6. Verify there is a ticket for the cross-cutting work nobody claims: data migration, documentation
   updates, feature flag cleanup, mobile app update, customer communication.

## 3.3 Dependency and sequencing analysis

1. Build the **dependency graph**: A before B before C.
2. Identify dependencies **external to the team** (another squad, a vendor, infrastructure, legal,
   design) along with their status and committed date. ⚠️ In this system, rules that live in
   **DotRez**, in the **Admin Portal** or in another external service can make the change **not
   implementable here alone** (vendor lead time).
3. Identify the **critical path** and what can be parallelized.
4. Verify the required **deployment order** and whether it is compatible with the release cadence
   (e.g.: the mobile app takes 2 weeks in store approval → the backend must ship
   backward-compatible first).
5. Detect **circular dependencies** between tickets — they get resolved with feature flags or with
   a compatible intermediate step.
6. Verify that the ticket does **not silently block others**.

## 3.4 Feasibility determination (the direct question: can it be done?)

Evaluate along five axes and conclude explicitly:

| Axis | Questions |
|---|---|
| **Technical** | Does the technical capability exist? Does the platform/library allow it? Is there a hard limit? Is there a proof of concept or is a spike needed? |
| **Data** | Does the necessary data exist? With the required quality and history? Can it be obtained? |
| **Dependencies** | Does what I need from others exist today, or does it depend on a future commitment? |
| **Scope/time** | Does it fit in the sprint? Is the estimation still valid after phases 1–2? |
| **Risk** | Is the risk acceptable? Is it reversible? What is the worst that can happen? |

**Possible outcomes and what to do with each:**

- **Feasible as is** → proceed to Phase 4/5.
- **Feasible with reduced scope** → propose the concrete cut (MVP) and what is left for later.
  Renegotiate with the PO.
- **Feasible but needs splitting** → propose the split into tickets with sequencing and incremental
  value delivery (vertical slices, not by layers).
- **Feasible but not now** → a dependency is missing; return the ticket to the backlog with the
  reason and the blocker linked.
- **Not feasible as requested** → bring **2–3 alternatives** with cost, trade-offs and a
  recommendation. Never just a "no".
- **Needs a spike first** → create the spike with a concrete question, timebox and defined
  deliverable.

These outcomes map to the gate's verdict (Phase 4): "feasible as is" ⇒ candidate for ✅;
anything else ⇒ ⚠️ or ⛔ with its questions/alternatives.

## 3.5 Scope and estimation renegotiation

1. If the estimation changed more than ~30% from the original, communicate it **immediately**, not
   at the end of the sprint.
2. Present the change with the evidence (impact matrix), not as opinion.
3. Offer options: reduce scope, move the date, add help, accept documented temporary debt.
4. Update the ticket: description, acceptance criteria, subtasks, estimation, linked dependencies,
   risk labels.

---

**Artifacts:** `work/<KEY>/phase-03-feasibility.md` — list of gaps with their resolution,
gap→ticket mapping, dependency graph, feasibility conclusion (also written in the ticket).

**Exit criterion:** the PO/tech lead agrees with the final scope and with the new tickets created.

**Next:** [Phase 4 — Blockers and assumptions (GATE)](phase-04-blockers.md)
