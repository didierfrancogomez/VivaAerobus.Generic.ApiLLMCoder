# Fase 2 — Identificar el radio de impacto

> **Pregunta que responde:** ¿qué se mueve si toco esto?
> **Apoyo OBLIGATORIO en el repo LLM:**
> - `documents/cross-module/dependency-map.md` — **índice reverso**: para cada modelo/servicio
>   compartido tocado, la lista de conceptos consumidores. Nunca reportar "no impacto" sin haberlo
>   consultado.
> - `llm/ANALYZE-TASK.md` §Phase 3 — la lista de impactos específicos de este sistema (Basket
>   lifecycle, contratos compartidos `OutputModel<T>`/`ErrorCode`, sesiones en vuelo, caché con
>   endpoints de reset, side effects encolados, dinero/puntos/monedas, superficie de seguridad).
> - `documents/cross-module/error-codes.md` si el cambio toca códigos de error.
> - `documents/_meta/flags-and-rules.md` si el cambio toca configuración.

**Objetivo:** enumerar exhaustivamente todo lo que se mueve, directa o indirectamente. Es la fase
que evita los incidentes.

## 2.1 Impacto en código (estático)

1. **Hacia arriba (callers):** quién invoca lo que voy a cambiar. Buscar referencias en todo el
   monorepo/organización, no solo en el archivo abierto.
2. **Hacia abajo (callees):** de qué dependo y si mi cambio altera cómo lo uso.
3. **Interfaces, clases abstractas, traits, tipos compartidos:** ¿hay otras implementaciones que
   también deban cambiar?
4. **Inyección de dependencias / registro de servicios / factories:** ¿hay wiring que actualizar?
5. **Herencia y polimorfismo:** subclases que sobrescriben el comportamiento.
6. **Reflexión, strings mágicos, nombres por convención, serialización:** referencias que el
   compilador y el IDE **no** encuentran. Buscar por texto plano el nombre viejo en todo el repo.
7. **Librerías internas compartidas:** si el cambio es en una librería, quiénes la consumen y en
   qué versión.
8. **Otros repositorios / otros servicios** que dependen de esto.
9. **Código generado** (clientes de API, DTOs, ORMs, GraphQL codegen): ¿hay que regenerar?

## 2.2 Impacto en contratos e integraciones

1. **APIs REST/GraphQL/gRPC:** ¿el cambio es *additive* (compatible) o *breaking*?
   - Breaking: eliminar campo, renombrar, cambiar tipo, cambiar semántica, volver obligatorio un
     opcional, cambiar código de error, cambiar orden/paginación por defecto.
2. **Consumidores conocidos y desconocidos:** frontend web, app móvil (⚠️ **versiones viejas
   instaladas que no puedes forzar a actualizar**), integraciones de terceros, scripts internos,
   reportería, Postman/Zapier de alguien.
3. **Eventos y mensajería:** esquemas de eventos, tópicos, colas, orden de mensajes, idempotencia,
   consumidores existentes, mensajes ya en vuelo durante el despliegue, DLQs.
4. **Webhooks** salientes y entrantes.
5. **Contratos con proveedores externos** (`documents/integrations/_catalog.md`), límites de tasa,
   cuotas, SLAs.
6. **Versionado:** ¿necesito una v2 del endpoint? ¿deprecación con período de gracia? ¿cabecera de
   versión? ⚠️ En este API coexisten pares V1/V2 (`Account`/`Account2`, `Register`/`RegisterV2`…) —
   cambiar uno deja comportamiento inconsistente.
7. **Compatibilidad bidireccional durante el despliegue:** cliente viejo + servidor nuevo, y
   cliente nuevo + servidor viejo (rollback).

## 2.3 Impacto en datos

1. **Esquema:** tablas, columnas, tipos, nullability, constraints, llaves foráneas, valores por
   defecto. (Persistencia de este sistema: `documents/architecture/data-persistence.md` —
   Marten/Postgres.)
2. **Migraciones:** ¿es reversible? ¿bloquea la tabla? ¿cuánto dura sobre el volumen real de
   producción?
3. **Volumen real:** correr el conteo en producción. Una migración instantánea en 100 filas puede
   ser un incidente de 40 minutos en 80 millones.
4. **Índices:** ¿el nuevo query los usa? ¿necesito uno nuevo? ¿el índice nuevo se puede crear
   concurrentemente?
5. **Datos existentes inconsistentes:** ¿la nueva regla es válida para los datos históricos?
   ¿necesito backfill? ¿qué hago con las filas que no cumplen? ⚠️ Documentos Marten ya almacenados
   deben seguir siendo legibles (tolerancia de esquema / backfill).
6. **Backfill:** estrategia, batching, idempotencia, reanudable, tiempo estimado, impacto en carga.
7. **Integridad y duplicidad:** ¿el cambio puede crear duplicados o huérfanos?
8. **Cachés:** invalidación, claves de caché, TTL, cachés en CDN, en cliente, en el ORM, en Redis,
   en memoria del proceso. ⚠️ Este API tiene endpoints Admin de reset
   (`CacheResetDotRez/Resources/Schedule/Settings/ExternalTokens`) — un cambio de datos de
   referencia sin invalidación se ve como "no aplicado" en producción.
9. **Réplicas de lectura y retraso de replicación** (leer justo después de escribir).
10. **Data warehouse / ETL / reportes / dashboards** que leen esas tablas directamente (rompes
    reportes sin darte cuenta).
11. **Backups y retención:** ¿se puede restaurar si esto sale mal?
12. **Datos personales (PII):** ¿el cambio agrega, mueve o expone datos sensibles? Implicaciones de
    privacidad, cifrado, anonimización, políticas de retención. (Base: `documents/operations/security.md`.)

## 2.4 Impacto no funcional

1. **Rendimiento:** nuevas consultas, N+1, llamadas en loop, payloads más grandes, tiempo de
   respuesta, uso de CPU/memoria, consultas sin índice. Hot paths conocidos: Availability, SeatMaps.
2. **Concurrencia:** condiciones de carrera, locks, deadlocks, transacciones largas, ejecuciones
   simultáneas del mismo job. ⚠️ La concurrencia optimista aflora como `BOOKING_WAS_MODIFIED`.
3. **Escalabilidad:** ¿aguanta el pico? ¿qué pasa con 10x el tráfico?
4. **Seguridad:** autenticación, autorización (roles y permisos por cada rol existente), IDOR,
   inyección, XSS, CSRF, secretos, escalación de privilegios, exposición de datos en respuestas y
   en logs.
5. **Multi-tenancy / aislamiento entre clientes** si aplica.
6. **Observabilidad:** ¿qué logs, métricas, trazas y alertas necesito para saber si esto funciona
   en producción?
7. **Resiliencia:** timeouts, reintentos, circuit breakers, degradación elegante, qué pasa si el
   servicio del que dependo está caído.
8. **Internacionalización:** textos nuevos, formatos de fecha/número/moneda, zonas horarias, RTL.
   ⚠️ Hay lógica dependiente de cultura (`IsCultureName`, `IsNonMxCulture`) y manejo
   `TimeZone.Local` vs `Utc`.
9. **Accesibilidad:** contraste, foco, lectores de pantalla, navegación por teclado, etiquetas.
10. **Compatibilidad de UI:** navegadores, tamaños de pantalla, dispositivos, modo oscuro.
11. **Costos:** nuevas llamadas a servicios pagos, almacenamiento, egress, licencias.
12. **Cumplimiento normativo / auditoría:** trazas de auditoría, requisitos legales, contables o
    regulatorios. ⚠️ Dominio de este API: impuestos mexicanos (TUA), reglas de reembolso, PCI si
    hay tarjetas, datos personales (documentos de viaje, CURP, **menores** vía child companions).

## 2.5 Impacto operativo y de entorno

1. **Configuración:** nuevas variables de entorno, feature flags, parámetros, secretos — **en cada
   entorno** (local, dev, QA, staging, prod). ⚠️ 39 config parts del Admin Portal gobiernan reglas
   de negocio en runtime (`documents/_meta/flags-and-rules.md`) — un cambio de config **no pasa por
   PR ni por tests**, lo cual es su propio riesgo.
2. **Infraestructura:** recursos nuevos, permisos IAM, colas, buckets, cron, redes, límites de
   memoria.
3. **Pipeline CI/CD:** pasos nuevos, tiempos de build, dependencias nuevas y sus
   licencias/vulnerabilidades.
4. **Orden de despliegue** entre servicios y entre back/front/móvil.
5. **Jobs programados, batch, procesos nocturnos** que toquen lo mismo.
6. **Herramientas internas y soporte:** paneles de administración, herramientas de back office,
   procesos manuales del equipo de soporte.
7. **Documentación y capacitación:** manuales de usuario, guías de soporte, guiones de venta, base
   de conocimiento. (La documentación técnica del sistema la actualiza el pipeline del ApiLLM en la
   Fase 11 — aquí solo se registra QUÉ habrá que re-documentar.)
8. **Analítica y tracking:** eventos de producto, embudos, experimentos A/B activos sobre esa
   pantalla.

## 2.6 Construir la matriz de impacto

Tabla obligatoria, una fila por elemento impactado:

| Elemento | Tipo (código/dato/contrato/config/no-funcional) | Cómo se afecta | ¿Está en el ticket? | ¿Hay otro ticket? | Dueño | Acción | Riesgo (A/M/B) |
|---|---|---|---|---|---|---|---|

**Regla de oro:** cada fila con "¿Está en el ticket? = No" y "¿Hay otro ticket? = No" es un hueco
que se resuelve en la Fase 3 o se convierte en pregunta bloqueante en la Fase 4.

---

**Artefactos:** `work/<CLAVE>/fase-02-matriz-impacto.md` (y pegada como comentario en el ticket),
cada fila citada contra el código o el dependency-map.

**Criterio de salida:** alguien más del equipo revisa la matriz y no agrega elementos que faltaban
(validación cruzada de 10 minutos).

**Siguiente:** [Fase 3 — Cobertura y viabilidad](fase-03-cobertura-viabilidad.md)
