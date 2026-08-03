# Fase 8 — Preparación para liberación

> **Pregunta que responde:** ¿se puede desplegar y revertir de forma segura?
> **Apoyo en el repo LLM:** `documents/_meta/flags-and-rules.md` (config parts / kill switch por
> entorno) y los endpoints Admin de reset de caché citados en la Fase 2.3.8 — la invalidación de
> caché es un paso del runbook, no una nota al pie.

**Objetivo:** que el despliegue sea un no-evento y que revertir sea posible en minutos.

## 8.1 Artefactos de despliegue

1. **Runbook de despliegue** con el orden exacto de pasos: migración → despliegue de servicio A →
   despliegue de servicio B → backfill → prender flag → verificación.
2. **Scripts de migración y backfill** revisados, idempotentes, reanudables, con logging de
   progreso y probados sobre una copia de datos reales.
3. **Configuración y secretos provisionados en cada entorno** antes del despliegue (una variable
   faltante en prod es la causa más común de un despliegue fallido).
4. **Feature flag creado en todos los entornos**, apagado, con dueño y con criterio de activación
   documentado.
5. **Orden de despliegue entre repositorios** y compatibilidad verificada para cada paso intermedio
   (el sistema debe funcionar *entre* despliegues, no solo al final).
6. **Dependencias externas listas**: el otro equipo ya desplegó, el proveedor ya habilitó, el
   permiso ya existe.

## 8.2 Observabilidad y seguridad de la operación

1. **Paneles y alertas creados y desplegados ANTES del cambio**, no después. Debes poder responder
   "¿está funcionando?" en 30 segundos.
2. **Definir las métricas de éxito y de falla** y sus umbrales: tasa de error, latencia p95/p99,
   volumen de la operación nueva, métricas de negocio.
3. **Plan de rollback probado**: cómo se revierte, cuánto tarda, quién lo ejecuta, qué se pierde.
   Si hay algo irreversible, decirlo explícitamente.
4. **Kill switch** disponible (el flag / config part) para desactivar sin desplegar.
5. **Criterios de abortar:** qué señal concreta hace que se revierta sin discusión.
6. **Plan de verificación post-despliegue (smoke test):** lista corta y concreta de qué se
   comprueba en producción en los primeros 10 minutos.

## 8.3 Comunicación y coordinación

1. **Notas de liberación / changelog** en lenguaje de usuario.
2. **Avisar a los afectados:** soporte, éxito del cliente, ventas, operaciones, otros equipos de
   desarrollo, y clientes/integradores si hay cambio de contrato (con período de gracia).
3. **Actualizar documentación:** API pública, guías internas, base de conocimiento de soporte,
   manuales, ADR, diagramas. (La documentación técnica de `documents/**` la actualiza el pipeline
   del ApiLLM — queda agendada para la Fase 11.)
4. **Coordinar la ventana:** evitar viernes, fin de mes/cierre contable, campañas, congelamientos
   de código, horas pico; considerar zonas horarias de los usuarios.
5. **Definir quién está de guardia** durante y después del despliegue, y por cuánto tiempo se
   monitorea.
6. **Aprobaciones formales** si aplican: seguridad, cumplimiento, legal, gestión de cambios, dueño
   del negocio.
7. **Capacitación** al equipo de soporte si el cambio altera lo que ven o hacen los usuarios.

---

**Artefactos:** runbook, notas de liberación, paneles y alertas, plan de rollback, comunicaciones
enviadas.

**Criterio de salida:** cualquier persona del equipo podría ejecutar el despliegue y el rollback
siguiendo el runbook.

**Siguiente:** [Fase 9 — Pre-review](fase-09-pre-review.md)
