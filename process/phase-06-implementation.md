# Phase 6 — Implementation

> **Question it answers:** build according to the plan, without deviating in silence.
> **Where it is implemented:** in the API repo (`../VivaAerobus.Generic.Api`), branch from
> `master`. System code is never written in this repo nor in the ApiLLM.
> **MANDATORY support in the LLM repo:**
> - `guidelines/**` (`STY`/`ARC`/`ROB`/`PRC`) — **normative (GOLDEN RULE, `../CLAUDE.md`
>   rule 5)**: it is the bar applied by the human
>   reviewers and by the Phase 9 gate.
> - `documents/architecture/conventions.md` + `patterns-cqrs.md` — where each piece goes (thin
>   controller, handler per feature, builders, registered validators).
> - `process/change-playbook.md` step 7: if the implementation reveals something the analysis missed,
>   **stop and go back to the gate (Phase 4)** instead of improvising.

**Objective:** execute the plan in a verifiable, incremental way, without deviating in silence.

## 6.1 Environment preparation

1. Update the base branch (`master`) and create the branch following the client's convention
   (PRC-102 in the LLM repo's `guidelines/process.md`): `feature/API-<n>/<kebab-slug>` (or
   `fix/…`). ⚠️ The Jira key in the branch name is **load-bearing**: the
   enforcement hooks resolve which task a code change belongs to from the checked-out branch and
   validate it against `work/KEY-123/` — that is what lets several plans run in parallel, each on
   its own branch. A branch whose key has no analysis artifacts gets its writes denied.
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
4. **Small, atomic commits with an explanatory message** (client convention, PRC-102:
   `API-<n> <gitmoji> <imperative why>`; formatting-only changes in their own commit, PRC-30).
   The message explains the *why*; the diff already explains the *what*. ⚠️ These development
   commits are **working
   checkpoints**: the team policy is that the PR carries **ONE clean commit with the whole
   solution** — the branch is squashed in Phase 9 (§9.3) before asking the user to approve
   publication.
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
   **Any deviation from the approved plan — even a small one — requires the user's approval** and
   is recorded in `work/<KEY>/phase-05-plan.md §Deviations (approved)` (what changed, why, who
   approved, when). Phase 9 audits the diff against the plan: an undocumented or unapproved
   deviation blocks publication.
4. **If the diff grows too large** (>~400 lines of real change, or it touches unrelated domains):
   split it into several PRs.
5. **Timebox rule:** if you have been stuck for more than ~2 hours without progress, ask for help.
   It is not weakness, it is economics.
6. **Report real progress daily**, including what got complicated. Surprises at the end of the
   sprint are process failures, not code failures.

## 6.5 Apply the team's code style — `Ezy` profile (MANDATORY, last step of the phase)

The API repo versions its own Rider/ReSharper settings,
`VivaAerobus.Generic.Api/VivaAerobus.Generic.Api.sln.DotSettings`, with a Code Cleanup profile
named **`Ezy`** (also the solution's *silent cleanup* profile). It is the style the reviewers
apply. Code that "looks tidy" is not enough: **every line the task adds or modifies must come out
exactly as that profile would write it**, and **every pre-existing line stays as `master` has it**
(reformatting untouched code is collateral that the reviewer reads as a decision of yours, and it
costs a review round).

It runs **here, after the functional work is done and before Phase 7**, so the tests (Phase 7)
and the review (Phase 9) run on the styled code, and nothing reaches a branch unstyled.

**The command (the CLI of Rider's *Code Cleanup*)**, from the solution directory
(`../VivaAerobus.Generic.Api/VivaAerobus.Generic.Api/`), scoped to the task's files:

```bash
jb cleanupcode VivaAerobus.Generic.Api.sln --profile="Ezy" --include="<file1.cs;file2.cs>" --verbosity=WARN
```

(`jb` = `JetBrains.ReSharper.GlobalTools`; one-time install: `dotnet tool install -g
JetBrains.ReSharper.GlobalTools`.) `--include` limits the **files**, not the **lines**: inside
an included file it rewrites everything. So it is **never run bare**. Run it through the wrapper,
which applies the rule mechanically:

```bash
tools/code-style.sh <KEY> apply
```

What `apply` does: it computes "our lines" (the new-side lines of `git diff -U0 <merge-base>`,
committed + uncommitted, plus every line of a new file). Then it runs the cleanup on the task's
`.cs` files, handling `dotnet restore` and the temporary `global.json` `rollForward` workaround,
and restores both afterwards. Finally it **keeps only the deltas that land on our lines** and
writes every other line back byte for byte, CRLF included. It reports what it could not decide
alone:

- `MANUAL MIXED`: one delta that touches our lines and pre-existing ones. Apply by hand only the
  part that is ours.
- `MANUAL MOVE`: the profile relocates one of our members (`CSReorderTypeMembers`). Move it by
  hand to where the profile puts it. Pre-existing members are never moved.
- `EDGE`: an insertion on the border between our code and existing code, usually a blank line.
  Keep it only if it separates **our** member.

Then review the resulting diff (a line that shows up as both `-` and `+` is a moved member —
revert it), and run `tools/code-style.sh <KEY> verify` for immediate feedback. `verify` re-runs
the cleanup, restores the files, and passes only when **zero deltas land on our lines**. Deltas
that remain on pre-existing lines are expected and recorded as such. The binding `verify` run is
repeated in Phase 9 §9.5 on the final commit. That run is the one the push gate reads.

⚠️ Never write `work/<KEY>/phase-06-code-style.md` by hand: only `verify` writes it, and a
hand-written marker is falsifying the gate. Only C# (`*.cs`) under `VivaAerobus.Generic.Api/` is
in scope; seeds (`Assets/Seed/**.json`) and `.csproj` files are left as the task wrote them. A
team hard rule that contradicts the profile (e.g. `const` in UPPERCASE) wins. Record the
conflict as an approved deviation in the plan, never as a silently rejected delta.

---

**Artifacts:** branch with clean commits, tests, updated configuration, Ezy style applied to the
task's lines (§6.5).

**Exit criterion:** all acceptance criteria implemented, all points of the impact matrix
addressed, `tools/code-style.sh <KEY> apply` run with every `MANUAL` delta resolved and `verify`
passing, suite green locally.

**Next:** [Phase 7 — Testing](phase-07-testing.md)
