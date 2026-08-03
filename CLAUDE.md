# CLAUDE.md — VivaAerobus.Generic.ApiLLMCoder (Implementer agent)

> This repository is the **implementation agent** for `VivaAerobus.Generic.Api`. Its job: given a
> **Jira task**, execute the mandatory 12-phase process (`process/`), **stop if there are
> blockers**, or **implement** if it can proceed.
>
> **This file orchestrates. It does not hold the process.** Read it first and load only the phase
> at hand.

---

## ⚠️ NON-NEGOTIABLE — The three rules that never break

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

### Map: phase → process file → LLM-repo artifact it uses

| Phase | Process file | Mandatory support in `../VivaAerobus.Generic.ApiLLM/` |
|---|---|---|
| 0 Intake | [`process/phase-00-intake.md`](process/phase-00-intake.md) | `documents/concepts/_catalog.md` (domain terms) |
| 1 Code contrast | [`process/phase-01-code-contrast.md`](process/phase-01-code-contrast.md) | **`CLAUDE.md` step 1 (SYNC) first**, then `llm/ANALYZE-TASK.md` phases 0–2 + `documents/**` |
| 2 Impact radius | [`process/phase-02-impact-radius.md`](process/phase-02-impact-radius.md) | `documents/cross-module/dependency-map.md` + `llm/ANALYZE-TASK.md` phase 3 |
| 3 Coverage & feasibility | [`process/phase-03-coverage-feasibility.md`](process/phase-03-coverage-feasibility.md) | `llm/ANALYZE-TASK.md` phases 4–5 |
| 4 Blockers (GATE) | [`process/phase-04-blockers.md`](process/phase-04-blockers.md) | Question rules from `llm/ANALYZE-TASK.md` §Phase 5 |
| 5 Planning | [`process/phase-05-planning.md`](process/phase-05-planning.md) | `llm/change-playbook.md` steps 1–6 + `guidelines/**` |
| 6 Implementation | [`process/phase-06-implementation.md`](process/phase-06-implementation.md) | `guidelines/**` (normative) + `documents/architecture/conventions.md`, `patterns-cqrs.md` |
| 7 Testing | [`process/phase-07-testing.md`](process/phase-07-testing.md) | `documents/operations/testing.md` |
| 8 Release prep | [`process/phase-08-release.md`](process/phase-08-release.md) | `documents/_meta/flags-and-rules.md` (kill switch / config parts) |
| 9 Pre-review | [`process/phase-09-pre-review.md`](process/phase-09-pre-review.md) | **`llm/REVIEW-CODE.md`** — APPROVED verdict mandatory |
| 10 PR & review | [`process/phase-10-pr-review.md`](process/phase-10-pr-review.md) | — |
| 11 Post-merge & closure | [`process/phase-11-post-merge.md`](process/phase-11-post-merge.md) | **Invoke the ApiLLM's `doc-sync`** to re-document what changed |

Annexes: [daily checklist](process/annex-a-checklist.md) ·
[hotfix route](process/annex-b-hotfix.md) · [team adoption](process/annex-c-adoption.md)

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
  (b) the docs-sync status, (c) which `process/` or `llm/` file to follow.

### Scaling rigor to risk

| Level | Examples | Phases that apply in full |
|---|---|---|
| **Trivial** | copy, typo, log level | 0, 1, 4 (gate), 6, 9, 10 — matrices reduced to a paragraph |
| **Normal** | bounded feature, bug without data impact | All; ADR and runbook optional |
| **Risky** | migration, contract, payments, flags, multi-repo | All, in full: ADR + runbook + tested rollback mandatory |

The classification is decided in Phase 0.1 and written into the ticket. When in doubt, one level
up.

---

## Work artifacts — the contract that opens the gate (ENFORCED)

Each task writes its artifacts into `work/<KEY>/` with **fixed names**; they are also posted as
comments on the Jira ticket (the ticket is the project's memory). The hooks in `.claude/` verify
these files **mechanically** — until they exist, every write to the API repo is **blocked**
(`PreToolUse` deny), and `git push` / `gh pr create` stay blocked until Phase 9 passes:

| Artifact (in `work/<KEY>/`) | Produced by | Unlocks |
|---|---|---|
| `../_active` (contains the KEY) | Phase 0 | fallback task identity (see resolution rule below) |
| `phase-00-intake.md` | Phase 0 | — |
| `phase-01-contrast.md` | Phase 1 | — |
| `phase-02-impact-matrix.md` | Phase 2 | — |
| `phase-03-feasibility.md` | Phase 3 | — |
| `phase-04-verdict.md` with the line `VERDICT: ✅` (or `⚠️`/`⛔`) | Phase 4 | — |
| `phase-05-plan.md` | Phase 5 | **writes to the API repo** (together with everything above and verdict ✅) |
| `phase-09-pre-review.md` with the line `REVIEW-CODE: APPROVED` | Phase 9 | **`git push` / `gh pr create`** |
| `HUMAN-GATE-REQUIRED` (*risky* level) → `HUMAN-GATE-OK` | human | the human creates it by hand (`touch`); **the agent is forbidden from creating it** |

**Task resolution — multiple plans in parallel.** The gate decides *which* task a code-repo
mutation belongs to by reading the **branch checked out in the code repo**: branch names follow
`type/KEY-123-short-desc` (Phase 6.1), and the Jira key in the branch binds that branch to
`work/KEY-123/`. Each plan therefore lives on its own branch and is gated by its own artifacts —
several plans can be in flight at once without touching `_active`. `work/_active` is the
**fallback** when the branch carries no parseable key (analysis stage, `master`, detached HEAD).
Work folders are named with the uppercase Jira key.

Integrity rules: artifacts are written **upon completing the phase's work, never before** —
writing the marker without doing the work is falsifying the gate. A `⚠️`/`⛔` verdict in
`phase-04-verdict.md` keeps the gate closed: the hook rejects code and the agent surfaces the
blocking questions. The gate state is injected into every prompt (`hooks/pipeline-state.sh`), so
"I didn't know which phase I was in" does not exist.

## Conventions of this repo

- `.claude/` = **enforcement** (committed, so every dev gets it on clone): `settings.json` wires
  the hooks; `hooks/pipeline-state.sh` injects the gate state into every prompt;
  `hooks/guard-writes.sh` and `hooks/guard-bash.sh` block API-repo writes/mutations and
  publication until the artifact contract is met. They are a deterministic guard, not a sandbox:
  the outer layers remain PR review and GitHub permissions.
- `process/` = the mandatory process, one file per phase. Modified only by team decision
  (process retro, Phase 11.9).
- Process files are written in **English**; citations to code and to the sibling repos keep their
  real names.
- `CLAUDE.md` stays under ~200 lines: the *rules* live here; the *procedure* lives in `process/`
  and is loaded on demand (same progressive-disclosure discipline as the ApiLLM).
