# Plan de respuesta a incidentes (NIST SP 800-61 r2)

Caso de aplicación: **Ataque A2 — fuerza bruta al login de la aplicación** (MITRE T1110.001).
Roles: **Analista N1** (monitoreo), **Responsable de incidente** (coordina y decide), **Admin**
(ejecuta cambios). Se reparten entre los integrantes A/B.

| Fase (NIST 800-61) | Acciones | Rol | Tiempo objetivo |
|--------------------|----------|-----|-----------------|
| **1. Preparación** | SIEM operativo, reglas propias, Active Response con lista blanca, snapshots, este plan documentado | Admin (A) + Resp. (B) | Previo (continuo) |
| **2. Detección y análisis** | Alerta Wazuh 100101 + Suricata 1000004; confirmar IP origen, nº de intentos, ventana temporal; descartar falso positivo | Analista N1 (B) | ≤ 2 min desde la alerta |
| **3. Contención** | `firewall-drop` bloquea la IP 180 s automáticamente; el analista valida el bloqueo (`iptables -S`, alerta 651) y decide si extenderlo | Analista N1 (B) + Resp. (A) | ≤ 5 min |
| **4. Erradicación** | Revisar si hubo acceso exitoso; forzar cambio de contraseña del usuario atacado; revisar logs en busca de pivoteo | Admin (A) | ≤ 15 min |
| **5. Recuperación** | Confirmar servicio normal, monitoreo reforzado de esa IP/usuario, re-habilitar tráfico legítimo si se bloqueó de más | Admin (A) + Analista N1 (B) | ≤ 30 min |
| **6. Lecciones aprendidas** | Documentar línea de tiempo, afinar umbrales, evaluar bloqueo de duración creciente, actualizar matriz de riesgos (riesgo residual) | Resp. de incidente (B) | ≤ 24 h |

## Indicadores y criterios
- **Indicador de compromiso (IoC):** ≥ 8 POST a `/vulnerabilities/brute/` desde una misma IP en 60 s.
- **Criterio de escalamiento:** si tras el bloqueo la misma IP reaparece o se detecta acceso
  exitoso, el Responsable de incidente escala y se considera bloqueo manual prolongado.
- **Cierre:** sin nuevas alertas de esa IP durante 1 h y servicio estable.

## Relación con los controles
El plan apoya los controles de R02/R03 de la matriz de riesgos: la detección (reglas) y la
contención (Active Response) reducen la probabilidad de éxito de la fuerza bruta; la fase de
lecciones alimenta el **riesgo residual** de §8.
