# Fase 6 — Implementación

> **Pregunta que responde:** construir según el plan, sin desviarse en silencio.
> **Dónde se implementa:** en el repo del API (`../VivaAerobus.Generic.Api`), branch desde
> `master`. Nunca se escribe código del sistema en este repo ni en el ApiLLM.
> **Apoyo OBLIGATORIO en el repo LLM:**
> - `guidelines/**` (`STY`/`ARC`/`ROB`/`PRC`) — **normativo**: es la vara que aplican los
>   revisores humanos y el gate de la Fase 9.
> - `documents/architecture/conventions.md` + `patterns-cqrs.md` — dónde va cada pieza (controller
>   delgado, handler por feature, builders, validators registrados).
> - `llm/change-playbook.md` paso 7: si la implementación revela algo que el análisis no vio,
>   **detenerse y volver al gate (Fase 4)** en lugar de improvisar.

**Objetivo:** ejecutar el plan de forma verificable e incremental, sin desviarse en silencio.

## 6.1 Preparación del entorno

1. Actualizar la rama base (`master`) y crear la rama con la convención del equipo:
   `tipo/CLAVE-123-descripcion-corta`.
2. Instalar dependencias, correr migraciones, sembrar datos, **verificar que la suite de tests pasa
   en verde ANTES de tocar nada**. Si ya está roja, ese es un hallazgo previo (no lo heredes
   silenciosamente). Setup local: `documents/operations/local-setup.md` del repo LLM.
3. Tener datos realistas: cantidad, casos borde, datos "sucios" parecidos a producción.
4. Tener acceso a lo necesario (credenciales de sandbox, permisos, flags) — resolverlo aquí, no a
   mitad de camino.

## 6.2 Ciclo de trabajo

1. **Para bugs: escribir primero el test que falla** y que demuestra el bug. Sin ese test rojo no
   sabes que lo arreglaste; sabes que ya no lo ves.
2. **Para features: escribir el test o el caso de aceptación antes o junto** con el código,
   empezando por el camino feliz y luego los bordes.
3. **Trabajar en incrementos pequeños**, corriendo tests y linters localmente en cada paso. Nunca
   acumular 3 días de cambios sin verificar.
4. **Commits pequeños, atómicos y con mensaje explicativo** (formato convencional:
   `feat(scope): ...`, `fix(scope): ...`, con la clave del ticket). El mensaje explica el *por
   qué*, el diff ya explica el *qué*.
5. **Sincronizar con la rama base a diario** (rebase o merge según el estándar del equipo) para
   evitar el conflicto gigante del final.
6. **Verificación funcional manual continua**: no esperar al final para ver la pantalla o llamar al
   endpoint.

## 6.3 Calidad durante el desarrollo

1. **Respetar los estándares del proyecto:** las reglas de `guidelines/**` son normativas; además
   estilo, formateo automático, linter, análisis estático, tipado, convenciones de nombres,
   estructura de carpetas. Que el pipeline no sea la primera vez que se corren.
2. **Nombres claros por encima de comentarios.** Comentar solo el *por qué* no obvio y las
   decisiones raras con su razón.
3. **Manejo de errores explícito:** no silenciar excepciones, no capturar de forma genérica,
   mensajes útiles, errores tipificados, no exponer detalles internos al cliente. Códigos de error:
   agregar, **nunca reutilizar** uno existente (`documents/cross-module/error-codes.md`).
4. **Validación en el borde y en el servidor** siempre, no solo en el frontend.
5. **Sin secretos en el código.** Nada de credenciales, tokens, URLs internas, datos reales de
   clientes.
6. **Instrumentar mientras se implementa:** los logs, métricas y trazas del plan de observabilidad
   son parte del cambio, no un extra.
7. **Idempotencia y reintentos** en todo lo que sea proceso asíncrono, job, webhook o pago. ⚠️ En
   este API los side effects encolados (insurances, child-companion, comments) fallan de forma
   invisible en la respuesta — diseñar su visibilidad.
8. **Actualizar en el mismo cambio:** tests, README si cambia el setup, contratos/OpenAPI, textos
   de i18n, configuración de todos los entornos, tipos compartidos, código generado. (La
   documentación del sistema en `documents/**` NO se toca aquí — la actualiza el pipeline del
   ApiLLM en la Fase 11.)
9. **Feature flag apagado por defecto** y verificar que **ambos caminos** (prendido y apagado)
   funcionan.
10. **Recorrer la matriz de impacto y tocar cada punto** que requiera cambio; marcarlos a medida
    que se resuelven.

## 6.4 Control de desvíos (crítico)

1. **Regla de no expansión de alcance:** todo hallazgo que no sea necesario para cumplir los
   criterios de aceptación se anota y se convierte en ticket nuevo. No se arregla aquí.
2. **Excepción (regla del boy scout acotada):** mejoras triviales y locales al código que ya estás
   tocando, sí; refactors que crecen el diff, no.
3. **Si aparece un problema grande** (el plan no funciona, el impacto es mayor, hay una
   imposibilidad técnica): **detenerse y volver a la Fase 4/5**. Comunicarlo el mismo día. No
   intentar "resolverlo con más horas".
4. **Si el diff crece demasiado** (>~400 líneas de cambio real, o toca dominios sin relación):
   partirlo en varios PRs.
5. **Regla del timebox:** si llevas más de ~2 horas atascado sin avanzar, pide ayuda. No es
   debilidad, es economía.
6. **Reportar avance real a diario**, incluyendo lo que se complicó. Las sorpresas al final del
   sprint son fallas de proceso, no de código.

---

**Artefactos:** rama con commits limpios, tests, configuración actualizada.

**Criterio de salida:** todos los criterios de aceptación implementados, todos los puntos de la
matriz de impacto atendidos, suite verde localmente.

**Siguiente:** [Fase 7 — Testing](fase-07-testing.md)
