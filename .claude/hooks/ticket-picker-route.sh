#!/usr/bin/env bash
# ticket-picker-route.sh — UserPromptSubmit hook (GOLDEN RULE 6, CLAUDE.md).
#
# "Which ticket can I take / what comes next / what is ready on the board?" has ONE
# answer path: the jira-next-ticket-picker skill, every step in order. Relying on the
# model to recognise the question and remember the skill is what the rule exists to
# avoid, so this hook recognises it deterministically and injects the instruction.
#
# Detection (accent- and case-insensitive, Spanish + English): a work-item noun
# (ticket, tarea, actividad, historia, issue...) together with a pick/next intent
# (tomar, retomar, sigue, siguiente, desarrollar, listo, pick, next...), or one of a
# few fixed phrases ("qué hay listo", "what should I work on"). NOT routed:
# prompts naming a concrete key (API-123 — that is ticket work, /implement or
# /continue) and slash commands.
#
# It never blocks: no match → silent; match → a plain-stdout note (same style as
# pipeline-state.sh). A false positive costs one ignorable note — the injected text
# says so. Must stay bash-3.2 compatible.

set -uo pipefail
INPUT="$(cat 2>/dev/null)" || INPUT=""

NOTE="TICKET PICKER — GOLDEN RULE 6 (CLAUDE.md): this prompt asks which Jira ticket to take, resume or develop next. Answer it ONLY by invoking the skill \`jira-next-ticket-picker\` (Skill tool) and executing ALL of its steps in order — Paso 0 includes the BLOCKING question for N (unless the user already gave a number), Paso 1 the In Progress priority check, Paso 3 every eligibility rule, Paso 5 the mandatory tables and checklist. Never answer from memory, from work/, or via tools/jira-sync. If the prompt is not actually that question, ignore this note."

if command -v python3 >/dev/null 2>&1; then
  MATCH="$(printf '%s' "$INPUT" | python3 -c '
import json, re, sys, unicodedata
try:
    p = json.load(sys.stdin).get("prompt") or ""
except Exception:
    sys.exit(0)
t = unicodedata.normalize("NFKD", p).encode("ascii", "ignore").decode().lower()
if t.lstrip().startswith("/") or re.search(r"\b[a-z][a-z0-9]*-\d+\b", t):
    sys.exit(0)
noun = r"\b(tickets?|tareas?|actividad(es)?|historias?|issues?|stor(y|ies)|tasks?|cards?|pendientes)\b"
intent = (r"\b(tomar|tomo|tomaria|agarrar|agarro|retomar|retomo|sigue|siguen|siguiente|proxim[oa]s?"
          r"|trabajar|desarrollar|continuar|empezar|arrancar|elegir|escoger|listos?|listas?"
          r"|candidat[oa]s?|recomiend\w*|pick|take|next|work on|ready|start)\b")
phrase = (r"(que hay listo|que (me )?(toca|sigue)|con cual (sigo|continuo|arranco)"
          r"|what should i (work on|pick|take)|what.s next on the board)")
if re.search(phrase, t) or (re.search(noun, t) and re.search(intent, t)):
    print("1")
' 2>/dev/null)"
else
  # Without python3: coarser ASCII-only match (accents are kept as typed).
  LOW="$(printf '%s' "$INPUT" | sed -n 's/.*"prompt"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 | tr '[:upper:]' '[:lower:]')"
  MATCH=""
  if [ -n "$LOW" ] && ! printf '%s' "$LOW" | grep -Eq '^[[:space:]]*/|[a-z][a-z0-9]*-[0-9]+'; then
    printf '%s' "$LOW" | grep -Eq '(ticket|tarea|actividad|historia|issue|task)' && \
      printf '%s' "$LOW" | grep -Eq '(tomar|retomar|sigue|siguiente|desarrollar|trabajar|listo|pick|next)' && MATCH=1
  fi
fi

[ "$MATCH" = "1" ] && echo "$NOTE"
exit 0
