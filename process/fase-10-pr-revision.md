# Fase 10 — Crear el PR y gestionar la revisión

> **Pregunta que responde:** transferir contexto y obtener aprobación.
> **Precondición:** veredicto APPROVED del gate de la Fase 9 (`llm/REVIEW-CODE.md`) y CI verde.

**Objetivo:** transferir todo el contexto de las fases 0–9 al revisor con el mínimo esfuerzo de su
parte.

## 10.1 Construcción del PR

1. **Título:** `CLAVE-123: descripción imperativa y concreta`. Que se entienda sin abrir el PR.
2. **Descripción con plantilla:**

```markdown
## Ticket
CLAVE-123 (link)

## Contexto y problema
Qué problema resuelve y por qué importa. 2–4 líneas.

## Solución
Qué hace este cambio, a alto nivel. Cómo funciona.

## Alternativas consideradas
Qué más evalué y por qué elegí esto. (Evita el 80% de los comentarios de "¿por qué no hiciste X?")

## Radio de impacto
Qué se afecta y qué NO se afecta. Consumidores, datos, contratos, configuración.

## Cómo probarlo
Pasos concretos, usuarios/datos de prueba, qué se debe observar.

## Evidencia
Capturas / video / respuestas de ejemplo. Antes y después.

## Migraciones / datos
Sí/No. ¿Reversible? Duración estimada. ¿Backfill?

## Feature flag
Nombre, valor por defecto, ticket de limpieza.

## Riesgos y plan de rollback
Qué puede salir mal, qué señal vigilar, cómo se revierte.

## Supuestos por confirmar
Lista para el revisor.

## Checklist
- [ ] Criterios de aceptación cubiertos
- [ ] Tests agregados/actualizados y CI verde
- [ ] Radio de impacto revisado
- [ ] Documentación actualizada
- [ ] Configuración provisionada en todos los entornos
- [ ] Sin secretos ni datos sensibles
- [ ] REVIEW-CODE.md (validador local) → APPROVED
```

3. **Enlazar bidireccionalmente:** el PR referencia el ticket y el ticket referencia el PR. Enlazar
   también PRs dependientes y el orden de merge.
4. **Etiquetas y metadatos:** tipo, área, tamaño, "requiere migración", "breaking change",
   "necesita despliegue coordinado".
5. **Elegir revisores con criterio:** quien conoce el código, quien es dueño del área impactada
   (CODEOWNERS), y quien consume el contrato si lo cambiaste. Uno o dos revisores, no ocho.
6. **Auto-anotar el diff:** dejar comentarios propios en las partes no obvias, explicando el por
   qué y señalando dónde quieres atención especial. Ahorra rondas.
7. **Draft vs. listo:** si falta algo o quieres feedback temprano de dirección, marcar como
   borrador y decirlo. No pedir revisión formal de algo incompleto.
8. **CI verde antes de pedir revisión.** Pedir revisión con el pipeline rojo es transferirle tu
   trabajo al revisor.

## 10.2 Gestión de la revisión

1. **Avisar al revisor** por el canal del equipo con una línea de contexto y la urgencia real.
2. **Responder cada comentario**, incluso para decir "hecho" o para discrepar con argumento. Nada
   sin responder.
3. **Discrepar bien:** con razones técnicas, sin defender el ego. Si tras dos rondas no hay
   acuerdo, escalar a un tercero en lugar de seguir en el hilo.
4. **Cambios en commits nuevos** durante la revisión (no reescribir el historial mientras revisan,
   o avisar si lo haces).
5. **Si un comentario revela un hueco de alcance o un problema de diseño:** volver a la fase que
   corresponda; no parchear encima.
6. **Volver a solicitar revisión** explícitamente cuando termines los cambios, resumiendo qué se
   ajustó.
7. **Convertir comentarios fuera de alcance en tickets** y enlazarlos, en lugar de expandir el PR.
8. **Cuidar los tiempos:** acuerdo de equipo (ej.: primera respuesta en menos de un día hábil). Un
   PR abierto una semana se vuelve un conflicto de merge y pierde contexto.

## 10.3 Merge

1. Verificar: aprobaciones necesarias, CI verde, conversaciones resueltas, rama actualizada,
   dependencias ya mergeadas en el orden correcto.
2. Usar la estrategia de merge del equipo (squash / merge commit / rebase) de forma consistente.
3. Mergear cuando puedas acompañar el despliegue — no justo antes de irte.
4. Borrar la rama.
5. Mover el ticket al estado correspondiente y dejar el comentario de cierre.

---

**Artefactos:** PR documentado, aprobaciones, historial de decisiones de revisión.

**Criterio de salida:** mergeado con CI verde y ticket actualizado.

**Siguiente:** [Fase 11 — Post-merge y cierre](fase-11-post-merge.md)
