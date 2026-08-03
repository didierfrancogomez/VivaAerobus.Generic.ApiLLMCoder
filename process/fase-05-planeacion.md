# Fase 5 — Planeación y diseño

> **Pregunta que responde:** ¿cómo lo voy a hacer, en qué orden, con qué riesgos?
> **Precondición:** veredicto ✅ del gate (Fase 4). Con ⚠️/⛔ esta fase NO se ejecuta.
> **Apoyo OBLIGATORIO en el repo LLM:**
> - `llm/change-playbook.md` pasos 1–6 — re-leer el análisis aprobado, confirmar los hechos
>   load-bearing en el código, plan con citas, dónde va cada pieza
>   (`documents/architecture/conventions.md`, `patterns-cqrs.md`), códigos de error nuevos (nunca
>   reutilizar — `documents/cross-module/error-codes.md`), kill switch.
> - `guidelines/README.md` + categorías `STY`/`ARC`/`ROB`/`PRC` — **normativo**: el plan cita los
>   IDs de regla que debe honrar; un plan que viola una regla 🐛/❗ no está listo.
> - `documents/operations/testing.md` — dónde hay cobertura y dónde no; **donde no hay tests,
>   escribirlos es parte del alcance de este cambio, no opcional**.

**Objetivo:** decidir *cómo* antes de teclear, y dejarlo escrito y validado. La planeación termina
cuando la implementación es mecánica y aburrida.

## 5.1 Diseño de la solución

1. **Generar al menos dos opciones de solución.** Si solo se te ocurre una, no has pensado; has
   recordado.
2. **Comparar con trade-offs explícitos:** esfuerzo, riesgo, reversibilidad, rendimiento,
   mantenibilidad, deuda que crea o elimina, impacto en el equipo.
3. **Elegir y justificar.** Criterio por defecto: la solución más simple que cumple los criterios
   de aceptación y no cierra puertas futuras.
4. **Registrar un ADR** si la decisión es estructural, difícil de revertir o afecta a otros
   equipos.
5. **Diseñar los límites, no solo el centro:** qué pasa con entradas vacías, nulas, máximas,
   negativas, duplicadas, concurrentes, fuera de orden, con permisos insuficientes, con el servicio
   externo caído.
6. **Diseño contract-first:** definir y acordar el contrato (request/response/errores/eventos)
   *antes* de implementar, y compartirlo con los consumidores para que trabajen en paralelo.

## 5.2 Planes específicos obligatorios

Cada uno es una sección corta escrita en el ticket, no un pensamiento:

1. **Plan de datos/migración:** DDL, estrategia expand–contract (agregar → escribir en ambos →
   migrar datos → leer del nuevo → eliminar el viejo), reversibilidad, duración estimada sobre
   volumen real, ventana requerida.
2. **Plan de compatibilidad hacia atrás:** cómo convive lo viejo y lo nuevo durante el despliegue y
   durante el período de gracia de clientes viejos. Incluir **sesiones en vuelo**: baskets/bookings
   creados antes del cambio que se procesan después.
3. **Plan de feature flag:** nombre, valor por defecto (apagado), alcance (global / por cliente /
   por porcentaje), quién lo prende, criterio para prenderlo, y **ticket de limpieza creado desde
   ya**. En este sistema el kill switch natural son los config parts del Admin Portal
   (`documents/_meta/flags-and-rules.md`).
4. **Plan de observabilidad:** qué logs (con qué campos estructurados y sin PII), qué métricas
   (contadores, latencia, tasa de error), qué trazas, qué alertas y con qué umbral, qué panel
   muestra si esto funciona.
5. **Plan de pruebas** (escrito antes de codificar): qué se prueba unitario, qué integrado, qué
   contrato, qué e2e, qué manual, qué datos de prueba se necesitan, qué casos negativos y de borde.
   Los criterios de aceptación se convierten uno a uno en casos de prueba.
6. **Plan de rollout y rollback:** cómo se despliega, en qué orden, cómo se verifica, cómo se
   revierte, cuál es el kill switch, qué es irreversible (⚠️ migraciones destructivas, envío de
   correos, cobros, eventos publicados).
7. **Presupuesto no funcional:** latencia máxima aceptable, cantidad máxima de consultas por
   request, tamaño máximo de payload.
8. **Plan de seguridad y permisos:** qué roles pueden hacer qué, dónde se valida (siempre en
   servidor), qué datos se exponen.

## 5.3 Descomposición del trabajo

1. **Partir en pasos entregables** de idealmente menos de medio día, cada uno dejando el sistema
   funcionando (verde) y con sentido propio.
2. **Cortes verticales, no horizontales:** "endpoint completo para el caso A" es mejor que "todos
   los repositorios de todas las entidades".
3. **Definir el orden:** primero lo que reduce más incertidumbre (lo más riesgoso o desconocido va
   temprano, no al final).
4. **Separar en PRs distintos:** refactor preparatorio | migración | cambio funcional | limpieza.
   Mezclarlos hace la revisión imposible y el rollback peligroso.
5. **Definir explícitamente qué NO se va a hacer** en este trabajo (anti-alcance).
6. **Registrar riesgos** con probabilidad, impacto y mitigación o plan B.
7. **Actualizar la estimación** con lo aprendido y comunicar si cambió.

## 5.4 Validación del plan (design review)

1. Compartir el plan (10–15 min o por escrito) con tech lead y con quien sea dueño del código
   impactado.
2. Objetivo de la revisión: encontrar elementos faltantes del radio de impacto y alternativas más
   simples.
3. Ajustar el plan con el feedback y dejar registrada la aprobación.
4. Confirmar con QA que el plan de pruebas es suficiente, y con el consumidor del contrato que el
   contrato le sirve.
5. Confirmar con el PO que el resultado esperado es el que quiere (especialmente si hubo
   reinterpretación en la Fase 0.3).

---

**Artefactos:** `work/<CLAVE>/fase-05-plan.md` — documento de diseño, ADR si aplica, plan de
pruebas, plan de rollout, lista de pasos, registro de riesgos, estimación actualizada — todo con
citas y con los IDs de `guidelines/**` que el código deberá honrar. Si la tarea es de nivel
*riesgoso* (`REQUIERE-GATE-HUMANO`), el humano aprueba el plan creando `work/<CLAVE>/GATE-HUMANO-OK`
a mano — el agente jamás crea ese archivo.

**Criterio de salida:** el plan está aprobado y podrías entregárselo a otra persona del equipo para
que lo implemente.

**Siguiente:** [Fase 6 — Implementación](fase-06-implementacion.md)
