# Anexo C — Cómo habilitar este proceso en el equipo (implantación)

No se implanta completo el lunes. Si lo intentas, el equipo lo rechaza por burocrático y vuelve al
caos.

## Secuencia de adopción sugerida

**Semana 1–2: hacer visible lo que ya falla.**
Empieza por lo que da resultado inmediato y cuesta casi nada:

1. **Plantilla de PR** en el repositorio del API (`.github/pull_request_template.md`, contenido en
   [fase-10](fase-10-pr-revision.md)). Costo cero, beneficio inmediato.
2. **Definition of Ready y Definition of Done** acordadas y visibles en el tablero. Regla: no se
   pasa a "En progreso" un ticket que no cumple la DoR ([fase-00 §0.2](fase-00-intake.md)).
3. **Regla del ticket como memoria:** toda decisión se escribe en el ticket, aunque se haya hablado
   en persona.

**Semana 3–4: introducir el radio de impacto.**

4. **Matriz de impacto obligatoria** (aunque sea 5 filas) antes de codificar, pegada como
   comentario. Es el mayor retorno de todo este documento.
5. **Validación cruzada de 10 minutos** de la matriz con otra persona. Empieza a compartir
   conocimiento del sistema como efecto secundario.
6. **Formato de pregunta bloqueante** con opciones y recomendación ([fase-04 §4.2](fase-04-bloqueantes.md)).

**Mes 2: planeación y calidad.**

7. **Design review corto** (15 min) obligatorio para tickets grandes o riesgosos; opcional para los
   pequeños.
8. **Plan de pruebas antes de codificar** (aunque sea una lista de casos).
9. **Checklist de pre-review** como hábito individual ([anexo-a](anexo-a-checklist.md)).
10. **Límite de tamaño de PR** acordado por el equipo.

**Mes 3: operación.**

11. **Runbook y plan de rollback** obligatorios para cambios con migración o coordinación entre
    servicios.
12. **Feature flags** con ticket de limpieza creado desde el inicio.
13. **Observabilidad como parte del cambio**, no como tarea aparte.
14. **Retro de proceso** mensual: ¿qué se detectó tarde y en qué fase debió detectarse?

## Reglas para que no se convierta en burocracia

- **Escalar el rigor al riesgo.** Un cambio de texto no necesita ADR ni runbook. Los 3 niveles
  (trivial / normal / riesgoso) y qué pasos aplican a cada uno están en `../CLAUDE.md`; el criterio
  queda explícito en el equipo.
- **Cada paso debe tener un dueño de la evidencia.** Si nadie revisa que se hizo, el paso no
  existe.
- **Automatizar todo lo automatizable:** linters, formateo, análisis estático, validación de
  mensajes de commit, plantillas, CODEOWNERS, validación de que el PR referencia un ticket, chequeo
  de secretos. Lo que puede validar una máquina no debe consumir atención humana. (Referencia de
  cómo se hace con hooks: `.claude/hooks/` del repo ApiLLM.)
- **Medir el efecto, no el cumplimiento.** Indicadores útiles: retrabajo por alcance mal entendido,
  defectos escapados a producción, tiempo de ciclo del ticket, tiempo hasta la primera revisión,
  rollbacks, incidentes por causa evitable, tickets bloqueados y por cuánto tiempo. Si el proceso
  no mueve esos números, ajústalo.
- **Revisar el proceso cada mes** y podar lo que no aporta. Un checklist que nadie usa es peor que
  no tenerlo, porque enseña que las reglas se ignoran.
- **Un dueño del proceso** que lo mantenga y lo defienda; sin dueño, se desvanece en 6 semanas.
