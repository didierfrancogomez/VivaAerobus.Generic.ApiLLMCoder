#!/usr/bin/env bash
# lib-gate.sh — shared helpers for the Coder pipeline gate.
# Sourced by pipeline-state.sh, guard-writes.sh and guard-bash.sh.
#
# The gate is DETERMINISTIC: it checks that the per-task artifacts exist under
# work/<KEY>/ with the required markers. It cannot judge their quality — that
# is what the process files and the human review are for — but it makes
# skipping a phase impossible by accident: the write is denied until the
# artifact exists.
#
# Artifact contract (fixed names, defined in ../CLAUDE.md):
#   work/_active                        ← key of the task in progress (one line)
#   work/<KEY>/fase-00-intake.md
#   work/<KEY>/fase-01-contraste.md
#   work/<KEY>/fase-02-matriz-impacto.md
#   work/<KEY>/fase-03-viabilidad.md
#   work/<KEY>/fase-04-veredicto.md     ← must contain "VEREDICTO: ✅" to open the gate
#   work/<KEY>/fase-05-plan.md          ← required before any code write
#   work/<KEY>/fase-09-pre-review.md    ← must contain "REVIEW-CODE: APPROVED" before push/PR
#   work/<KEY>/REQUIERE-GATE-HUMANO     ← optional (riesgoso level): if present,
#   work/<KEY>/GATE-HUMANO-OK             a HUMAN must create this file by hand
#
# Must stay bash-3.2 compatible (macOS default bash).

GATE_HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODER_ROOT="$(cd "$GATE_HOOK_DIR/../.." && pwd)"
WORK_DIR="$CODER_ROOT/work"

# The code repo is a sibling folder. Note: its name is a prefix of this repo's
# name and of the ApiLLM repo's name — match it exactly, never by substring.
CODE_REPO="$(cd "$CODER_ROOT/.." 2>/dev/null && pwd)/VivaAerobus.Generic.Api"

gate_active_key() {
  [ -f "$WORK_DIR/_active" ] || return 1
  head -1 "$WORK_DIR/_active" | tr -d '[:space:]'
}

# Prints the missing analysis artifacts (phases 0-5) for a task key, one per
# line. Empty output = analysis gate satisfied.
gate_missing_analysis() {
  KEY="$1"; DIR="$WORK_DIR/$KEY"
  [ -f "$DIR/fase-00-intake.md" ]         || echo "work/$KEY/fase-00-intake.md (Fase 0)"
  [ -f "$DIR/fase-01-contraste.md" ]      || echo "work/$KEY/fase-01-contraste.md (Fase 1)"
  [ -f "$DIR/fase-02-matriz-impacto.md" ] || echo "work/$KEY/fase-02-matriz-impacto.md (Fase 2)"
  [ -f "$DIR/fase-03-viabilidad.md" ]     || echo "work/$KEY/fase-03-viabilidad.md (Fase 3)"
  if [ ! -f "$DIR/fase-04-veredicto.md" ]; then
    echo "work/$KEY/fase-04-veredicto.md (Fase 4 — el GATE)"
  elif ! grep -q "VEREDICTO: ✅" "$DIR/fase-04-veredicto.md" 2>/dev/null; then
    if grep -q "VEREDICTO: ⚠️\|VEREDICTO: ⛔" "$DIR/fase-04-veredicto.md" 2>/dev/null; then
      echo "VEREDICTO-NO-APROBADO"
    else
      echo "work/$KEY/fase-04-veredicto.md sin linea 'VEREDICTO: ✅' (Fase 4)"
    fi
  fi
  [ -f "$DIR/fase-05-plan.md" ]           || echo "work/$KEY/fase-05-plan.md (Fase 5)"
  if [ -f "$DIR/REQUIERE-GATE-HUMANO" ] && [ ! -f "$DIR/GATE-HUMANO-OK" ]; then
    echo "GATE-HUMANO-PENDIENTE"
  fi
}

# Prints missing pre-review artifacts for push/PR. Empty = ok.
gate_missing_prereview() {
  KEY="$1"; DIR="$WORK_DIR/$KEY"
  if [ ! -f "$DIR/fase-09-pre-review.md" ]; then
    echo "work/$KEY/fase-09-pre-review.md (Fase 9)"
  elif ! grep -q "REVIEW-CODE: APPROVED" "$DIR/fase-09-pre-review.md" 2>/dev/null; then
    echo "work/$KEY/fase-09-pre-review.md sin linea 'REVIEW-CODE: APPROVED' (Fase 9 — correr llm/REVIEW-CODE.md del ApiLLM)"
  fi
}

# Emits a PreToolUse deny decision and exits 0 (Claude Code reads the JSON).
gate_deny() {
  REASON="$1"
  if command -v python3 >/dev/null 2>&1; then
    python3 -c '
import json,sys
print(json.dumps({"hookSpecificOutput": {
  "hookEventName": "PreToolUse",
  "permissionDecision": "deny",
  "permissionDecisionReason": sys.argv[1]}}))' "$REASON" 2>/dev/null && exit 0
  fi
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Blocked by pipeline gate: analysis artifacts missing under work/<KEY>/. See CLAUDE.md."}}\n'
  exit 0
}

# Builds the full deny message for a code write, given the missing list.
gate_deny_message() {
  KEY="$1"; MISSING="$2"; ACTION="$3"
  if printf '%s' "$MISSING" | grep -q "VEREDICTO-NO-APROBADO"; then
    printf '⛔ GATE (Fase 4): el veredicto registrado en work/%s/fase-04-veredicto.md es ⚠️/⛔. El pipeline exige DETENERSE: emitir las preguntas bloqueantes al usuario y NO %s. Solo un veredicto "VEREDICTO: ✅" (tras resolver los bloqueantes con el solicitante) abre el gate. Ver process/fase-04-bloqueantes.md.' "$KEY" "$ACTION"
    return
  fi
  if printf '%s' "$MISSING" | grep -q "GATE-HUMANO-PENDIENTE"; then
    printf '⛔ GATE HUMANO: la tarea %s esta marcada como riesgosa (work/%s/REQUIERE-GATE-HUMANO). Un humano debe aprobar el plan creando el archivo work/%s/GATE-HUMANO-OK manualmente (touch work/%s/GATE-HUMANO-OK). El agente tiene PROHIBIDO crear ese archivo — pidele al usuario que lo cree si el plan ya fue revisado.' "$KEY" "$KEY" "$KEY" "$KEY"
    return
  fi
  printf '⛔ GATE DEL PIPELINE: no se puede %s — faltan artefactos de las fases 0-5 para la tarea %s:\n%s\nCompleta las fases en orden (process/fase-NN-*.md) y registra cada artefacto en work/%s/. El gate de la Fase 4 exige "VEREDICTO: ✅" antes de tocar codigo.' "$ACTION" "$KEY" "$MISSING" "$KEY"
}
