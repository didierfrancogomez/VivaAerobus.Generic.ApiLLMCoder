# Fase 7 — Testing

> **Pregunta que responde:** ¿funciona, y no rompí el radio de impacto?
> **Apoyo en el repo LLM:** `documents/operations/testing.md` — mapa real de cobertura. Donde la
> cobertura está **ausente** (Basket, Booking, Checkin, Irop, Train, Transfer, Vehicle, Admin,
> Internal, clientes de integración), escribir los tests **es parte del alcance**, no un follow-up.
> ⚠️ Varios flujos dependen de **sistemas de prueba externos** (DotRez, PSPs, Hopper, TrenMaya…) —
> "testeable" no es un supuesto, se verifica.

**Objetivo:** demostrar que funciona lo nuevo **y** que no se rompió nada del radio de impacto. La
Fase 2 define exactamente qué hay que probar aquí — es la misma lista.

## 7.1 Niveles de prueba

1. **Unitarias:** lógica de negocio, ramas condicionales, funciones puras, transformaciones.
   Rápidas y sin dependencias externas.
2. **Integración:** capa de datos con base real (contenedor), transacciones, consultas,
   migraciones, serialización, integración entre módulos.
3. **De contrato:** que el request/response cumpla el esquema acordado; contract tests con el
   consumidor si existen.
4. **End-to-end / de flujo:** el recorrido completo del usuario en los caminos principales.
5. **Manual exploratoria:** lo que ningún test automatizado ve. Usar el producto como usuario,
   intentando romperlo.
6. **De regresión sobre el radio de impacto:** probar explícitamente **cada elemento de la matriz**
   de la Fase 2, no solo lo que cambiaste.

## 7.2 Qué probar (casos)

- **Camino feliz** de cada criterio de aceptación (uno a uno, con el criterio a la vista).
- **Casos negativos:** entradas inválidas, faltantes, tipos incorrectos, valores fuera de rango.
- **Bordes:** cero, uno, muchos, el máximo, el máximo+1, vacío, nulo, cadena vacía, cadenas muy
  largas, caracteres especiales y emojis, fechas límite, cambio de mes/año, zonas horarias, horario
  de verano.
- **Autorización:** **cada rol existente**, incluyendo el usuario sin permisos y el usuario de otro
  tenant/cliente. Acceso directo al endpoint saltándose la UI.
- **Estados del recurso:** inexistente, eliminado (soft delete), archivado, en proceso, ya
  procesado. ⚠️ En este API: estados del Basket (Active/Passive/Expired, dos relojes
  independientes).
- **Concurrencia:** dos peticiones simultáneas, doble clic, doble envío del mismo evento, ejecución
  paralela del mismo job. ⚠️ Verificar la interacción con `BOOKING_WAS_MODIFIED`.
- **Idempotencia:** ejecutar dos veces la misma operación y verificar que el resultado no se
  duplica. Crítico en pagos y check-in.
- **Fallos de dependencias:** servicio externo caído, lento (timeout), respondiendo error,
  respondiendo basura.
- **Datos legados:** registros viejos con el formato antiguo, nulos históricos, datos
  inconsistentes reales. ⚠️ Documentos Marten almacenados antes del cambio.
- **Compatibilidad de versiones:** cliente viejo contra servidor nuevo, y **cliente nuevo contra
  servidor viejo** (esto es lo que revienta durante el despliegue y el rollback).
- **Feature flag:** apagado (comportamiento anterior intacto) y prendido (comportamiento nuevo), y
  el cambio en caliente entre ambos.
- **Rendimiento:** cantidad de consultas por request (detectar N+1), plan de ejecución de las
  consultas nuevas, tiempo con volumen realista, tamaño de la respuesta.
- **Seguridad:** inyección, XSS, IDOR (cambiar el id en la URL), datos sensibles en la respuesta y
  **en los logs**, límites de tasa.
- **UI:** navegadores y versiones soportadas, móvil/tablet/escritorio, estados de carga, vacío,
  error y parcial; accesibilidad (teclado, foco, contraste, lector de pantalla); i18n en cada
  idioma soportado.
- **Migración:** aplicarla, verificar los datos, **revertirla**, volver a aplicarla; medir duración
  sobre un volumen tipo producción; verificar que el backfill es reanudable.

## 7.3 Higiene y validación de las pruebas

1. **Verificar que los tests realmente fallan sin el cambio** (invertir la corrección y ver el
   rojo). Un test que pasa siempre no prueba nada.
2. **Tests deterministas:** sin dependencia del reloj real, del orden de ejecución, de la red o de
   datos compartidos. Cero tests intermitentes nuevos.
3. **Cobertura con criterio:** cubrir las ramas de riesgo, no perseguir un porcentaje. Ningún
   camino crítico sin prueba.
4. **Correr la suite completa**, no solo los tests que escribiste (ahí aparecen las regresiones).
5. **Revisar el pipeline completo en CI**, no solo local (diferencias de entorno, zona horaria,
   locale, orden).
6. **Probar en un entorno tipo producción** (staging) con datos y configuración realistas antes de
   dar por cerrado.

## 7.4 Entrega a QA

1. Entregar **notas de prueba**: qué cambió, qué probar, cómo reproducir, usuarios/datos de prueba,
   qué NO cambió pero conviene mirar (el radio de impacto), riesgos conocidos, supuestos pendientes
   de validar.
2. Adjuntar evidencia: capturas, video del flujo, respuestas de ejemplo.
3. Definir el estado del flag durante las pruebas de QA.
4. Ciclo de corrección: cada defecto encontrado → arreglar → **agregar test que lo cubra** → volver
   a probar el flujo completo, no solo el defecto.
5. Registrar en el ticket la aprobación de QA y del PO (aceptación funcional).

---

**Artefactos:** tests automatizados, evidencia de pruebas manuales, notas para QA, resultados de
rendimiento/migración.

**Criterio de salida:** todos los criterios de aceptación verificados con evidencia, radio de
impacto probado, CI verde, cero defectos abiertos de severidad alta.

**Siguiente:** [Fase 8 — Preparación para liberación](fase-08-liberacion.md)
