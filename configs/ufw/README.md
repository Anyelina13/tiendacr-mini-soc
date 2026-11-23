# Reglas UFW — TiendaCR (denegacion por defecto + menor privilegio)

Principio general: `default deny incoming`, `default allow outgoing`. Solo se abre lo
estrictamente necesario y **acotado por IP de origen** (nada de `Anywhere` / `0.0.0.0/0`).

## tiendacr-web (192.168.56.20)

| # | Regla | Origen | Puerto | Justificacion | Riesgo que mitiga | Principio |
|---|-------|--------|--------|---------------|-------------------|-----------|
| 1 | allow | 192.168.56.1 (host) | 22/tcp | Administracion SSH desde la laptop | Acceso SSH no autorizado | Menor privilegio |
| 2 | allow | 192.168.56.10 (kali) | 22/tcp | Pruebas de control de acceso | Exposicion SSH a toda la red | Menor privilegio |
| 3 | allow | 192.168.56.1 (host) | 80/tcp | Acceso a la app desde la laptop | Exposicion web general | Denegacion por defecto |
| 4 | allow | 192.168.56.10 (kali) | 80/tcp | Lanzar los ataques contra la app | Trafico web no controlado | Denegacion por defecto |

## tiendacr-siem (192.168.56.30)

| # | Regla | Origen | Puerto | Justificacion | Riesgo que mitiga | Principio |
|---|-------|--------|--------|---------------|-------------------|-----------|
| 1 | allow | 192.168.56.1 (host) | 22/tcp | Administracion SSH del SIEM | Acceso SSH no autorizado | Menor privilegio |
| 2 | allow | 192.168.56.1 (host) | 443/tcp | Panel web de Wazuh (unico acceso GUI) | Exposicion del panel | Menor privilegio |
| 3 | allow | 192.168.56.20 (web) | 1514/tcp | Eventos del agente -> manager | Suplantacion de agentes | Menor privilegio |
| 4 | allow | 192.168.56.20 (web) | 1515/tcp | Registro/enrolamiento del agente | Enrolamiento no autorizado | Menor privilegio |

> Nota: el puerto 1514/1515 solo se abre al host web, no a toda la red. El panel 443
> solo al host admin. Asi, aunque Kali comprometa la web, no alcanza los puertos del SIEM.
