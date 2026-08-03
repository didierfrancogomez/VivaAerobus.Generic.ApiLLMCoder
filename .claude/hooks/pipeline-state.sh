#!/usr/bin/env bash
# pipeline-state.sh — SessionStart + UserPromptSubmit hook.
# Injects the DETERMINISTIC pipeline state into context on every prompt, so the
# agent can never claim ignorance of which phase each task is in. Read-only.

set -uo pipefail
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HOOK_DIR/lib-gate.sh"

echo "PIPELINE GATE (Coder) — estado determinista de work/:"

if [ ! -d "$WORK_DIR" ] || [ -z "$(ls -A "$WORK_DIR" 2>/dev/null | grep -v '^_active$' || true)" ]; then
  echo "- Sin tareas activas. Al recibir una tarea de Jira: crear work/<CLAVE>/, escribir la clave en work/_active y ejecutar las fases en orden (process/). El hook PreToolUse BLOQUEA toda escritura en el repo del API hasta que existan los artefactos de las fases 0-5 con 'VEREDICTO: ✅'."
  exit 0
fi

ACTIVE="$(gate_active_key || echo "")"
[ -n "$ACTIVE" ] && echo "- Tarea activa (work/_active): $ACTIVE" || echo "- ⚠️ work/_active no existe — el gate denegara escrituras de codigo hasta definirlo."

for DIR in "$WORK_DIR"/*/; do
  [ -d "$DIR" ] || continue
  KEY="$(basename "$DIR")"
  MISSING="$(gate_missing_analysis "$KEY")"
  if [ -z "$MISSING" ]; then
    PRE="$(gate_missing_prereview "$KEY")"
    if [ -z "$PRE" ]; then
      echo "- $KEY: fases 0-5 completas ✅ · pre-review APPROVED ✅ — push/PR habilitado (fases 10-11 pendientes de evidencia)."
    else
      echo "- $KEY: fases 0-5 completas ✅ — implementacion habilitada. Push/PR BLOQUEADO: falta $PRE"
    fi
  elif printf '%s' "$MISSING" | grep -q "VEREDICTO-NO-APROBADO"; then
    echo "- $KEY: ⛔ DETENIDA en el gate (veredicto ⚠️/⛔ en fase-04-veredicto.md). Emitir preguntas bloqueantes; NO codificar."
  else
    N=$(printf '%s\n' "$MISSING" | grep -c . || true)
    echo "- $KEY: gate CERRADO — faltan $N artefacto(s) de analisis: $(printf '%s' "$MISSING" | tr '\n' ';' )"
  fi
done

echo "Regla: las fases se ejecutan en orden y cada una deja su artefacto en work/<CLAVE>/ ANTES de pasar a la siguiente (contrato en CLAUDE.md). Escribir un artefacto sin haber hecho el trabajo de la fase es falsificar el gate — prohibido."
exit 0
