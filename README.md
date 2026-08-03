# VivaAerobus.Generic.ApiLLMCoder

Agente de **implementación** para `VivaAerobus.Generic.Api`. Dada una tarea de Jira, ejecuta el
proceso obligatorio de 12 fases: analiza (fases 0–4), **se detiene si hay bloqueantes**, e
implementa (fases 5–11) solo con veredicto ✅.

- **Punto de entrada:** [`CLAUDE.md`](CLAUDE.md) — el orquestador (pipeline, gate, layout de repos).
- **El proceso:** [`process/`](process/) — un archivo por fase + anexos (checklist diario, ruta
  hotfix, guía de implantación).

Trabaja en conjunto con dos repos hermanos (mismo directorio padre):

| Repo | Rol |
|---|---|
| `../VivaAerobus.Generic.Api` | El código — donde se implementa |
| `../VivaAerobus.Generic.ApiLLM` | Documentación evidenciada + pipeline de análisis (SYNC / ANALYZE-TASK / REVIEW-CODE / guidelines) |

Este repo **no documenta el sistema** (eso lo hace el pipeline del ApiLLM) y **no contiene código
del API** — solo el proceso y los artefactos de trabajo por tarea (`work/<CLAVE>/`).
