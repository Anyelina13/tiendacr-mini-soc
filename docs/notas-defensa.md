# Notas de defensa — TiendaCR Mini SOC

Material de estudio: *qué* se hizo, *por qué* y *qué riesgo mitiga*, más el banco de preguntas con
respuestas cortas. Se va completando durante la ejecución.

## Banco de preguntas (con respuestas cortas)

**IDS vs. IPS.** IDS detecta y alerta; IPS además bloquea en línea. Suricata aquí va como IDS
(alerta); Wazuh añade respuesta activa, que actúa como "IPS lógico" sobre el firewall del host.

**NIDS vs. HIDS.** NIDS (Suricata) inspecciona tráfico de red; HIDS (agente Wazuh) vigila el host:
logs, integridad de archivos, vulnerabilidades. Se complementan.

**¿Por qué Suricata ve el escaneo pese a UFW?** Suricata captura en `af-packet` sobre `enp0s8`,
**antes** de que UFW decida descartar el paquete. UFW bloquea la conexión, pero el paquete ya pasó
por la pila donde Suricata lo observa.

**¿Por qué el contenedor en 127.0.0.1?** Docker inyecta reglas iptables que **saltan UFW**. Al
publicar DVWA solo en loopback (`127.0.0.1:8080`), no queda expuesto a la red; todo el acceso pasa
por Apache, que registra la IP real y permite anteponer ModSecurity.

**Explica una regla de Suricata (SQLi OR 1=1, sid 1000003).** `alert http` sobre `$HOME_NET`;
`flow:established,to_server` (conexión ya establecida hacia el servidor); `http.uri` + `pcre` que
busca el patrón `' or '1'='1`; `sid` identifica la regla, `rev` su versión. Clasificación
`web-application-attack`.

**`frequency` / `timeframe` / `same_source_ip` (Wazuh).** La regla 100101 dispara si 8 eventos
hijos (`if_matched_sid 100100`) ocurren en 60 s desde la **misma IP** — así distingue fuerza bruta
de un login fallido normal.

**¿Cómo funciona `firewall-drop` y el riesgo de IP spoofing?** Inserta una regla iptables que
descarta el tráfico de la IP ofensora durante el `timeout`. Riesgo: si el atacante **falsifica** la
IP de un tercero legítimo, provoca que el sistema bloquee a ese tercero (DoS autoinducido). Se
mitiga con lista blanca, timeout corto y revisión humana.

**¿Qué es FIM y por qué ve el webshell?** File Integrity Monitoring: el agente vigila
`/opt/tiendacr/uploads` en tiempo real; al aparecer un `.php` nuevo genera la regla 100300. Detecta
el webshell aunque el WAF no lo haya visto.

**¿Cómo se calculó cada CVSS? ¿Qué es PR:L?** Con la calculadora de FIRST, fijando métricas base
(AV, AC, PR, UI, S, C, I, A). **PR:L** = *Privileges Required: Low* = el ataque necesita una cuenta
de bajo privilegio (p. ej. sesión DVWA) pero no de administrador.

**Probabilidad / impacto / riesgo residual.** Riesgo = Probabilidad × Impacto (1–5). El residual es
el riesgo que queda **después** de aplicar controles; se recalcula tras la remediación.

**Responsabilidad compartida.** En IaaS el proveedor asegura hardware/hipervisor; el cliente,
SO/red/acceso/app/datos/monitoreo. En el lab administramos la parte del cliente (UFW ≈ Security
Group, etc.).

**¿Por qué Suricata sigue alertando tras remediar?** Porque detecta en la red (el paquete SQLi
existe), aunque ModSecurity lo bloquee en la app. Demuestra detección ≠ prevención.

**Táctica y técnica ATT&CK de cada ataque.** A1 Discovery/Recon (T1046/T1595); A2 Brute Force
(T1110.001); A3 Exploit Public-Facing App (T1190); A4 Web Shell (T1505.003).

**¿Cómo se midió el tiempo de alerta y qué lo hace variar?** `tiempo_alerta.sh` resta `t0` del
ataque al `timestamp` de la primera alerta en `alerts.json`. Varía por: sincronización de reloj
(NTP), umbral/frecuencia de la regla, carga del SIEM e intervalo de lectura de logs.

**Mejoras con más presupuesto.** Falco (runtime), CrowdSec (reputación colaborativa), alertas por
correo, y en nube real GuardDuty.

## Bitácora (qué/por qué/riesgo) — se llena durante la ejecución
> PENDIENTE: por cada paso ejecutado, anotar 2–4 líneas (qué, por qué, qué riesgo mitiga).
