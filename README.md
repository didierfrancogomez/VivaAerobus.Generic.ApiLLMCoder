# VivaAerobus.Generic.ApiLLMCoder

**Implementation** agent for `VivaAerobus.Generic.Api`. Given a Jira task, it runs the mandatory
12-phase process: analyzes (phases 0–4), **stops if there are blockers**, and implements
(phases 5–11) only on a ✅ verdict.

- **Entry point:** open a Claude Code session HERE and run **`/implement API-9999`** — it
  scaffolds, fetches the ticket, gates and walks the 12 phases. [`CLAUDE.md`](CLAUDE.md) is the
  orchestrator (pipeline, gates, repo layout); `tools/` holds the automation (`new-task.sh`,
  `new-run.sh`, the `jira-sync` bridge).
- **The process:** [`process/`](process/) — one file per phase + annexes (daily checklist, hotfix
  route, team adoption guide, agent execution map).

It works together with two sibling repos (same parent directory):

| Repo | Role |
|---|---|
| `../VivaAerobus.Generic.Api` | The code — where implementation happens |
| `../VivaAerobus.Generic.ApiLLM` | Evidence-cited documentation + analysis pipeline (SYNC / ANALYZE-TASK / REVIEW-CODE / guidelines) |

This repo **does not document the system** (the ApiLLM pipeline does) and **holds no API code** —
only the process and the per-task work artifacts (`work/<KEY>/`).
