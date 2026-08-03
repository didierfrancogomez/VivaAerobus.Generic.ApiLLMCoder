# Fase 0 — Intake y comprensión del ticket

> **Pregunta que responde:** ¿qué me están pidiendo realmente y por qué?
> **Apoyo en el repo LLM:** `../VivaAerobus.Generic.ApiLLM/documents/concepts/_catalog.md` para
> resolver términos del dominio (una línea por concepto — no abrir el doc completo si el catálogo
> responde).

**Objetivo:** entender la *intención* detrás del ticket, no solo su texto. Un ticket es un resumen
imperfecto de una conversación que ya ocurrió.

## 0.1 Lectura y clasificación

1. **Leer el ticket completo**, incluyendo: descripción, criterios de aceptación, comentarios
   (todos, en orden cronológico), adjuntos, links, campos personalizados.
2. **Leer el historial de cambios del ticket** (Jira: pestaña *History*). Cambios de alcance, de
   estimación, de prioridad o de asignado son señales de que hubo discusión no documentada.
3. **Clasificar el tipo de trabajo**, porque determina el rigor del resto del proceso:
   - Bug (con o sin impacto en datos)
   - Hotfix / incidente en producción → *ruta comprimida*, ver [Anexo B](anexo-b-hotfix.md)
   - Feature nueva
   - Modificación de comportamiento existente
   - Refactor / deuda técnica (sin cambio de comportamiento observable)
   - Spike / investigación (el entregable es conocimiento, no código)
   - Migración de datos o infraestructura
   - Cambio de configuración

   Asignar también el **nivel de rigor** (trivial / normal / riesgoso) según la tabla de
   `../CLAUDE.md` y escribirlo en el ticket.
4. **Identificar el "por qué"**: qué problema de negocio o de usuario resuelve. Si no puedes
   explicarlo en una frase sin usar términos técnicos, no lo entiendes todavía.
5. **Identificar a los actores afectados**: qué rol de usuario, qué segmento de clientes, qué
   equipo interno, qué sistema externo.
6. **Identificar el resultado observable esperado**: ¿cómo sabrá alguien que no es tú que esto
   quedó hecho? Si la respuesta no está en el ticket, es un hueco.

## 0.2 Verificar que el ticket está listo (Definition of Ready)

Checklist mínimo. Si falla algo, el ticket **no debería estar en progreso** — se devuelve o se
completa con la Fase 4.

- [ ] Tiene descripción del problema, no solo de la solución propuesta.
- [ ] Tiene criterios de aceptación explícitos, verificables y no ambiguos.
- [ ] Tiene diseño/mockups adjuntos si hay cambio de UI (y están actualizados, no una versión vieja).
- [ ] Tiene contrato de API definido o link a él, si aplica.
- [ ] Tiene datos de prueba, ejemplos concretos o casos reales (para bugs: pasos de reproducción +
      entorno + usuario + timestamp + evidencia).
- [ ] Tiene dependencias identificadas y su estado.
- [ ] Está estimado / dimensionado y cabe en el sprint.
- [ ] Tiene prioridad y responsable de negocio identificable (a quién le pregunto).
- [ ] El alcance está delimitado: dice también **qué NO incluye**.
- [ ] No hay ambigüedad de términos del dominio (ej.: "usuario activo" — ¿activo según qué
      definición?). Verificar el término contra `documents/concepts/_catalog.md` del repo LLM antes
      de preguntarlo: si el catálogo lo define con cita, no es ambigüedad.

## 0.3 Distinguir solicitud literal vs. necesidad real

1. **Separar "el qué" del "el cómo"**. Muchos tickets vienen escritos como solución ("agregar un
   campo X en la tabla Y"). Reconstruye el problema original.
2. **Preguntar por el caso de uso concreto**: "¿en qué situación real un usuario necesita esto?"
3. **Buscar la solución más simple que resuelve el problema real** — puede ser distinta a la
   propuesta y mucho más barata.
4. **Detectar XY problems**: piden X porque creen que resuelve Y; a veces X no resuelve Y, o Y ya
   está resuelto de otra forma.
5. **Registrar la reinterpretación** en un comentario del ticket antes de codificar. Nunca
   reinterpretar en silencio.

## 0.4 Contexto histórico y organizacional

1. Buscar **tickets relacionados**: mismo componente, mismas palabras clave, mismo epic, mismo
   reportante.
2. Buscar **tickets duplicados o ya resueltos**.
3. Buscar si **ya se intentó antes y se revirtió** (esto es oro: hay una razón documentada de por
   qué falló).
4. Identificar el **epic/iniciativa** y qué lugar ocupa este ticket ahí: ¿es el primero de una
   serie? ¿el último? ¿habilita a otros?
5. Identificar **quién más está tocando esa zona del código ahora mismo** (para evitar conflictos
   y trabajo duplicado).

---

**Artefactos:** crear `work/<CLAVE>/` y escribir la clave en `work/_active`; guardar
`work/<CLAVE>/fase-00-intake.md` (entendimiento reformulado + lista inicial de dudas +
clasificación de tipo de trabajo y nivel de rigor — si el nivel es *riesgoso*, crear también
`work/<CLAVE>/REQUIERE-GATE-HUMANO`); publicar el mismo contenido como comentario en el ticket.

**Criterio de salida:** puedes explicar en voz alta el problema, el resultado esperado, quién lo
pidió y por qué, sin leer el ticket.

**Siguiente:** [Fase 1 — Contraste contra el código](fase-01-contraste-codigo.md)
