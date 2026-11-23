# EJECUTAR — corrida en vivo del lab (una sola pasada)

Guía para levantar el laboratorio real y generar las evidencias. Pensada para correrla **juntas**
desde Git Bash en Windows. Todo el código y la documentación ya están listos; esto es solo la
ejecución física.

## 0. Antes de empezar (RAM — importante)
El lab usa ~**8 GB** de RAM en las 3 VMs (SIEM 4 GB, web 2.5 GB, atacante 1.5 GB). Tu laptop tiene
16 GB pero Windows + apps dejan poco libre.
- **Cierra** navegador, Office, Teams, etc. (o **reinicia** y no abras nada).
- Verifica que haya ≥ **9 GB libres**:
  ```powershell
  [math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1024)   # MB libres
  ```
- Asegúrate de que **no haya otras VMs encendidas** (`VBoxManage list runningvms`).

## 1. Prerrequisitos
- VirtualBox 7.2 (ya instalado).
- ISO de Ubuntu Server: usa `ubuntu-26.04.1-live-server-amd64.iso` (está en Descargas) — el plan
  pedía 24.04 server; se documenta la diferencia de versión. **No** sirve el ISO *desktop* para
  instalación desatendida.
- En Git Bash:
  ```bash
  cd "/c/Users/nglnc/Downloads/tiendacr-mini-soc"
  cp scripts/env.sh.example scripts/env.sh
  # edita scripts/env.sh:  UBUNTU_ISO, ADMIN_PW, HOSTONLY_ADAPTER (nombre en Windows)
  ```
  El nombre del adaptador host-only en Windows se ve con:
  `"/c/Program Files/Oracle/VirtualBox/VBoxManage.exe" list hostonlyifs`

## 2. Crear las 3 VMs (desatendido)
```bash
bash scripts/desplegar_lab.sh
```
Crea la red host-only, la llave SSH y las 3 VMs con **instalación desatendida**
(`VBoxManage unattended`, sin necesidad de `mkisofs`). Cada instalación tarda ~20-40 min.

## 3. Fijar IPs estáticas (.10/.20/.30)
Cuando cada VM termine e inicie, lee su IP temporal (NAT/host-only) y fija la estática en `enp0s8`:
```bash
VBM="/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"
"$VBM" guestproperty get tiendacr-siem /VirtualBox/GuestInfo/Net/1/V4/IP
```
Por SSH (con la clave del usuario `soc`), crea `/etc/netplan/60-lab.yaml` con la IP destino
(.30 SIEM, .20 web, .10 atacante) y `sudo netplan apply`. Plantilla en
`scripts/crear_vm_ubuntu.sh` (bloque netplan). Copia la llave pública a cada VM:
```bash
source scripts/env.sh && source scripts/lib.sh
ssh-copy-id -i "${SSH_KEY}.pub" soc@<ip>     # repetir para las 3
```

## 4. Provisionar (monitoreo, objetivo, atacante)
```bash
source scripts/env.sh && source scripts/lib.sh
# SIEM: Wazuh all-in-one + reglas + active response
PUSH configs/wazuh/local_rules.xml     "$IP_SIEM" /tmp/local_rules.xml
PUSH configs/wazuh/active-response.xml "$IP_SIEM" /tmp/active-response.xml
PUSH scripts/provision_siem.sh         "$IP_SIEM" /tmp/prov.sh
R "$IP_SIEM" 'bash /tmp/prov.sh'
# WEB: DVWA + Apache + Suricata + agente + FIM
PUSH configs/apache/tiendacr.conf             "$IP_WEB" /tmp/tiendacr.conf
PUSH configs/suricata/local.rules             "$IP_WEB" /tmp/local.rules
PUSH configs/wazuh/ossec-agent-localfiles.xml "$IP_WEB" /tmp/lf.xml
PUSH scripts/provision_web.sh                 "$IP_WEB" /tmp/prov.sh
R "$IP_WEB" "bash /tmp/prov.sh $IP_SIEM"
# ATACANTE: nmap/hydra/sqlmap
PUSH scripts/provision_atacante.sh "$IP_KALI" /tmp/prov.sh
R "$IP_KALI" 'bash /tmp/prov.sh'
```

## 5. Hardening, objetivo y snapshots
```bash
bash scripts/hardening.sh          # SSH solo-llaves + UFW -> evidencias/
bash scripts/dvwa_setup.sh         # inicializa DVWA (security=low)
# Snapshots de hito:
for vm in atacante tiendacr-web tiendacr-siem; do "$VBM" snapshot "$vm" take S3-vulnerable-listo; done
```

## 6. Ataques + mediciones (EVIDENCIA)
```bash
bash scripts/ataques/run.sh                 # A1 recon, A2 fuerza bruta, A3 SQLi, A4 webshell
# Tiempo hasta la alerta (ejemplos):
bash scripts/tiempo_alerta.sh "$(cat evidencias/ataque2/t0.txt)" 100101
bash scripts/tiempo_alerta.sh "$(cat evidencias/ataque1/t0.txt)" 86601
# Active response: confirmar bloqueo
R "$IP_WEB" 'sudo iptables -S | grep '"$IP_KALI"'' | tee evidencias/ataque2/iptables_block.txt
```

## 7. Remediación + reevaluación (antes/después)
```bash
bash scripts/remediacion.sh                 # ModSecurity + no-php-uploads + parches
bash scripts/ataques/run.sh                 # repetir (minimo A2/A3) -> comparar
for vm in atacante tiendacr-web tiendacr-siem; do "$VBM" snapshot "$vm" take S4-remediado; done
```

## 8. Rellenar el informe con los datos reales
Con las evidencias en `evidencias/`, actualiza los `PENDIENTE` de:
- `docs/informe/05_ataques.md` (tiempos, IDs, capturas)
- `docs/riesgos/matriz_riesgos.csv` (columna Riesgo_residual)
- `docs/informe/08_remediacion.md` (tabla antes/después)
Luego recompila el Word/PDF:
```bash
powershell -ExecutionPolicy Bypass -File "$TMP/build_informe.ps1"   # o re-ejecuta el builder
```

## Problemas comunes
- **Autoinstall no arranca:** revisa que el ISO sea *server* (no desktop) y que `--ostype` sea de Ubuntu.
- **No hay SSH:** la VM quizá no instaló `openssh-server`; entra por consola una vez y
  `sudo apt -y install openssh-server`.
- **Suricata no ve `enp0s8`:** confirma el nombre de la interfaz con `ip a` y ajusta `suricata.yaml`.
- **Wazuh pesado:** si el indexer no levanta por RAM, baja el heap de JVM o sube la RAM del SIEM a 6 GB.
- **Te quedas sin SSH tras UFW:** `hardening.sh` prueba una 2ª conexión antes de cerrar; si pasa,
  entra por consola y `sudo ufw allow from <tu_ip> to any port 22 proto tcp`.
