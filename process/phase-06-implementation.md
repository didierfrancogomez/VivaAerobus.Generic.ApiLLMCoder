# Phase 6 — Implementation

> **Question it answers:** build according to the plan, without deviating in silence.
> **Where it is implemented:** in the API repo (`../VivaAerobus.Generic.Api`), branch from
> `master`. System code is never written in this repo nor in the ApiLLM.
> **MANDATORY support in the LLM repo:**
> - `guidelines/**` (`STY`/`ARC`/`ROB`/`PRC`) — **normative**: it is the bar applied by the human
>   reviewers and by the Phase 9 gate.
> - `documents/architecture/conventions.md` + `patterns-cqrs.md` — where each piece goes (thin
>   controller, handler per feature, builders, registered validators).
> - `llm/change-playbook.md` step 7: if the implementation reveals something the analysis missed,
>   **stop and go back to the gate (Phase 4)** instead of improvising.

**Objective:** execute the plan in a verifiable, incremental way, without deviating in silence.

## 6.1 Environment preparation

1. Update the base branch (`master`) and create the branch following the team's convention:
   `type/KEY-123-short-description`.
2. Install dependencies, run migrations, seed data, **verify that the test suite passes green
   BEFORE touching anything**. If it is already red, that is a pre-existing finding (do not
   inherit it silently). Local setup: `documents/operations/local-setup.md` in the LLM repo.
3. Have realistic data: volume, edge cases, "dirty" data resembling production.
4. Have access to everything needed (sandbox credentials, permissions, flags) — resolve it here,
   not midway through.

## 6.2 Work cycle

1. **For bugs: first write the failing test** that demonstrates the bug. Without that red test you
   don't know you fixed it; you only know you no longer see it.
2. **For features: write the test or the acceptance case before or alongside** the code, starting
   with the happy path and then the edges.
3. **Work in small increments**, running tests and linters locally at every step. Never accumulate
   3 days of changes without verifying.
4. **Small, atomic commits with an explanatory message** (conventional format:
   `feat(scope): ...`, `fix(scope): ...`, with the ticket key). The message explains the *why*;
   the diff already explains the *what*.
5. **Sync with the base branch daily** (rebase or merge per the team's standard) to avoid the
   giant conflict at the end.
6. **Continuous manual functional verification:** don't wait until the end to look at the screen
   or call the endpoint.

## 6.3 Quality during development

1. **Respect the project's standards:** the rules in `guidelines/**` are normative; additionally
   style, automatic formatting, linter, static analysis, typing, naming conventions, folder
   structure. The pipeline must not be the first time they are run.
2. **Clear names over comments.** Comment only the non-obvious *why* and unusual decisions with
   their reason.
3. **Explicit error handling:** no swallowing exceptions, no generic catches, useful messages,
   typed errors, no exposing internal details to the client. Error codes: add new ones, **never
   reuse** an existing one (`documents/cross-module/error-codes.md`).
4. **Validation at the edge and on the server** always, not only in the frontend.
5. **No secrets in the code.** No credentials, tokens, internal URLs, real customer data.
6. **Instrument while implementing:** the logs, metrics and traces from the observability plan are
   part of the change, not an extra.
7. **Idempotency and retries** in everything that is an asynchronous process, job, webhook or
   payment. ⚠️ In this API the enqueued side effects (insurances, child-companion, comments) fail
   invisibly in the response — design their visibility.
8. **Update in the same change:** tests, README if the setup changes, contracts/OpenAPI, i18n
   texts, configuration for all environments, shared types, generated code. (The system
   documentation in `documents/**` is NOT touched here — the ApiLLM pipeline updates it in
   Phase 11.)
9. **Feature flag off by default** and verify that **both paths** (on and off) work.
10. **Walk the impact matrix and touch every point** that requires a change; check them off as
    they are resolved.

## 6.4 Deviation control (critical)

1. **No-scope-expansion rule:** every finding that is not necessary to meet the acceptance
   criteria gets noted and becomes a new ticket. It is not fixed here.
2. **Exception (bounded boy-scout rule):** trivial, local improvements to code you are already
   touching, yes; refactors that grow the diff, no.
3. **If a big problem appears** (the plan doesn't work, the impact is larger, there is a technical
   impossibility): **stop and go back to Phase 4/5**. Communicate it the same day. Do not try to
   "solve it with more hours".
4. **If the diff grows too large** (>~400 lines of real change, or it touches unrelated domains):
   split it into several PRs.
5. **Timebox rule:** if you have been stuck for more than ~2 hours without progress, ask for help.
   It is not weakness, it is economics.
6. **Report real progress daily**, including what got complicated. Surprises at the end of the
   sprint are process failures, not code failures.

---

**Artifacts:** branch with clean commits, tests, updated configuration.

**Exit criterion:** all acceptance criteria implemented, all points of the impact matrix
addressed, suite green locally.

**Next:** [Phase 7 — Testing](phase-07-testing.md)
