# Remediación y reevaluación (Fases 2.7–2.8) — 15 pts

Aplicada por [`scripts/remediacion.sh`](../../scripts/remediacion.sh) vía SSH sobre `tiendacr-web`,
seguida del snapshot `S4-remediado`.

## Controles aplicados

1. **DVWA a nivel `impossible` + cambio de contraseña admin** por API (curl con token).
2. **WAF ModSecurity + OWASP CRS** en modo bloqueo (`SecRuleEngine On`) — ver
   [`configs/modsecurity/README.md`](../../configs/modsecurity/README.md). Las SQLi pasan a
   devolver **HTTP 403** (reglas CRS 942xxx).
3. **Sin ejecución de PHP en `uploads`** (`php_admin_flag engine off`): un `.php` subido ya no se
   ejecuta, neutralizando el webshell.
4. **Parches del SO** (`apt upgrade`) y comparación del inventario de vulnerabilidades Wazuh
   antes/después.
5. **Ingesta del audit log de ModSecurity** en el agente para mantener trazabilidad.

## Reevaluación (antes/después)

Se re-ejecuta `scripts/ataques/run.sh` sobre el estado remediado (mínimo A2 y A3). Resultado
esperado y columna a llenar con la medición real:

| Ataque | Antes (vulnerable) | Después (remediado) | Evidencia |
|--------|--------------------|---------------------|-----------|
| A2 Fuerza bruta | Hydra encuentra `password`; Active Response bloquea | Hydra **no** encuentra clave (contraseña fuerte) y es bloqueado antes | PENDIENTE |
| A3 SQLi | `sqlmap` extrae las BD | ModSecurity responde **403**; `sqlmap` no extrae | PENDIENTE |
| A4 Webshell | `shell.php` ejecuta `id` | Subida permitida pero PHP **no se ejecuta** | PENDIENTE |

**Observación clave (detección ≠ prevención):** aun con ModSecurity bloqueando, **Suricata sigue
alertando** porque inspecciona el paquete en la red. ModSecurity **previene** (capa 7); Suricata
**detecta** (red). Ambos son complementarios.

## Riesgo residual

Tras la remediación se re-estima P×I en `matriz_riesgos.csv` (columna `Riesgo_residual`): p. ej.
R01 (SQLi) baja de **25** a nivel medio por el WAF; R02 (fuerza bruta) baja por el bloqueo
automático; R04 (webshell) baja porque el upload ya no ejecuta PHP. Se genera además una gráfica
antes/después (`evidencias/antes_despues/`).

> Estado: valores medidos **PENDIENTE** de la corrida en vivo (§0.7).
