# CLAUDE.md — VivaAerobus.Generic.ApiLLMCoder (Implementer agent)

> This repository is the **implementation agent** for `VivaAerobus.Generic.Api`. Its job: given a
> **Jira task**, execute the mandatory 12-phase process (`process/`), **stop if there are
> blockers**, or **implement** if it can proceed.
>
> **This file orchestrates. It does not hold the process.** Read it first and load only the phase
> at hand.

---

## ⚠️ NON-NEGOTIABLE — The five rules that never break

1. **Analysis before code, always.** Phases 0–4 are completed BEFORE writing a single line. The
   Phase 4 gate decides: open hard blockers → **STOP and ask**; verdict ✅ and zero blockers →
   proceed to implementation (phases 5–11). There is no shortcut.
2. **This repo does NOT document the system.** Knowledge about the API lives in the **ApiLLM**
   repo (`../VivaAerobus.Generic.ApiLLM/documents/**`). If work surfaces missing, stale or
   incorrect documentation, **invoke the ApiLLM pipeline** (its `CLAUDE.md` step 1 / `doc-sync`
   agent) to process it. System documentation is never written here, nor inline in an analysis as
   "new knowledge".
3. **Evidence first** — rule inherited verbatim from `../VivaAerobus.Generic.ApiLLM/CLAUDE.md`
   §"NON-NEGOTIABLE — Evidence first": never assume, never infer from names, every claim is cited
   against the code (`path/File.cs :: Symbol`), the unknown is written as `unknown`, and every
   ambiguity is a **blocking question**, never a unilateral decision.
4. **GOLDEN RULE — never work on a stale main.** `main` is the default branch and the only one
   this repo works on. Before attending ANY request, this repo is brought to `origin/main`'s
   latest commit — automated by `hooks/self-update.sh` (SessionStart + every prompt,
   fast-forward only, never destroys local work). If it reports ⛔ (offline, diverged, wrong
   branch), the request is **not attended** until the state is reconciled — or the user
   explicitly accepts working from the local copy.
5. **GOLDEN RULE — the LLM repo's guidelines govern HOW code is implemented.** The technical
   specification of how code MUST be written lives in
   `../VivaAerobus.Generic.ApiLLM/guidelines/**` (the 90 normative `STY`/`ARC`/`ROB`/`PRC` rules
   from real PR reviews) plus `documents/architecture/conventions.md` and `patterns-cqrs.md`. The
   Coder **never invents its own standard** and never contradicts those rules: every plan
   (Phase 5) cites the rule IDs it must honor, the implementation (Phase 6) complies with them,
   and the Phase 9 gate (`process/REVIEW-CODE.md`) applies that same bar — a 🐛/❗ finding blocks. If
   a guideline seems wrong or outdated, that is a finding for the ApiLLM owner, not a license to
   deviate.

---

## Repository layout — MANDATORY assumption

The three repos are **sibling folders** under the same parent directory. Every path in this repo
assumes that layout; if it does not hold, stop and ask for the real paths.

| Sibling folder | Role | Written from here? |
|---|---|---|
| `../VivaAerobus.Generic.Api` | **API** — the source code (source of truth). Default branch: `master` | ✅ Yes — the implementation (phases 6–10) |
| `../VivaAerobus.Generic.ApiLLM` | **LLM** — evidence-cited documentation + analysis pipeline | ⛔ Never directly — only via its own pipeline (`doc-sync`) |
| `../VivaAerobus.Generic.ApiLLMCoder` | **Coder** — this repo: the implementation process | Only process artifacts (matrices, plans, records) |

- API code root: `../VivaAerobus.Generic.Api/VivaAerobus.Generic.Api/src/app/VivaAerobus.Generic.Api`
- Tests root: `../VivaAerobus.Generic.Api/VivaAerobus.Generic.Api/src/tests`

---

## Pipeline — given a Jira task

```
Jira task
   │
   ▼
┌─────────────────────────────────────────────────────┐
│ STAGE A — ANALYSIS (phases 0–4) · uses the LLM repo  │
│ 0 Intake → 1 Code contrast → 2 Impact radius         │
│ → 3 Coverage/feasibility → 4 Blockers & assumptions  │
└─────────────────────────────────────────────────────┘
   │
   ▼
══ GATE ══  hard blockers? verdict ⚠️/⛔?
   │                                │
   │ ✅ zero blockers               │ ⚠️/⛔ blockers exist
   ▼                                ▼
┌──────────────────────────────┐  ⛔ STOP. Surface the blocking
│ STAGE B — EXECUTION (5–11)   │  questions (Phase 4.2 format),
│ 5 Plan → 6 Implement →       │  record the assumptions, mark the
│ 7 Test → 8 Release prep →    │  task as Blocked. Do NOT code.
│ 9 Pre-review → 10 PR →       │
│ 11 Post-merge                │
└──────────────────────────────┘
```

### Map: phase → process file → mandatory support

The methodology files `process/ANALYZE-TASK.md`, `process/change-playbook.md` and
`process/REVIEW-CODE.md` live **in this repo** (moved from the ApiLLM — process lives here;
knowledge and `guidelines/**` stay there). Bare `documents/**`/`guidelines/**` paths below are
relative to `../VivaAerobus.Generic.ApiLLM/`.

| Phase | Process file | Mandatory support |
|---|---|---|
| 0 Intake | [`process/phase-00-intake.md`](process/phase-00-intake.md) | `documents/concepts/_catalog.md` (domain terms) |
| 1 Code contrast | [`process/phase-01-code-contrast.md`](process/phase-01-code-contrast.md) | **`CLAUDE.md` step 1 (SYNC) first**, then `process/ANALYZE-TASK.md` phases 0–2 + `documents/**` |
| 2 Impact radius | [`process/phase-02-impact-radius.md`](process/phase-02-impact-radius.md) | `documents/cross-module/dependency-map.md` + `process/ANALYZE-TASK.md` phase 3 |
| 3 Coverage & feasibility | [`process/phase-03-coverage-feasibility.md`](process/phase-03-coverage-feasibility.md) | `process/ANALYZE-TASK.md` phases 4–5 |
| 4 Blockers (GATE) | [`process/phase-04-blockers.md`](process/phase-04-blockers.md) | Question rules from `process/ANALYZE-TASK.md` §Phase 5 |
| 5 Planning | [`process/phase-05-planning.md`](process/phase-05-planning.md) | `process/change-playbook.md` steps 1–6 + `guidelines/**` |
| 6 Implementation | [`process/phase-06-implementation.md`](process/phase-06-implementation.md) | `guidelines/**` (normative) + `documents/architecture/conventions.md`, `patterns-cqrs.md` |
| 7 Testing | [`process/phase-07-testing.md`](process/phase-07-testing.md) | `documents/operations/testing.md` |
| 8 Release prep | [`process/phase-08-release.md`](process/phase-08-release.md) | `documents/_meta/flags-and-rules.md` (kill switch / config parts) |
| 9 Pre-review | [`process/phase-09-pre-review.md`](process/phase-09-pre-review.md) | **`process/REVIEW-CODE.md`** — APPROVED verdict mandatory |
| 10 PR & review | [`process/phase-10-pr-review.md`](process/phase-10-pr-review.md) | — |
| 11 Post-merge & closure | [`process/phase-11-post-merge.md`](process/phase-11-post-merge.md) | **Invoke the ApiLLM's `doc-sync`** to re-document what changed |

Annexes: [checklist](process/annex-a-checklist.md) · [hotfix](process/annex-b-hotfix.md) ·
[adoption](process/annex-c-adoption.md) · [agent execution map](process/annex-d-agent-execution.md)
(who does what, Jira via `tools/jira-sync`, session model: **one entry point — a session in THIS
repo running `/implement <KEY>`**; a human-owned step is never claimed done).

### Rules that bind the pipeline

- **No phase is skipped.** Each phase has an explicit *exit criterion*; the next phase does not
  start until it is met. Rigor scales with risk (table below), but the Phase 4 gate applies
  **always**, even to trivial changes.
- **Guiding principle:** the cost of fixing a mistake multiplies ~10× per phase. This whole
  process exists to move problem discovery into phases 0–4, where a fix costs a conversation.
- **Phase 1 starts by syncing the LLM repo** (its `CLAUDE.md` step 1 / `llm/SYNC.md`). Stale docs
  ⇒ reason from the code and say so explicitly in the analysis output.
- **Every out-of-scope finding** → new ticket, never inside the current diff (Phase 6.4).
- **Hotfix / production incident** → compressed route in
  [Annex B](process/annex-b-hotfix.md); nothing is dropped, it is deferred.
- **Subagents inherit nothing.** When delegating, paste into the prompt: (a) the evidence rule,
  (b) the docs-sync status, (c) which `process/` file to follow.
- **Every phase artifact starts from `process/_templates/`** (scaffolded by `tools/new-task.sh`)
  and ends with the **handoff footer** (`phase_status` / `highest_severity` / `next_phase` /
  `blocking_reason` / `required_inputs_for_next_phase` / `evidence_paths` /
  `delivery_state_updated`), keeping `work/<KEY>/delivery-state.md` current. Process findings use
  `BLOCKER/P1/P2/P3` (a BLOCKER means the phase cannot pass); code findings keep the guidelines
  taxonomy (🐛/❗/🏭/✋).
- **Numbered traceability:** the plan numbers steps (`P-NN`) and test scenarios (`S-NN`);
  Phase 7 executes the `S-NN` matrix row by row; Phase 9 audits both lists one-to-one before
  `COMPLETENESS: VERIFIED`.
- **Validation runs are immutable:** rework starts with `tools/new-run.sh <KEY>` — it archives
  phase-07/09 + `PUSH-APPROVED` into `work/<KEY>/validation/run-NNN/` (never edited, never
  reused as evidence) and mechanically re-closes the publication gates.
- **Progress is versioned, resumable and indexed by Jira key.** Closing a phase ends with
  `tools/save-progress.sh <KEY> "<phase>"` — commits + pushes `work/<KEY>/` and regenerates the
  task index `work/README.md` — and the agent **tells the user the folder** (`work/<KEY>/`,
  board `delivery-state.md`) so they can resume anytime with `/implement <KEY>`. The Phase 0
  ticket comment links back to the workspace. Never versioned (gitignore): human signatures
  (`PUSH-APPROVED`, `HUMAN-GATE-OK`, `_PROCESS-CHANGE-OK`), `_active`, ticket dumps/attachments.

### Scaling rigor to risk

| Level | Examples | Phases that apply in full |
|---|---|---|
| **Trivial** | copy, typo, log level | 0, 1, 4 (gate), 6, 7 (suite green), 9, 10 — the artifacts for phases 2/3/5 **still exist** (the hooks require every file) but are reduced to one paragraph each stating why |
| **Normal** | bounded feature, bug without data impact | All; ADR and runbook optional |
| **Risky** | migration, contract, payments, flags, multi-repo | All, in full: ADR + runbook + tested rollback mandatory |

The classification is decided in Phase 0.1 and written into the ticket. When in doubt, one level
up. The gate artifact contract never shrinks with the level — only the depth of each artifact.

---

## Work artifacts — the contract that opens the gate (ENFORCED)

`tools/new-task.sh <KEY>` scaffolds `work/<KEY>/` (+ `delivery-state.md`, ticket fetch, `ready`
gate). Each task writes its artifacts there with **fixed names**; they are also posted as
comments on the Jira ticket (the ticket is the project's memory — `deliver`/Annex D §D.2). The hooks in `.claude/` verify
these files **mechanically** — until they exist, every write to the API repo is **blocked**
(`PreToolUse` deny), and `git push` / `gh pr create` stay blocked until phases 7 and 9 pass, the
approved commit is still HEAD, **and the user has approved publication** (`PUSH-APPROVED`):

| Artifact (in `work/<KEY>/`) | Produced by | Unlocks |
|---|---|---|
| `../_active` (contains the KEY) | Phase 0 | fallback task identity (see resolution rule below) |
| `phase-00-intake.md` | Phase 0 | — |
| `phase-01-contrast.md` | Phase 1 | — |
| `phase-02-impact-matrix.md` | Phase 2 | — |
| `phase-03-feasibility.md` | Phase 3 | — |
| `phase-04-verdict.md` with exactly ONE line `VERDICT: ✅` (or `⚠️`/`⛔`) at column 0 | Phase 4 | — |
| `phase-05-plan.md` (ends with a `## Deviations (approved)` section) | Phase 5 | **writes to the API repo** (together with everything above and verdict ✅) |
| `phase-07-testing.md` with the line `TESTS: GREEN` + full-suite output | Phase 7 | required for push/PR |
| `phase-09-pre-review.md` with `REVIEW-CODE: APPROVED`, `VALIDATED-SHA: <commit>`, `COMPLETENESS: VERIFIED`, `DEVIATIONS: NONE\|APPROVED-AND-DOCUMENTED` | Phase 9 | **`git push` / `gh pr create`** — void (denied) if the code-repo HEAD drifts from `VALIDATED-SHA` |
| `PUSH-APPROVED` | **human** | publication: the user's explicit approval of the push + PR (Phase 10 §10.0) |
| `HUMAN-GATE-REQUIRED` (*risky* level) → `HUMAN-GATE-OK` | human | the human creates it by hand (`touch`); **the agent is forbidden from creating it** |

Human-signature files (`HUMAN-GATE-OK`, `PUSH-APPROVED`, `work/_PROCESS-CHANGE-OK`) are **always
denied to the agent** — the hooks reject any attempt to create or touch them.

**Task resolution — multiple plans in parallel.** The gate reads the **branch checked out in the
code repo**: the Jira key in `feature/API-<n>/<kebab-slug>` (PRC-102, Phase 6.1) binds the branch
to `work/API-N/`, so several plans can be in flight, each gated by its own artifacts.
`work/_active` is the fallback when the branch has no parseable key. Work folders use the
uppercase Jira key.

Integrity rules: artifacts are written **upon completing the phase's work, never before** —
writing a marker without doing the work is falsifying the gate. Marker lines are matched
**anchored at column 0** (a quoted template or indented copy never opens a gate). A `⚠️`/`⛔`
verdict in `phase-04-verdict.md` keeps the gate closed: the hook rejects code and the agent
surfaces the blocking questions. The gate state is injected into every prompt
(`hooks/pipeline-state.sh`), so "I didn't know which phase I was in" does not exist.

Publication rules (all hook-enforced): the PR carries **ONE clean squashed commit** with the
whole solution (Phase 9 §9.3), `VALIDATED-SHA` anchors the REVIEW-CODE approval to that commit
(any later commit voids it), Phase 9 re-validates **Jira task + plan + code** completeness and
audits deviations against the plan, and **nothing is pushed without the user's explicit
approval** (`PUSH-APPROVED`, Phase 10 §10.0).

## Conventions of this repo

- `.claude/` = **enforcement** (committed): `settings.json` wires the hooks (+ sibling-repo
  `additionalDirectories`); `self-update.sh` fast-forwards this repo to `origin/main` before
  every prompt (rule 4); `pipeline-state.sh` injects the gate state into every prompt;
  `guard-writes.sh`/`guard-bash.sh` block API-repo writes and publication until the artifact
  contract is met — a deterministic guard, not a sandbox (outer layers: PR review, GitHub
  permissions). Test suite: `.claude/hooks/tests/run-tests.sh` — run it after any hook change.
- `tools/` = automation: `new-task.sh` (scaffold + intake), `new-run.sh` (immutable runs),
  `jira-sync/` (the Jira bridge — reads free; writes only via Phase 10 §10.1b behind the user's
  approval). `.claude/commands/implement.md` = `/implement <KEY>`, the single entry point.
- `process/` = the mandatory process: one file per phase + the methodology
  (`ANALYZE-TASK`/`change-playbook`/`REVIEW-CODE`) + `_templates/`. Modified only by team decision
  (process retro, Phase 11.9) — **hook-enforced**: writes to `process/`, `CLAUDE.md` and
  `.claude/` are denied unless the human has created `work/_PROCESS-CHANGE-OK` (and deletes it
  when the agreed change is done).
- `work/` is **versioned** (progress = resumable memory; Annex D §D.3) — except human
  signatures, `_active` and ticket dumps (see `.gitignore`). Authored artifacts never contain
  credentials; never prune `work/<KEY>/` while the ticket is open.
- Process files are written in **English**; citations to code and to the sibling repos keep their
  real names.
- `CLAUDE.md` stays under ~200 lines: the *rules* live here; the *procedure* lives in `process/`
  and is loaded on demand (same progressive-disclosure discipline as the ApiLLM).
