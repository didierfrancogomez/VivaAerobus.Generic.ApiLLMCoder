# CLAUDE.md — VivaAerobus.Generic.ApiLLMCoder (Agente implementador)

> Este repositorio es el **agente de implementación** para `VivaAerobus.Generic.Api`. Su trabajo:
> dada una **tarea de Jira**, ejecutar el proceso obligatorio de 12 fases (`process/`), **detenerse
> si hay temas bloqueantes**, o **implementar** si puede continuar.
>
> **Este archivo orquesta. No contiene el proceso.** Léelo primero y carga solo la fase que toca.

---

## ⚠️ NO NEGOCIABLE — Las tres reglas que nunca se rompen

1. **Análisis antes de código, siempre.** Las fases 0–4 se completan ANTES de escribir una sola
   línea. El gate de la Fase 4 decide: bloqueantes duros abiertos → **DETENERSE y preguntar**;
   veredicto ✅ y cero bloqueantes → continuar a implementación (fases 5–11). No hay atajo.
2. **Este repo NO documenta el sistema.** El conocimiento del API vive en el repo **ApiLLM**
   (`../VivaAerobus.Generic.ApiLLM/documents/**`). Si durante el trabajo se detecta documentación
   faltante, desactualizada o incorrecta, se **invoca el pipeline del ApiLLM** (su `CLAUDE.md`
   paso 1 / agente `doc-sync`) para que la procese. Nunca se escribe documentación del sistema aquí,
   ni inline en el análisis como "conocimiento nuevo".
3. **Evidencia primero** — regla heredada íntegra de `../VivaAerobus.Generic.ApiLLM/CLAUDE.md`
   §"NON-NEGOTIABLE — Evidence first": nunca asumir, nunca inferir de nombres, toda afirmación se
   cita contra el código (`path/File.cs :: Symbol`), lo desconocido se escribe como `unknown`, y
   toda ambigüedad es una **pregunta bloqueante**, jamás una decisión unilateral.

---

## Layout de repositorios — supuesto OBLIGATORIO

Los tres repos son **carpetas hermanas** bajo el mismo directorio padre. Todas las rutas de este
repo asumen ese layout; si no se cumple, detenerse y pedir las rutas reales.

| Carpeta hermana | Rol | Se escribe aquí? |
|---|---|---|
| `../VivaAerobus.Generic.Api` | **API** — el código fuente (source of truth). Branch por defecto: `master` | ✅ Sí — la implementación (fases 6–10) |
| `../VivaAerobus.Generic.ApiLLM` | **LLM** — documentación evidenciada + pipeline de análisis | ⛔ Nunca directo — solo vía su propio pipeline (`doc-sync`) |
| `../VivaAerobus.Generic.ApiLLMCoder` | **Coder** — este repo: el proceso de implementación | Solo artefactos de proceso (matrices, planes, registros) |

- Código root del API: `../VivaAerobus.Generic.Api/VivaAerobus.Generic.Api/src/app/VivaAerobus.Generic.Api`
- Tests root: `../VivaAerobus.Generic.Api/VivaAerobus.Generic.Api/src/tests`

---

## Pipeline — dada una tarea de Jira

```
Jira task
   │
   ▼
┌─────────────────────────────────────────────────────┐
│ ETAPA A — ANÁLISIS (fases 0–4) · usa el repo LLM     │
│ 0 Intake → 1 Contraste código → 2 Radio de impacto   │
│ → 3 Cobertura/viabilidad → 4 Bloqueantes y supuestos │
└─────────────────────────────────────────────────────┘
   │
   ▼
══ GATE ══  ¿bloqueantes duros? ¿veredicto ⚠️/⛔?
   │                                │
   │ ✅ cero bloqueantes            │ ⚠️/⛔ hay bloqueantes
   ▼                                ▼
┌──────────────────────────────┐  ⛔ DETENERSE. Emitir preguntas
│ ETAPA B — EJECUCIÓN (5–11)   │  bloqueantes (formato Fase 4.2),
│ 5 Plan → 6 Implementar →     │  registrar supuestos, marcar la
│ 7 Testear → 8 Liberación →   │  tarea como Blocked. NO codificar.
│ 9 Pre-review → 10 PR →       │
│ 11 Post-merge                │
└──────────────────────────────┘
```

### Mapa fase → archivo → artefacto del repo LLM que usa

| Fase | Archivo del proceso | Apoyo obligatorio en `../VivaAerobus.Generic.ApiLLM/` |
|---|---|---|
| 0 Intake | [`process/fase-00-intake.md`](process/fase-00-intake.md) | `documents/concepts/_catalog.md` (términos del dominio) |
| 1 Contraste vs código | [`process/fase-01-contraste-codigo.md`](process/fase-01-contraste-codigo.md) | **`CLAUDE.md` paso 1 (SYNC) primero**, luego `llm/ANALYZE-TASK.md` fases 0–2 + `documents/**` |
| 2 Radio de impacto | [`process/fase-02-radio-impacto.md`](process/fase-02-radio-impacto.md) | `documents/cross-module/dependency-map.md` + `llm/ANALYZE-TASK.md` fase 3 |
| 3 Cobertura y viabilidad | [`process/fase-03-cobertura-viabilidad.md`](process/fase-03-cobertura-viabilidad.md) | `llm/ANALYZE-TASK.md` fases 4–5 |
| 4 Bloqueantes (GATE) | [`process/fase-04-bloqueantes.md`](process/fase-04-bloqueantes.md) | Reglas de preguntas de `llm/ANALYZE-TASK.md` §Phase 5 |
| 5 Planeación | [`process/fase-05-planeacion.md`](process/fase-05-planeacion.md) | `llm/change-playbook.md` pasos 1–6 + `guidelines/**` |
| 6 Implementación | [`process/fase-06-implementacion.md`](process/fase-06-implementacion.md) | `guidelines/**` (normativo) + `documents/architecture/conventions.md`, `patterns-cqrs.md` |
| 7 Testing | [`process/fase-07-testing.md`](process/fase-07-testing.md) | `documents/operations/testing.md` |
| 8 Liberación | [`process/fase-08-liberacion.md`](process/fase-08-liberacion.md) | `documents/_meta/flags-and-rules.md` (kill switch / config parts) |
| 9 Pre-review | [`process/fase-09-pre-review.md`](process/fase-09-pre-review.md) | **`llm/REVIEW-CODE.md`** — veredicto APPROVED obligatorio |
| 10 PR y revisión | [`process/fase-10-pr-revision.md`](process/fase-10-pr-revision.md) | — |
| 11 Post-merge y cierre | [`process/fase-11-post-merge.md`](process/fase-11-post-merge.md) | **Invocar `doc-sync` del ApiLLM** para re-documentar lo cambiado |

Anexos: [checklist diario](process/anexo-a-checklist.md) ·
[ruta hotfix](process/anexo-b-hotfix.md) · [implantación en el equipo](process/anexo-c-implantacion.md)

### Reglas que atan el pipeline

- **Ninguna fase se salta.** Cada fase tiene *criterio de salida* explícito; no se pasa a la
  siguiente sin cumplirlo. El rigor se escala al riesgo (tabla abajo), pero el gate de la Fase 4
  aplica **siempre**, incluso en cambios triviales.
- **Principio rector:** el costo de corregir un error se multiplica ~10× por fase. Todo el proceso
  existe para mover el descubrimiento de problemas a las fases 0–4, donde corregir cuesta una
  conversación.
- **La Fase 1 empieza sincronizando el repo LLM** (su `CLAUDE.md` paso 1 / `llm/SYNC.md`). Docs
  stale ⇒ razonar desde el código y decirlo explícitamente en el output del análisis.
- **Todo hallazgo fuera de alcance** → ticket nuevo, nunca dentro del diff actual (Fase 6.4).
- **Hotfix / incidente en producción** → ruta comprimida del
  [Anexo B](process/anexo-b-hotfix.md); nada se elimina, se posterga.
- **Subagentes no heredan nada.** Al delegar, pegar en el prompt: (a) la regla de evidencia, (b) el
  estado de sync de los docs, (c) qué archivo de `process/` o de `llm/` seguir.

### Escalado de rigor al riesgo

| Nivel | Ejemplos | Fases que aplican completas |
|---|---|---|
| **Trivial** | texto, typo, log level | 0, 1, 4 (gate), 6, 9, 10 — matrices reducidas a un párrafo |
| **Normal** | feature acotada, bug sin datos | Todas; ADR y runbook opcionales |
| **Riesgoso** | migración, contrato, pagos, flags, multi-repo | Todas, completas: ADR + runbook + rollback probado obligatorios |

La clasificación se decide en la Fase 0.1 y se escribe en el ticket. En duda, un nivel arriba.

---

## Artefactos de trabajo — el contrato que abre el gate (ENFORCED)

Cada tarea escribe sus artefactos en `work/<CLAVE>/` con **nombres fijos**; además se publican como
comentarios en el ticket de Jira (el ticket es la memoria del proyecto). Los hooks de `.claude/`
verifican estos archivos **mecánicamente** — hasta que existen, toda escritura en el repo del API
está **bloqueada** (deny en `PreToolUse`), y `git push` / `gh pr create` lo están hasta pasar la
Fase 9:

| Artefacto (en `work/<CLAVE>/`) | Lo produce | Desbloquea |
|---|---|---|
| `../_active` (contiene la CLAVE) | Fase 0 | identifica la tarea activa |
| `fase-00-intake.md` | Fase 0 | — |
| `fase-01-contraste.md` | Fase 1 | — |
| `fase-02-matriz-impacto.md` | Fase 2 | — |
| `fase-03-viabilidad.md` | Fase 3 | — |
| `fase-04-veredicto.md` con línea `VEREDICTO: ✅` (o `⚠️`/`⛔`) | Fase 4 | — |
| `fase-05-plan.md` | Fase 5 | **escrituras en el repo del API** (junto con todo lo anterior y veredicto ✅) |
| `fase-09-pre-review.md` con línea `REVIEW-CODE: APPROVED` | Fase 9 | **`git push` / `gh pr create`** |
| `REQUIERE-GATE-HUMANO` (nivel *riesgoso*) → `GATE-HUMANO-OK` | humano | el humano lo crea a mano (`touch`); **el agente tiene prohibido crearlo** |

Reglas de integridad: los artefactos se escriben **al completar el trabajo de la fase, nunca
antes** — escribir el marcador sin hacer el trabajo es falsificar el gate. Un veredicto `⚠️`/`⛔`
en `fase-04-veredicto.md` mantiene el gate cerrado: el hook rechaza el código y el agente emite las
preguntas bloqueantes. El estado del gate se inyecta en cada prompt (`hooks/pipeline-state.sh`),
así que "no sabía en qué fase iba" no existe.

## Convenciones de este repo

- `.claude/` = **enforcement** (committeado, cada dev lo recibe al clonar): `settings.json` cablea
  los hooks; `hooks/pipeline-state.sh` inyecta el estado del gate en cada prompt;
  `hooks/guard-writes.sh` y `hooks/guard-bash.sh` bloquean escrituras/mutaciones del repo del API
  y la publicación hasta cumplir el contrato de artefactos. Son un guard determinista, no un
  sandbox: la capa externa siguen siendo el PR review y los permisos de GitHub.
- `process/` = el proceso obligatorio, un archivo por fase. Se modifica solo por decisión de
  equipo (retro de proceso, Fase 11.9).
- Los archivos del proceso están en **español** (idioma del equipo); las citas a código y a los
  repos hermanos conservan sus nombres reales.
- `CLAUDE.md` se mantiene bajo ~200 líneas: aquí viven las *reglas*; el *procedimiento* vive en
  `process/` y se carga bajo demanda (misma disciplina de progressive disclosure que el ApiLLM).
