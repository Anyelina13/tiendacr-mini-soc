# Ataques y detecciones (Fases 2.4–2.6) — 20 + 15 pts

Todos los ataques se lanzan desde `kali-atacante` **solo** contra `tiendacr-web` (192.168.56.20),
orquestados por [`scripts/ataques/run.sh`](../../scripts/ataques/run.sh). Cada uno marca inicio
(`t0`), ejecuta, recoge evidencia saneada en `evidencias/ataqueN/` y se mide el tiempo hasta la
alerta con [`scripts/tiempo_alerta.sh`](../../scripts/tiempo_alerta.sh).

## Reglas propias

**Suricata** ([`configs/suricata/local.rules`](../../configs/suricata/local.rules), SID 1000001–1000005):
escaneo SYN, SQLi UNION SELECT, SQLi `OR 1=1`, fuerza bruta en `/vulnerabilities/brute/` y carga de
`.php`. Cada opción (`flow`, `threshold`, `content`, `pcre`, `http.uri`…) se explica en
[`../notas-defensa.md`](../notas-defensa.md).

**Wazuh** ([`configs/wazuh/local_rules.xml`](../../configs/wazuh/local_rules.xml)):
- `100100/100101`: login en la app → **fuerza bruta** (8 en 60 s, misma IP) — MITRE **T1110.001**.
- `100200`: correlaciona las firmas propias de Suricata — MITRE **T1190**.
- `100300`: archivo nuevo en `uploads` (posible webshell vía FIM) — MITRE **T1505.003**.

Los `if_sid` padre (31100, 86601, 554, 5763) se validan con `wazuh-logtest` antes de confiar en
ellos (`evidencias/logtest_apache.txt`).

## Tabla final de ataques (§7.6)

| N.º | Ataque | Herramienta / comando | Evidencia | Regla (ID y nombre) | Tiempo a la alerta | ATT&CK | Captura |
|----|--------|----------------------|-----------|---------------------|--------------------|--------|---------|
| A1 | Reconocimiento | `nmap -sS -sV -T4 -p1-1000` | `evidencias/ataque1/nmap.txt` | Suricata 1000001 "Escaneo SYN" | PENDIENTE | T1046 / T1595 | PENDIENTE |
| A2 | Fuerza bruta login app | `hydra http-get-form` (lista corta) | `evidencias/ataque2/hydra.txt` | Wazuh 100101 + Suricata 1000004 | PENDIENTE | T1110.001 | PENDIENTE |
| A3 | SQL Injection | `sqlmap --dbs` + `OR '1'='1'` | `evidencias/ataque3/sqlmap.txt` | Suricata 1000002/1000003 → Wazuh 100200 | PENDIENTE | T1190 | PENDIENTE |
| A4 | Webshell por upload | `curl -F uploaded=@shell.php` | `evidencias/ataque4/upload.txt` | Wazuh 100300 (FIM) + Suricata 1000005 | PENDIENTE | T1505.003 | PENDIENTE |

Ataque complementario **A2b** (10 intentos SSH con usuario falso) demuestra que SSH **solo** acepta
llaves. El webshell es **inofensivo** (solo imprime `id`) y **se borra** tras la prueba (controlada).

> Los tiempos, IDs disparados y capturas se completan al ejecutar el lab en vivo; mientras tanto se
> marcan `PENDIENTE` conforme al contrato §0.7. Suricata detecta el escaneo **pese a UFW** porque
> captura en la red antes del filtrado.
