# Fase 4 — Preguntas bloqueantes y registro de supuestos ══ EL GATE ══

> **Pregunta que responde:** ¿qué no puedo decidir yo solo?
> **Esta fase ES el gate del pipeline** (`../CLAUDE.md`): aquí se decide si el agente **se detiene**
> o **continúa a implementar**.
> **Apoyo en el repo LLM:** reglas de preguntas y veredicto de `llm/ANALYZE-TASK.md` §Phase 5
> ("puedes recomendar, pero nunca resolver"; separar preguntas de negocio de tareas de
> verificación nuestras; priorizar; cada pregunta con su porqué; agrupar por dueño; pocas y
> buenas).

**Objetivo:** convertir toda la incertidumbre en (a) una respuesta, o (b) un supuesto documentado y
aceptado. Nunca en una adivinanza silenciosa.

## 4.0 Regla del gate (obligatoria, sin excepción)

Al cerrar esta fase se emite un **veredicto explícito** (mismo formato que `llm/ANALYZE-TASK.md`):

| Veredicto | Significado | Acción del agente |
|---|---|---|
| ✅ **Ready to implement** | Objetivo, contratos, criterios de aceptación e impacto claros; cero bloqueantes duros | **Continuar** a [Fase 5](fase-05-planeacion.md) |
| ⚠️ **Needs definition** | Implementable, pero hay bloqueantes sin definir | **DETENERSE.** Emitir las preguntas (formato 4.2), marcar el ticket *Blocked*, NO codificar |
| ⛔ **Not implementable as stated** | La fuente de verdad está fuera del repo, depende de un stub, o contradice una regla/contrato existente | **DETENERSE.** Explicar por qué + 2–3 alternativas con recomendación |

- El veredicto se escribe en el ticket y se entrega al usuario. Con ⚠️/⛔ el agente **no produce
  código, ni plan de implementación** — solo el análisis, las preguntas y (si puede) el trabajo no
  bloqueado descrito en 4.5.
- **Dos tipos de información faltante — nunca confundirlos** (regla de `ANALYZE-TASK.md`):
  - **Hueco de negocio** → lo define el solicitante. Es una *pregunta*.
  - **Hueco de documentación/verificación** → lo verificamos **nosotros** en el código. Es una
    *tarea de verificación previa*, no una pregunta al negocio (y si el doc del LLM estaba mal, se
    invoca su pipeline `doc-sync`).

## 4.1 Clasificar las dudas

| Tipo | Definición | Manejo |
|---|---|---|
| **Bloqueante duro** | Sin la respuesta no puedo empezar, o el 100% del trabajo puede ser desechado | Escalar de inmediato, marcar el ticket como *Blocked*, no empezar |
| **Bloqueante parcial** | Bloquea una parte; puedo avanzar en otra | Preguntar y paralelizar el trabajo no bloqueado |
| **Decisión de negocio/producto** | No es técnica; solo el PO/negocio puede decidir | Preguntar con opciones y recomendación |
| **Decisión técnica de equipo** | Afecta a otros o al estándar (arquitectura, contrato, librería) | Llevar a tech lead / design review |
| **Ambigüedad de dominio** | Términos o reglas con más de una lectura | Resolver con el experto de dominio; documentar la definición |
| **Supuesto de bajo riesgo** | Puedo asumir algo razonable; si me equivoco el costo es bajo | Documentar como supuesto, seguir, validar en review/QA |
| **Detalle irrelevante** | No cambia el resultado | Decidir y seguir. No preguntar por todo: erosiona el canal |

## 4.2 Cómo formular una pregunta bloqueante (formato)

Una pregunta mal hecha genera dos días de ping-pong. Estructura:

```
[BLOQUEANTE] <Título corto de la decisión>
Contexto: <2–3 líneas. Qué encontré y por qué esto no está definido.>
Evidencia: <link al código, al dato, a la matriz de impacto.>
La pregunta concreta: <una sola pregunta, cerrada si es posible.>
Opciones:
  A) <descripción> — costo: <X>; implica: <Y>; riesgo: <Z>
  B) <descripción> — costo: <X>; implica: <Y>; riesgo: <Z>
Mi recomendación: <A o B, y por qué en una línea.>
Qué pasa si no se responde: <impacto y para cuándo se necesita: "necesito respuesta antes del
<fecha> o el ticket no entra al sprint">
Mientras espero, avanzo en: <lo que sí puedo hacer.>
```

Reglas:

- **Siempre con opciones y recomendación.** Preguntar en abierto ("¿qué hacemos?") traslada tu
  trabajo a otra persona y demora la respuesta.
- **Puedes recomendar, pero nunca resolver.** Aunque la recomendación sea obvia, la decisión queda
  como pregunta bloqueante hasta que el dueño confirme (regla de evidencia del ApiLLM).
- **Una pregunta por bloque.** Si hay tres, son tres bloques numerados, no un párrafo.
- **Sin jerga** si el destinatario es negocio.
- **Con fecha límite** explícita.

## 4.3 A quién y dónde preguntar

1. **Ruteo:** producto/negocio → PO. Arquitectura/estándar → tech lead. Comportamiento esperado y
   casos borde → QA + PO. UI/UX y estados vacíos/error → diseño. Datos y permisos → dueño del
   dominio o seguridad. Contrato de API → equipo consumidor. Infra → plataforma/DevOps. Reglas que
   viven en DotRez u otro vendor → quien gestione al vendor.
2. **Siempre dejar la pregunta escrita en el ticket**, aunque se resuelva por chat o en persona. El
   ticket es la memoria del proyecto; el chat no.
3. **Después de una conversación verbal, escribir el resumen y la decisión en el ticket** y pedir
   confirmación explícita ("¿confirmas que quedamos en A?").
4. **Etiquetar y hacer visible el bloqueo:** estado *Blocked*, motivo, responsable de desbloquear,
   fecha desde cuándo está bloqueado.

## 4.4 Registro de supuestos

Tabla que vive en el ticket y se revisa en la Fase 9 y en el PR:

| # | Supuesto | Por qué lo asumo | Riesgo si es falso | Cómo se valida | Estado |
|---|---|---|---|---|---|

Todo supuesto debe tener un mecanismo de validación: un test, una pregunta en el PR, una
verificación de QA. **Un supuesto sin validación es un bug programado.**

## 4.5 Escalamiento y trabajo en paralelo

1. **Definir el reloj:** si un bloqueante duro no se responde en X horas (acuerdo del equipo,
   típicamente 4–24h), se escala al siguiente nivel. Sin drama, por proceso.
2. **No quedarse quieto esperando:** avanzar en lo no bloqueado (tests, refactor preparatorio,
   scaffolding, documentación, otro ticket).
3. **No "avanzar adivinando" en lo bloqueado.** Si decides avanzar con un supuesto para no perder
   tiempo, hazlo explícito y aislado de forma que sea fácil de cambiar (detrás de una interfaz, de
   un flag, de un solo punto de cambio).
4. **Si el bloqueo se prolonga:** devolver el ticket al backlog y tomar otro. Un ticket bloqueado
   en progreso miente sobre el estado del sprint.

---

**Artefactos:** `work/<CLAVE>/fase-04-veredicto.md` — DEBE contener la línea literal
`VEREDICTO: ✅` / `VEREDICTO: ⚠️` / `VEREDICTO: ⛔` (los hooks la leen), más las preguntas
bloqueantes y la tabla de supuestos. Las preguntas también van al ticket. ⚠️ El veredicto se
escribe **al terminar el análisis real**, nunca antes: registrar ✅ sin haber cerrado los
bloqueantes es falsificar el gate.

**Criterio de salida (para cruzar el gate):** veredicto ✅ — cero bloqueantes duros abiertos y cada
supuesto documentado con su plan de validación. Con cualquier otro veredicto, el pipeline se
detiene aquí.

**Siguiente (solo con ✅):** [Fase 5 — Planeación y diseño](fase-05-planeacion.md)
