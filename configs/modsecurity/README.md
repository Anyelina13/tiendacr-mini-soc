# ModSecurity + OWASP CRS — remediacion (Fase 2.8)

Se instala en `tiendacr-web` **delante** del reverse proxy Apache para filtrar
ataques web antes de que lleguen al contenedor DVWA.

Pasos (ver `scripts/remediacion.sh`):
1. `sudo apt -y install libapache2-mod-security2 modsecurity-crs`
2. Copiar `modsecurity.conf-recommended` -> `modsecurity.conf`.
3. `SecRuleEngine DetectionOnly` -> `SecRuleEngine On` (pasa de solo registrar a bloquear).
4. `sudo systemctl reload apache2`.

Efecto esperado: las peticiones SQLi devuelven **HTTP 403** (CRS regla 942xxx). Suricata
**sigue alertando** porque inspecciona el paquete en la red (deteccion), mientras que
ModSecurity **previene** en la capa 7 — demuestra la diferencia deteccion vs. prevencion.

El audit log `/var/log/apache2/modsec_audit.log` se ingiere en el agente Wazuh para
seguir teniendo trazabilidad tras la remediacion.
