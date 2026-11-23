# Resumen ejecutivo

**TiendaCR Mini SOC** es un laboratorio de seguridad defensiva construido íntegramente por línea
de comandos sobre VirtualBox. Simula una tienda en línea ficticia y monta alrededor de ella un
Centro de Operaciones de Seguridad (SOC) en miniatura para **detectar, responder y remediar**
ataques reales en un entorno controlado y aislado (red `192.168.56.0/24`).

**Arquitectura (3 VMs):**
- `tiendacr-web` (192.168.56.20): aplicación vulnerable DVWA en Docker tras un reverse proxy
  Apache, con Suricata (NIDS), agente Wazuh (HIDS/FIM) y UFW.
- `tiendacr-siem` (192.168.56.30): Wazuh all-in-one (manager + indexer + dashboard) con reglas
  propias y respuesta automática (`firewall-drop`).
- `kali-atacante` (192.168.56.10): origen controlado de los ataques (nmap, hydra, sqlmap).

**Qué se demuestra:** control de acceso por menor privilegio (SSH solo-llaves + UFW
deny-by-default), monitoreo HIDS+NIDS con reglas propias, respuesta automática ante fuerza bruta,
cuatro ataques (reconocimiento, fuerza bruta, SQLi y webshell) con su detección y tiempo de
alerta, un plan de respuesta a incidentes (NIST SP 800-61) y una remediación medida antes/después
(WAF ModSecurity, bloqueo de PHP en uploads, parches), con el análisis de riesgos (NIST SP 800-30)
y los cálculos CVSS que justifican cada control.

> **Estado de evidencias en vivo:** los números medidos (tiempos de alerta, IDs disparados, CVE del
> host, comparativa antes/después) se marcan `PENDIENTE` hasta ejecutar el lab con las 3 VMs
> levantadas; los scripts de `scripts/` los generan automáticamente. No se inventan datos (§0.7).
