# Fase 1 — Contraste de la solicitud contra el código real

> **Pregunta que responde:** ¿qué existe hoy en la realidad?
> **Apoyo OBLIGATORIO en el repo LLM — en este orden:**
> 1. **Sincronizar primero**: ejecutar el paso 1 del `../VivaAerobus.Generic.ApiLLM/CLAUDE.md`
>    (`llm/SYNC.md`). Si los docs quedan/están stale, razonar desde el código y **decirlo
>    explícitamente** en el output.
> 2. Localizar el código vía `documents/concepts/_catalog.md` → el doc del concepto →
>    `documents/integrations/_catalog.md` si hay servicio externo.
> 3. Aplicar `llm/ANALYZE-TASK.md` fases 0–2 (restatement, clasificación de canal/flow/versión,
>    clarity gates) como parte de esta fase.
> 4. **Si un doc del LLM contradice el código o está incompleto:** eso es un hallazgo — se reporta
>    e **invoca el pipeline `doc-sync` del ApiLLM** para corregirlo. Nunca se documenta aquí.

**Objetivo:** cerrar la brecha entre lo que el ticket *asume* que existe y lo que *realmente*
existe. Es la fase que más retrabajo evita.

## 1.1 Localizar el código involucrado

1. **Ubicar el punto de entrada**: endpoint, handler, comando, job, listener, pantalla, componente.
2. **Trazar el flujo completo** desde el punto de entrada hasta la persistencia y de vuelta:
   controlador → servicio → repositorio → base de datos → respuesta → cliente.
3. **Identificar todas las capas involucradas** y en qué repositorios viven (¿es un solo repo o son
   3 servicios?).
4. **Buscar duplicaciones**: la misma lógica implementada en dos o tres lugares (muy común: web +
   móvil + batch, o una copia en un servicio legacy). Si existen, todas están en el alcance o hay
   que decidir explícitamente que no.
5. **Identificar el "código muerto o casi muerto"** cercano: cosas que parecen relevantes pero ya
   no se ejecutan. ⚠️ En este API hay archivos presentes pero **excluidos de compilación**
   (`<Compile Remove>` en el `.csproj`) — nunca asumir que un archivo en el árbol está activo
   (ver `llm/ANALYZE-TASK.md` §Phase 4, "Build traps").

## 1.2 Entender el comportamiento actual

1. **Leer el código, no adivinarlo.** Leer también los tests existentes: son la especificación real
   del comportamiento actual.
2. **Ejecutarlo localmente** y observar el comportamiento actual con datos reales o realistas
   (setup en `documents/operations/local-setup.md` del repo LLM).
3. **Para bugs: reproducir primero.** Si no puedes reproducir, no puedes arreglar. Si no reproduce,
   eso ya es un hallazgo que va a la Fase 4.
4. **Documentar el comportamiento actual** en 3–5 viñetas **con citas** (`path/File.cs :: Symbol`).
   Esto se vuelve la línea base contra la cual se define el "después".
5. **Identificar comportamientos no documentados de los que alguien depende** (side effects, orden
   de ejecución, tolerancias, formatos de respuesta).

## 1.3 Arqueología: por qué está así

1. `git log` / `git blame` sobre las líneas relevantes. Buscar el commit original y su mensaje.
2. Del commit → al PR → al ticket → a la discusión. Muchas rarezas tienen una razón explícita.
3. Buscar comentarios en el código tipo `// no cambiar esto porque...`, `HACK`, `WORKAROUND`, `TODO`.
4. Buscar ADRs (Architecture Decision Records) o documentación de diseño del módulo (en el repo
   LLM: `documents/architecture/**`).
5. **Regla:** si algo parece absurdo y no encuentras la razón, asume que hay una razón que no ves y
   pregunta. La opción por defecto no es "lo arreglo".

## 1.4 Detección de discrepancias (el output clave de esta fase)

Compara ticket vs. realidad y clasifica:

| Tipo de discrepancia | Ejemplo | Acción |
|---|---|---|
| Ya está implementado | El ticket pide algo que ya funciona | Verificar y cerrar / reclasificar como bug de configuración |
| Parcialmente implementado | Existe el 60%, falta el resto | Ajustar alcance y estimación |
| Existe pero de otra forma | El campo se llama distinto, el flujo es otro | Ajustar la descripción del ticket |
| No existe la precondición | El ticket asume una tabla/servicio/permiso que no está | **Bloqueante o dependencia nueva** |
| El ticket contradice el diseño actual | Lo pedido rompe una invariante del sistema | **Bloqueante de diseño** |
| Es imposible como está pedido | Limitación técnica real | **Bloqueante; llevar alternativas** |
| Cuesta 10x más de lo estimado | Por acoplamiento o deuda | Re-estimar y renegociar alcance |
| El ticket asume un stub como funcional | Endpoints que devuelven vacío pese a lo que promete Swagger (`documents/concepts/_catalog.md` §Known implementation gaps) | **Es greenfield, no modificación** — decirlo |

---

**Artefactos:** `work/<CLAVE>/fase-01-contraste.md` — nota de "estado actual vs. solicitado" con
la tabla de discrepancias, todo citado, abriendo con el estado de sync de los docs.

**Criterio de salida:** cero suposiciones sobre el código; todo lo afirmado fue verificado leyendo
o ejecutando, con cita.

**Siguiente:** [Fase 2 — Radio de impacto](fase-02-radio-impacto.md)
