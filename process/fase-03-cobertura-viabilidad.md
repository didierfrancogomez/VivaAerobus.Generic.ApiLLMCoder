# Fase 3 — ¿El ticket y sus hermanos contemplan el radio de impacto? ¿Es viable?

> **Pregunta que responde:** ¿el ticket (y sus hermanos) contemplan todo? ¿es viable?
> **Apoyo en el repo LLM:** `llm/ANALYZE-TASK.md` §Phase 4 (riesgo y seguridad de implementación:
> integridad transaccional, concurrencia, idempotencia, red de tests, reversibilidad,
> observabilidad, alcance de despliegue, migración de datos, build traps, tamaño) — esos criterios
> alimentan directamente la determinación de viabilidad de 3.4.

**Objetivo:** verificar cobertura y factibilidad *antes* de escribir código. Aquí se decide si el
trabajo se puede hacer, cómo se parte y en qué orden.

## 3.1 Análisis de cobertura del ticket

1. Recorrer la matriz de impacto fila por fila contra la descripción y los criterios de aceptación.
2. Marcar cada fila como: **cubierta explícitamente / cubierta implícitamente / no cubierta /
   contradicha**.
3. "Cubierta implícitamente" es una trampa: exige convertirla en explícita, porque nadie la va a
   probar.
4. Producir la **lista de huecos**: todo lo no cubierto o contradicho.
5. Para cada hueco decidir: (a) entra en este ticket, (b) se crea ticket nuevo, (c) ya existe
   ticket, (d) se decide explícitamente no hacerlo (y se documenta la decisión y su riesgo).
6. Verificar también el sentido inverso: **¿el ticket pide cosas que ya no aplican o que están
   fuera del radio real?** Recortar es tan valioso como agregar.

## 3.2 Análisis de los tickets hermanos

1. Abrir el **epic completo** y listar todos los tickets relacionados.
2. Mapear: hueco identificado → ticket que lo cubre. Dejar el mapeo escrito.
3. Verificar que los tickets hermanos **realmente cubren** el hueco (leerlos, no confiar en el
   título).
4. Detectar **solapamientos**: dos tickets que van a tocar la misma función → riesgo de conflicto y
   de trabajo duplicado. Coordinar con el otro responsable.
5. Detectar **huecos entre tickets**: cada ticket cubre su parte pero nadie cubre la integración
   entre ambas.
6. Verificar que hay un ticket para lo transversal que nadie reclama: migración de datos,
   actualización de documentación, limpieza del feature flag, actualización de la app móvil,
   comunicación al cliente.

## 3.3 Análisis de dependencias y secuencia

1. Construir el **grafo de dependencias**: A antes de B antes de C.
2. Identificar dependencias **externas al equipo** (otro squad, un proveedor, infraestructura,
   legal, diseño) y su estado y fecha comprometida. ⚠️ En este sistema, reglas que viven en
   **DotRez**, en el **Admin Portal** o en otro servicio externo pueden hacer que el cambio **no
   sea implementable solo aquí** (lead time del vendor).
3. Identificar el **camino crítico** y qué se puede paralelizar.
4. Verificar el **orden de despliegue** requerido y si es compatible con la cadencia de releases
   (ej.: la app móvil tarda 2 semanas en aprobación de tienda → el backend debe salir compatible
   hacia atrás primero).
5. Detectar **dependencias circulares** entre tickets — se resuelven con feature flags o con un
   paso intermedio compatible.
6. Verificar que el ticket **no bloquea a otros** silenciosamente.

## 3.4 Determinación de viabilidad (la pregunta directa: ¿se puede hacer?)

Evaluar en cinco ejes y concluir explícitamente:

| Eje | Preguntas |
|---|---|
| **Técnica** | ¿Existe la capacidad técnica? ¿La plataforma/librería lo permite? ¿Hay un límite duro? ¿Existe prueba de concepto o hace falta un spike? |
| **De datos** | ¿Existen los datos necesarios? ¿Con la calidad y el histórico requeridos? ¿Se pueden obtener? |
| **De dependencias** | ¿Lo que necesito de otros existe hoy, o depende de un compromiso futuro? |
| **De alcance/tiempo** | ¿Cabe en el sprint? ¿La estimación sigue siendo válida después de las fases 1–2? |
| **De riesgo** | ¿El riesgo es aceptable? ¿Es reversible? ¿Qué es lo peor que puede pasar? |

**Salidas posibles y qué hacer con cada una:**

- **Viable como está** → seguir a Fase 4/5.
- **Viable con alcance reducido** → proponer el recorte concreto (MVP) y qué queda para después.
  Renegociar con el PO.
- **Viable pero requiere partirse** → proponer la división en tickets con secuencia y entrega
  incremental de valor (cortes verticales, no por capas).
- **Viable pero no ahora** → falta una dependencia; devolver el ticket al backlog con la razón y el
  bloqueo enlazado.
- **No viable como está pedido** → llevar **2–3 alternativas** con costo, trade-offs y una
  recomendación. Nunca solo un "no".
- **Requiere spike primero** → crear el spike con pregunta concreta, timebox y entregable definido.

Estas salidas se mapean al veredicto del gate (Fase 4): "viable como está" ⇒ candidato a ✅;
cualquier otra ⇒ ⚠️ o ⛔ con sus preguntas/alternativas.

## 3.5 Renegociación de alcance y estimación

1. Si la estimación cambió más de ~30% respecto a la original, comunicarlo **inmediatamente**, no
   al final del sprint.
2. Presentar el cambio con la evidencia (matriz de impacto), no como opinión.
3. Ofrecer opciones: reducir alcance, mover fecha, agregar ayuda, aceptar deuda temporal
   documentada.
4. Actualizar el ticket: descripción, criterios de aceptación, subtareas, estimación, dependencias
   enlazadas, etiquetas de riesgo.

---

**Artefactos:** `work/<CLAVE>/fase-03-viabilidad.md` — lista de huecos con su resolución, mapeo
hueco→ticket, grafo de dependencias, conclusión de viabilidad (también escrita en el ticket).

**Criterio de salida:** el PO/tech lead está de acuerdo con el alcance final y con los tickets
nuevos creados.

**Siguiente:** [Fase 4 — Bloqueantes y supuestos (GATE)](fase-04-bloqueantes.md)
