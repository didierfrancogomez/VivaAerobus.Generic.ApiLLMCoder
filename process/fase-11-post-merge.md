# Fase 11 — Post-merge, verificación y cierre

> **Pregunta que responde:** ¿funcionó en producción y quedó cerrado el ciclo?
> **Paso OBLIGATORIO con el repo LLM:** al mergear, el código cambió ⇒ los docs del ApiLLM quedan
> stale por definición. **Invocar el pipeline de sync del ApiLLM** (su `CLAUDE.md` paso 1 /
> `llm/SYNC.md`, agente `doc-sync`) para re-documentar lo alterado (endpoints, contratos, reglas,
> códigos de error, aristas del dependency-map) y publicar. Este repo NUNCA edita `documents/**`
> directamente — está protegido por hooks del ApiLLM y los cambios manuales se auto-descartan.

**Objetivo:** confirmar en la realidad y cerrar el ciclo de aprendizaje. Sin esta fase, el proceso
no mejora.

1. **Verificar el despliegue** en cada entorno por el que pasa; ejecutar el smoke test del runbook.
2. **Ejecutar migraciones y backfills** según el runbook, verificando conteos y consistencia.
3. **Prender el flag progresivamente** (interno → % pequeño → total), verificando métricas en cada
   paso.
4. **Monitorear activamente** durante la ventana definida (primeras horas y el primer ciclo
   diario/nocturno completo, incluyendo los jobs batch).
5. **Verificar las métricas de negocio**, no solo las técnicas: ¿el usuario está haciendo lo que se
   esperaba?
6. **Re-documentar vía el ApiLLM** (ver encabezado): correr el sync, verificar que el anchor de
   `documents/_meta/sync-state.md` avanzó al nuevo HEAD y que quedó publicado.
7. **Cerrar el ticket** con evidencia y notificar a quien lo pidió.
8. **Limpiar:** eliminar el feature flag y el código muerto (el ticket ya está creado desde la
   Fase 5), eliminar columnas/campos viejos tras el período de gracia, cerrar la fase *contract* de
   la migración.
9. **Crear/priorizar los tickets de deuda** detectados en el camino.
10. **Retro sobre el proceso:** ¿en qué fase se debió detectar lo que se detectó tarde? Ese es el
    ajuste al proceso (un cambio en `process/` de este repo), no un regaño a la persona.
11. **Compartir aprendizaje:** ADR, mensaje al equipo, actualización de la plantilla o del
    checklist.

---

**Artefactos:** evidencia de smoke test y monitoreo, docs del ApiLLM re-sincronizados y
publicados, ticket cerrado, tickets de deuda/limpieza creados, ajuste al proceso si aplica.

**Criterio de salida:** cambio verificado en producción, docs del ApiLLM anclados al nuevo HEAD,
ciclo de aprendizaje registrado.
