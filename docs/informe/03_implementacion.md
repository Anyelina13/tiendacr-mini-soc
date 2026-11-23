# Implementación

## 3.1 Infraestructura por CLI

Las VMs Ubuntu se crean con **instalación desatendida** (autoinstall/cloud-init inyectado por un
ISO `seed` con usuario, llave SSH, IP estática y paquetes base) mediante
[`scripts/crear_vm_ubuntu.sh`](../../scripts/crear_vm_ubuntu.sh). Kali se importa de un OVA para
evitar instalación interactiva. Toda la red host-only, las llaves y los snapshots se gestionan con
`VBoxManage`. El acceso de administración es por llave SSH (`tiendacr_ed25519`); la contraseña de
consola es solo un respaldo.

## 3.2 Despliegue del objetivo (Fase 2.1)

En `tiendacr-web`: Docker + Apache, el contenedor DVWA publicado en `127.0.0.1:8080` con un volumen
para `uploads`, el vhost reverse proxy
([`configs/apache/tiendacr.conf`](../../configs/apache/tiendacr.conf)) y la inicialización de DVWA
**sin navegador** por `curl` ([`scripts/dvwa_setup.sh`](../../scripts/dvwa_setup.sh), que crea la BD
y fija `security=low`). Verificación: `ss -tlnp` debe mostrar 8080 solo en 127.0.0.1.

## 3.3 Control de acceso (Fase 2.2) — 15 pts

**SSH solo-llaves** ([`configs/ssh/99-hardening.conf`](../../configs/ssh/99-hardening.conf)):
`PasswordAuthentication no`, `PermitRootLogin no`, `MaxAuthTries 3`, `AllowUsers soc`. Evidencia:
un intento sin llave debe fallar (`evidencias/ssh_sin_llave.txt`).

**UFW deny-by-default acotado por IP de origen** (ver tabla completa en
[`configs/ufw/README.md`](../../configs/ufw/README.md)). Principios aplicados: **denegación por
defecto** (`default deny incoming`) y **menor privilegio** (cada puerto abierto solo a la IP que lo
necesita; **ninguna** regla `Anywhere`/`0.0.0.0/0`). Lo aplica
[`scripts/hardening.sh`](../../scripts/hardening.sh) de forma idempotente, probando una segunda
conexión antes de cerrar la actual para no quedarse fuera.

## 3.4 Monitoreo (Fase 2.3)

- **Wazuh all-in-one** en `tiendacr-siem` (`wazuh-install.sh -a -i`). La contraseña del panel se
  guarda **fuera del repo** (`.env`, gestor de contraseñas).
- **Agente Wazuh** en `tiendacr-web`, enrolado contra el manager; verificación con
  `agent_control -l` (`evidencias/agente_activo.txt`).
- **Suricata NIDS** en `tiendacr-web`, `HOME_NET=192.168.56.0/24`, interfaz `enp0s8`, con las
  reglas propias ([`configs/suricata/local.rules`](../../configs/suricata/local.rules)).
- **Ingesta + FIM** ([`configs/wazuh/ossec-agent-localfiles.xml`](../../configs/wazuh/ossec-agent-localfiles.xml)):
  el agente lee `eve.json`, `access.log` y `tiendacr_error.log`, y vigila en tiempo real
  `/opt/tiendacr/uploads` y `/etc/{ssh,apache2,suricata/rules}` (integridad de archivos).

El inventario de vulnerabilidades del host (Vulnerability Detection de Wazuh) se guarda en
`evidencias/vuln_inventory.json` y alimenta el CVE real de §3.3 del análisis de riesgos.
