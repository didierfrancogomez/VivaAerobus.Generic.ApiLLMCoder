---
name: jira-next-ticket-picker
description:
    Consulta el tablero de Jira de la Generic API vía MCP atlassian e identifica con cuál ticket
    continuar el desarrollo: candidatos a pasar a In Progress desde To Do, Feedback o PAUSED.
    Evalúa cada candidato a fondo (label TestCaseReady, assignee, comentarios sin pendientes) y
    entrega un ranking con justificación y una recomendación. Es 100% solo lectura — no crea
    archivos, no comenta ni transiciona nada en Jira. Usa este skill cuando el usuario pregunte
    qué ticket tomar/retomar, cuál sigue, o qué hay listo para desarrollo en el tablero.
user-invocable: true
---

# Selector del próximo ticket - Jira Next Ticket Picker

Skill para analizar el tablero de Jira del proyecto GenericAPI y recomendar **con cuál ticket
continuar el desarrollo** — es decir, cuál está listo para pasar a `In Progress`, ya sea uno nuevo
(`To Do`) o uno que se retoma (`Feedback`, `PAUSED`).

## En el Coder — GOLDEN RULE 6 (`CLAUDE.md`)

- Toda pregunta del tipo *"¿qué ticket/tarea/actividad puedo tomar, retomar o desarrollar?"*,
  *"¿cuál sigue?"* o *"¿qué hay listo en el tablero?"* se responde **solo** con este skill,
  ejecutando **todos** sus pasos en orden (0 → 5) — también cuando la pregunta llega con otras
  palabras. Nunca de memoria, ni a partir de `work/`, ni con `tools/jira-sync`.
  `hooks/ticket-picker-route.sh` detecta estas preguntas en cada prompt y recuerda la regla.
- El MCP `atlassian` está declarado en `.mcp.json` (servidor remoto oficial de Atlassian). Cada
  developer lo aprueba y se autentica una vez: `claude` en este repo → `/mcp` → `atlassian` →
  *Authenticate*. Si no está conectado, aplica el `ERROR` de abajo y dile cómo conectarlo.
- Este skill no cambia el pipeline: elegir un ticket no inicia la Fase 0. Eso ocurre solo cuando
  el developer lo decide (`/implement <KEY>`).

## Restricciones duras (sin excepción)

- **Solo lectura y análisis.** No genera archivos, no comenta en Jira, no transiciona estados, no
  asigna tickets, no modifica nada — ni en Jira ni en el filesystem. El único output es la
  respuesta en el chat.
- **Autocontenida.** Todo lo que este skill necesita está en este archivo; lo único externo que
  usa es el MCP `atlassian`. No leas otros archivos del repo ni invoques otras skills (en
  particular, **no** invoques `jira-ticket-analyzer`): la decisión se toma evaluando las reglas de
  este skill contra cada ticket, sin generar informes de análisis técnico. Si el usuario quiere el
  análisis profundo del ticket elegido, ese es un paso posterior y separado que él decide.
- **Sin fallback a XML.** Este skill consulta el tablero vivo; si no hay acceso al MCP `atlassian`,
  se detiene con: `"ERROR: No hay acceso al MCP atlassian; no puedo consultar el tablero."`

## Proceso

### Paso 0: Resolver acceso y proyecto (dinámico, no hardcodeado)

1. Obtén el `cloudId` con `getAccessibleAtlassianResources`.
2. Identifica al **usuario actual** con `atlassianUserInfo` (necesario para la regla de assignee).
3. Descubre el proyecto **dinámicamente**: usa `getVisibleJiraProjects` (búsqueda por "Generic" /
   "API") y localiza el proyecto de la Generic API (sus tickets usan keys `API-xxxx`). Si hay más
   de un proyecto plausible o ninguno, pregunta al usuario antes de continuar — no adivines.
4. **PREGUNTA OBLIGATORIA — cuántos candidatos quiere** (el N del corte del Paso 4).

   Esta pregunta es un **paso bloqueante**: hazla y **espera la respuesta** antes de ejecutar
   cualquier consulta del Paso 1. No la omitas, no la infieras, no asumas el default sin haber
   preguntado. Si el CLI tiene una herramienta de pregunta al usuario (p. ej. `AskUserQuestion`),
   úsala; si no, escribe la pregunta en el chat y detén el turno ahí.

   Texto sugerido: *"¿Cuántos candidatos quieres que evalúe para el ranking (el corte N)?"*
   con opciones 3 / 5 (default) / 10 / todos.

   **Único caso en que se usa el default N = 5:** ya preguntaste y el usuario no respondió, o
   respondió algo que no permite deducir un número (p. ej. "no sé", "lo que veas"). En ese caso
   di explícitamente en la respuesta final: *"Usé N = 5 por defecto"*.

   Excepción: si el usuario **ya dio el número en su mensaje inicial** ("dame los 3 mejores",
   "muéstrame 10"), eso cuenta como respuesta — no vuelvas a preguntar; confirma el N que tomaste.

### Paso 1: Traer los candidatos del tablero

**Chequeo prioritario (antes que todo lo demás):** consulta primero si hay tickets `In Progress`
asignados al usuario actual:

```
project = <KEY> AND status = "In Progress" AND assignee = currentUser()
```

Si hay resultados, esos tickets tienen **la más alta prioridad sobre todas las demás reglas**:
significa que el usuario recibió de vuelta un ticket de review a `In Progress` y probablemente
tiene feedback en el PR que debe resolver **antes de tomar otro ticket**. No vayas a buscar ni
analizar ese feedback — no aplica ninguna regla de elegibilidad ni lectura profunda: van directo
al **tope del ranking** (por encima de cualquier elegible, sin importar prioridad), marcados como
"retomar: resolver feedback del PR". El resto del proceso continúa normalmente para completar el
mapa del tablero.

Luego, consulta los candidatos con `searchJiraIssuesUsingJql`:

```
project = <KEY> AND status in ("To Do", "Feedback", "PAUSED")
  AND issuetype in (Story, Task, Bug)
  AND labels in (TestCaseReady, TestCasesReady)
ORDER BY Rank ASC
```

- El filtro de `labels` en el JQL es seguro porque el label es requisito de elegibilidad en
  **todos** los estados (regla 1 del Paso 3). Pero su significado difiere por estado: en `To Do`
  es un proxy muy fiable de "listo" (la lectura profunda casi siempre solo confirma); en
  `Feedback`/`PAUSED` es **solo un requisito más, no determinista por sí solo** — ahí la
  disposición real la decide el análisis de comentarios del Paso 3, sin atajos.
- `ORDER BY Rank ASC` preserva el **orden de la columna en el tablero** (más arriba = más
  prioritario); consérvalo, se usa como desempate del ranking.
- Pide los campos necesarios para el filtrado inicial (`summary`, `status`, `assignee`,
  `priority`, `labels`, `issuetype`) y pagina hasta traer **todos** los resultados.
- **Excluye** los tickets de análisis: summary que empieza con `Analyze -` / `Analysis -`
  (trabajo de análisis de Ezy, no de implementación). Filtra sobre los resultados — no confíes en
  el operador `~` de JQL para esto.
- Alcance: **todo el proyecto** — sin filtro de sprint ni de assignee en el JQL (el assignee se
  evalúa como regla de elegibilidad en el Paso 3, no como filtro de la query).

### Paso 2: Leer cada candidato a fondo (en batch)

Trae el detalle de **todos** los tickets que sobreviven el Paso 1 en **una sola consulta batch**
con `searchJiraIssuesUsingJql` (no hagas un `getJiraIssue` por ticket — mismo contenido, mucho
menos overhead):

- `jql: "key in (API-XXX, API-YYY, ...) ORDER BY Rank ASC"`.
- `fields: ["summary", "status", "priority", "labels", "assignee", "updated", "comment"]` — el
  historial completo de comentarios queda en `fields.comment.comments`.
- `responseContentFormat: "markdown"`.
- Si el resultado excede el límite de salida y se vuelca a un archivo, extrae de ahí un resumen
  compacto por ticket (campos clave + comentarios) en vez de reintentar la consulta.

`getJiraIssue` individual queda como alternativa válida solo cuando necesitas un ticket puntual
(p. ej. re-verificar uno solo).

**Atajo:** si un candidato tiene `totalComments = 0` (visible en el propio batch), no hay nada
que analizar en comentarios — la regla 3 del Paso 3 se cumple automáticamente y pasa directo a
las demás reglas.

El ranking se justifica con evidencia de esta lectura — no con suposiciones a partir del listado
del JQL.

### Paso 3: Reglas de elegibilidad

Un ticket es **candidato elegible** solo si cumple **todas**:

1. **Label de test cases:** tiene el label `TestCaseReady` — la forma real del board (89 tickets,
   incluidos los de jul-2026; verificado 2026-08-06). La página canónica del proceso lo escribe
   `TestCasesReady`, prácticamente sin uso real (1 ticket de prueba); el JQL del Paso 2 acepta
   **ambas** variantes a propósito, para no perder ese caso residual.
2. **Assignee:** **no** está asignado a otro developer. Está OK si:
   - no tiene assignee, o
   - está asignado al **usuario actual** (típico en `Feedback`/`PAUSED` que él mismo retoma), o
   - está asignado a un miembro de **VB** (negocio — no es quien implementa).

   Está **descartado** si el assignee es otro developer (equipos **Ezy** o **Tech And Solve**).
   Clasifica al assignee con esta tabla de equipos (los developers son Ezy + Tech And Solve; VB
   es negocio):

   | Equipo | Miembros | Rol |
   |---|---|---|
   | **Ezy** (`EzyWebwerkstaden`) | Marcin Nowak, Piotr Wędzicha, Piotr Wieliński, Henrik (Adolfsson), Mujeeb (Ahmad) | Developers (análisis técnico, review, implementación) |
   | **Tech And Solve** | Luis Guillermo Galindo, Didier, Gabriel, Daniel (Llano), Eric (De la Nuez, ya no está), Sebastián (ya no está) | Developers (implementación) |
   | **Viva Aerobus (VB)** | Héctor Rodríguez Cervantes (aparece en Jira como `hectorcervantes`), Luis Alejandro (Alex), Belem (Maldonado), Adrián (Valdez), Víctor, Arturo (Garza), Edgar Gallegos, Nathaly Arias, Mauricio Fernández, Hugo Ricardo Cuevas Torre | Negocio (redactan tickets, deciden reglas) — **no descarta** |

   Si el assignee no aparece en esta tabla y no puedes clasificarlo con certeza, **pregunta al
   usuario** — no lo clasifiques por intuición.
3. **Comentarios sin pendientes:** en la sección de comentarios **no** hay preguntas, dudas,
   refinamientos o validaciones **sin resolver**. Analiza el hilo con criterio de "la verdad más
   reciente manda": una duda planteada y luego respondida/decidida más abajo cuenta como resuelta;
   una pregunta al negocio sin respuesta posterior cuenta como pendiente y descarta el ticket.

Señales adicionales **por estado de origen** (matizan la justificación y pueden descartar):

- **`Feedback`:** verifica en los últimos comentarios que la acción realmente volvió al developer
  (negocio desbloqueó/decidió, o se reportó un issue de UAT/prod ya acotado y accionable). Si el
  último movimiento sigue esperando a negocio, no está listo.
- **`PAUSED`:** se pausó por repriorización; busca señales de que la prioridad volvió (comentario
  de daily, mención de repriorización, el ticket que motivó la pausa ya cerrado). Si la causa de
  la pausa sigue vigente, márcalo como no listo y di por qué.
- **`To Do`:** confirma que nada en los comentarios contradiga que está listo para tomarse
  (p. ej. un comentario reciente que reabre el alcance).

### Paso 4: Ranking de los elegibles (con corte en N)

Ordena los candidatos elegibles con estos criterios, en este orden:

1. **Prioridad del ticket** (campo `priority`): Highest/High primero, luego Medium, y así
   descendentemente.
2. **Orden en la columna del tablero** (el Rank del Paso 1): a igual prioridad, va primero el que
   esté más arriba.

**Corte en N (modo rápido):** evalúa los candidatos en ese mismo orden (prioridad descendente,
y dentro de cada prioridad por Rank) y **detente en cuanto tengas N elegibles** — el N que el
usuario eligió en el Paso 0 (default 5). El corte es válido porque un ticket de prioridad menor
nunca supera en ranking a uno de prioridad mayor ya elegible. Si una prioridad se agota sin
llegar a N, continúa con la siguiente. Los tickets que el corte dejó **sin evaluar** no son
descartados — simplemente no se analizaron.

### Paso 5: Presentar el resultado (solo en el chat)

Responde en el **idioma de la conversación** (por defecto, español) con:

1. **Recomendación directa:** el ticket con el que continuar y por qué, en una o dos frases.
   Si el chequeo prioritario del Paso 1 encontró tickets `In Progress` asignados al usuario, la
   recomendación es **siempre** retomar esos (resolver el feedback del PR) antes que cualquier
   candidato del ranking.
2. **TABLA DE RANKING — OBLIGATORIA SIEMPRE.** Los elegibles se presentan en una **tabla markdown**,
   nunca como lista de bullets, nunca como párrafos, nunca como texto plano — incluso si hay un solo
   elegible (tabla de una fila) o si las celdas quedan muy cortas.

   Copia esta plantilla **exactamente**, incluyendo la fila de encabezado y la de separadores, y
   agrega **una fila por ticket elegible** en orden de ranking:

   ```markdown
   | # | Ticket | Estado | Prioridad | Assignee | Por qué está listo / riesgos |
   |---|---|---|---|---|---|
   | 1 | [API-XXXX](https://<site>/browse/API-XXXX) — <summary> | To Do | High | <nombre> (VB) | <evidencia concreta> |
   | 2 | ... | ... | ... | ... | ... |
   ```

   Ejemplo de una fila ya rellenada (imita este nivel de detalle):

   ```markdown
   | 1 | [API-1794](https://vivaaerobus.atlassian.net/browse/API-1794) — [IROP] Exclude From Irop - BookingStatus | To Do | High | Belem Maldonado (VB) | Dudas de Marcin sobre los TCs (30-jul) respondidas por negocio (31-jul); descripción y matriz ya corregidas |
   ```

   Reglas de las celdas:

   | Columna | Contenido |
   |---|---|
   | `#` | Posición en el ranking (1, 2, 3...) |
   | Ticket | Key enlazado a Jira + título: `[API-XXXX](https://<site>/browse/API-XXXX) — <summary>` |
   | Estado | Estado de origen tal cual: `To Do` / `Feedback` / `PAUSED` (o `In Progress` para los del chequeo prioritario) |
   | Prioridad | Campo `priority` tal cual (`Highest`, `High`, `Medium`...) |
   | Assignee | Nombre + equipo entre paréntesis: `(VB)`, `(tú)`, `(sin asignar)` |
   | Por qué está listo / riesgos | Evidencia concreta (qué duda se resolvió, por quién, cuándo) y el matiz que afecte la decisión (dependencia, PR previo, antigüedad). Si no cabe, deja una frase corta acá y desarrolla en prosa **debajo** de la tabla |

   Prohibido: omitir columnas, renombrarlas, reordenarlas, o sustituir la tabla por una lista.

3. **TABLA DE DESCARTADOS — OBLIGATORIA cuando haya al menos uno.** Mismo criterio: tabla markdown,
   no bullets. Agrupa por motivo (una fila por motivo) para que no crezca sin control:

   ```markdown
   | Motivo del descarte | Cant. | Tickets |
   |---|---|---|
   | Asignado a otro developer | 11 | API-1431, API-1698, ... |
   | Ticket de análisis (`Analyze -`) | 2 | API-1255, API-1690 |
   | Duda pendiente con negocio sin respuesta | 1 | API-1234 |
   | En `Feedback` sin señal de retorno al developer | 6 | API-724, API-1269, ... |
   | Pausa aún vigente | 0 | — |
   ```

   Usa solo las filas de motivos que realmente apliquen. Si un descarte necesita explicación
   (p. ej. "venía bloqueado por API-1240, hay que verificar si cerró"), agrégala en prosa **debajo**
   de la tabla. Si el corte en N del Paso 4 se activó, dilo explícitamente y agrega una fila
   `No evaluados (quedaron después del corte N)` — esos **no** son descartados.

4. Si **ningún** ticket resulta elegible, dilo explícitamente y presenta solo la tabla de
   descartados con lo que le falta a cada uno.

**Checklist antes de enviar la respuesta** (verifica los cuatro puntos; si alguno falla, corrige
antes de responder):

- [ ] ¿Pregunté el N y estoy usando el valor que el usuario dio (o dije que usé el default 5)?
- [ ] ¿La respuesta contiene una tabla markdown de ranking con las 6 columnas de la plantilla?
- [ ] ¿Hay una fila por cada elegible, con el key enlazado?
- [ ] ¿Hay tabla de descartados (si hubo descartados)?

No cierres invocando otra skill ni proponiendo escribir nada: la decisión de qué hacer con la
recomendación es del usuario.
