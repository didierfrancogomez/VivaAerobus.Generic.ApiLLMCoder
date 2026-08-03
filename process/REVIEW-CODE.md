<!-- MOVED HERE from VivaAerobus.Generic.ApiLLM/llm/ — this file is Coder process methodology.
     Paths like documents/**, guidelines/**, llm/SYNC.md remain RELATIVE TO THE ApiLLM REPO ROOT
     (../VivaAerobus.Generic.ApiLLM/). Knowledge and guidelines stay there; only the procedure moved. -->

# REVIEW-CODE.md — Implementation Review Gate (the local validator)

> Called by `../CLAUDE.md` **after `SYNC.md` completes**, whenever the user brings **implemented
> code** to validate — an uncommitted working tree, a branch diff, or a PR — before pushing or
> requesting human review.
>
> **Goal:** verify the implementation against (a) the **purpose of its task** and (b) the
> **normative team rules** (`../guidelines/**`), and return a structured verdict with findings —
> the same bar the human reviewers will apply, applied earlier and at the developer's desk.
>
> ⚠️ Bound by the **evidence-first rule** (`../CLAUDE.md §Non-negotiable`): every finding cites the
> rule it violates (`STY-NN`/`ARC-NN`/`ROB-NN`/`PRC-NN`) **and** the exact code location. A concern
> no rule covers is reported as an *observation*, clearly separated — never dressed up as a rule.
>
> ⛔ **This step modifies nothing.** No edits to the code repo, no commits, no doc updates beyond
> what `SYNC.md` itself required. Illustrative ❌/✅ snippets inside a finding are fine (that is how
> the reviewers write); applying fixes is the developer's job — or a future step, never this one.
>
> **Inputs required** (ask for what is missing before reviewing):
> 1. **The change**: working tree, branch (`git -C <code-repo> diff master...<branch>`), or PR.
> 2. **The task**: the ticket / requirement — and its step-2 analysis if one exists. Without the
>    task, phases 1–2 cannot run; say so and either obtain it or deliver a **rules-only review**,
>    labelled as such (it validates compliance, not correctness of intent).

---

## Phase 0 — Context (before looking at the diff)

0. **State the docs-sync status in the first lines of the output — always** (anchor vs code HEAD),
   same rule as `ANALYZE-TASK.md` Phase 0.
1. **Load the bar**: `../guidelines/README.md` + the four category files. Note the severity
   taxonomy (🐛 bug · ❗ blocking · 🏭 refactor · ✋ style) — findings are classified with it.
2. **Restate the task** in one paragraph: what outcome the change is supposed to deliver. List its
   acceptance criteria (from the ticket or the step-2 analysis).
3. **Scope the diff**: files changed, concepts/integrations touched (locate them via
   `../documents/concepts/_catalog.md`). Open only the docs for what the diff touches.

## Phase 1 — Purpose alignment (does it do what the task asked?)

- **Map each acceptance criterion to the code that implements it.** An AC with no implementing
  code is a 🐛 finding; code implementing no AC is scope creep.
- **Scope creep / unrequested changes**: anything the diff changes that the task did not ask for —
  including visible output changes, refactors mixed into the feature, deleted code the task didn't
  mention. Flag each one (the reviewers do: "VB didn't ask for it, remove it").
- **Edge cases of the requirement**: empty, maximum, expired, duplicated, concurrent, partial —
  are the ones the task (or its analysis) called out actually handled?

## Phase 2 — Functional correctness (`ROB`)

- Logic: conditions, boundaries, null handling, impossible states.
- **Failure paths**: external call fails, empty response, timeout, concurrency. The happy path
  working is the *minimum*, not the review.
- Error handling: correct `ErrorCode` (never repurposed — `../documents/cross-module/error-codes.md`),
  no swallowed exceptions, failures visible in logs.

## Phase 3 — Blast radius (what else does this touch?)

Drive from `../documents/cross-module/dependency-map.md` (reverse index) and the concept docs:

- Shared models/services touched → list their consumers; verify the change is safe for each.
- **Contract changes** (request/response shapes, error codes): backwards compatible? Who consumes
  them (web, mobile, partners)?
- Config parts / flags the code now depends on — do they exist in every environment
  (`../documents/_meta/flags-and-rules.md`)?
- In-flight sessions: are baskets/bookings created before the change still processable after it?

## Phase 4 — Design & architecture (`ARC`)

- Code in the right place per `../documents/architecture/conventions.md` and `patterns-cqrs.md`
  (thin controller, handler per feature, builders, validators registered).
- Reuses what exists (shared services, constants, helpers) instead of duplicating it.
- DI registrations correct; domain model conventions respected.

## Phase 5 — Style (`STY`)

- Naming, dead code, formatting, language conventions. Real findings, minor severity — style
  comments must never dominate the review.

## Phase 6 — Tests (`PRC` + `../documents/operations/testing.md`)

- New behaviour has tests, **including failure paths**.
- Existing tests still valid — not weakened to pass.
- Where the area had no coverage, the change adds it (part of scope, not a follow-up).

## Phase 7 — Security & data

- Inputs validated; no hardcoded secrets; PII handled per `../documents/operations/security.md`;
  logs don't leak sensitive data.

## Phase 8 — Process & delivery (`PRC`)

- Commit/PR hygiene, release notes when applicable, kill switch (config/flag) for risky changes,
  no leftover debug artifacts.

---

## Phase 9 — Verdict and findings (the deliverable)

Always end with an explicit verdict — the same two states the team's PR cycle uses:

| Verdict | When |
|---|---|
| ✅ **APPROVED** | No 🐛/❗ findings and every acceptance criterion implemented. 🏭/✋ findings (if any) are listed for the developer to **fix or justify** before the human PR — they do not block. |
| ⛔ **CHANGES_REQUESTED** | At least one 🐛 or ❗ finding, or an acceptance criterion not implemented, or scope creep that changes visible behaviour. List exactly what blocks; re-review after fixes (the "Fixed / Done ✅" iteration, same as the human cycle). |

### Finding rules

- **Every finding**: severity emoji · rule ID (or *observation*) · `file:line` · what's wrong ·
  why (one line) · optionally a ❌/✅ snippet.
- **Order by severity**, blocking first. Within severity, by file.
- **An observation is not a rule.** Concerns without a backing guideline go in their own section;
  they do not affect the verdict. If one seems recurrent, note it as a **candidate rule** — it
  only enters `../guidelines/**` through that folder's own procedure (PR-review evidence, per
  `../guidelines/CLAUDE.md`), never from an AI review alone.
- **No opinion without anchor.** If you cannot cite a rule or a documented fact, either verify it
  in code first or leave it out.

### Output template

```markdown
## Code review — <task id / title>
**Verdict:** ✅ APPROVED / ⛔ CHANGES_REQUESTED — <one line>
**Docs sync:** anchor `<sha>` vs code HEAD `<sha>` — <in sync | N behind, reasoning from code>
**Reviewed:** <branch/diff/worktree> · <N files> · guidelines loaded (STY/ARC/ROB/PRC)

### Purpose alignment
| Acceptance criterion | Implemented by | Status |
Scope creep: <list or "none">

### Blocking findings (🐛/❗ — these set the verdict)
1. ❗ ARC-12 · `Concepts/X/Handler.cs:41` — <what> — *why:* <risk>

### Non-blocking findings (🏭/✋ — fix or justify before the human PR)
1. 🏭 STY-02 · `…` — <what>

### Observations (no rule — never block)
- <concern> <candidate rule? note it>

### Tests
<covered / gaps — absent coverage is a 🐛/❗ finding when the guidelines require it>

### What blocks (only when ⛔)
<the minimal list to flip the verdict to APPROVED>
```

---

## Anti-patterns (do not do this)

- Reviewing style before purpose — polishing code that does the wrong thing.
- Emitting findings without rule ID + location, or opinions with no anchor.
- Letting ✋ items pile onto the verdict (they never block).
- Passing the review without the task context and not saying so (rules-only reviews are labelled).
- "Fixing" the code, the docs, or the guidelines during the review.
- Reporting "no impact" without consulting the reverse index.
- Treating an `unverified` doc line as fact — verify in code or exclude it.
- Skipping the sync status line.
