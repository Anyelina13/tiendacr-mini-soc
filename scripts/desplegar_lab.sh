#!/usr/bin/env bash
# ORQUESTADOR MAESTRO — crea el lab de 3 VMs en una sola pasada (Windows + Git Bash).
# Usa VBoxManage unattended (no requiere mkisofs). Afinado a laptops con RAM justa.
# Ejecutar desde la raiz del repo:  bash scripts/desplegar_lab.sh
set -uo pipefail
cd "$(dirname "$0")/.."
source scripts/env.sh
source scripts/lib.sh
VBM="${VBM:-/c/Program Files/Oracle/VirtualBox/VBoxManage.exe}"
[ -x "$VBM" ] || { echo "No encuentro VBoxManage en: $VBM (ajusta \$VBM)"; exit 1; }

# RAM afinada (total ~8 GB en guests). Cierra apps antes de correr esto.
RAM_WEB=2560; RAM_SIEM=4096; RAM_ATK=1536

echo "### 1/6 Red host-only + llave SSH"
"$VBM" hostonlyif create 2>/dev/null || true
# Nota: en Windows el adaptador suele llamarse "VirtualBox Host-Only Ethernet Adapter".
"$VBM" list hostonlyifs | grep -i "Name:" | head -1
[ -f "$SSH_KEY" ] || ssh-keygen -t ed25519 -N '' -f "$SSH_KEY" -C "tiendacr-lab"

crear_vm() { # <nombre> <ram>
  local name="$1" ram="$2"
  "$VBM" createvm --name "$name" --ostype Ubuntu24_LTS_64 --register
  "$VBM" modifyvm "$name" --memory "$ram" --cpus 2 --nic1 nat \
    --nic2 hostonly --hostonlyadapter2 "$HOSTONLY_ADAPTER" --graphicscontroller vmsvga --vram 16
  "$VBM" createmedium disk --filename "$HOME/VirtualBox VMs/$name/$name.vdi" --size 25600 --format VDI
  "$VBM" storagectl "$name" --name SATA --add sata --controller IntelAhci
  "$VBM" storageattach "$name" --storagectl SATA --port 0 --device 0 --type hdd --medium "$HOME/VirtualBox VMs/$name/$name.vdi"
  "$VBM" unattended install "$name" --iso="$UBUNTU_ISO" \
    --user="$ADMIN_USER" --password="$ADMIN_PW" --full-user-name="SOC Lab" \
    --install-additions --locale=es_CR --country=CR --time-zone=America/Costa_Rica \
    --post-install-command="sudo apt-get update; sudo apt-get -y install openssh-server python3" \
    --start-vm=headless
}

echo "### 2/6 Creando VMs (instalacion desatendida, ~20-40 min c/u)"
crear_vm tiendacr-siem "$RAM_SIEM"
crear_vm tiendacr-web  "$RAM_WEB"
crear_vm atacante      "$RAM_ATK"

echo "### 3/6 Esperando SSH (usa la IP NAT temporal; luego fijamos la estatica)"
echo "    Cuando cada VM termine, lee su IP de la red interna con:"
echo "    \"$VBM\" guestproperty get <vm> /VirtualBox/GuestInfo/Net/1/V4/IP"
echo "    y configura la IP estatica enp0s8 (ver EJECUTAR.md paso 4)."
echo "    [Este paso es semi-asistido: las IP estaticas se fijan por netplan via SSH.]"

cat <<'NOTE'

>>> SIGUIENTE (tras tener SSH a las 3 con IP estatica .10/.20/.30):
    source scripts/env.sh && source scripts/lib.sh
    # SIEM
    PUSH configs/wazuh/local_rules.xml     "$IP_SIEM" /tmp/local_rules.xml
    PUSH configs/wazuh/active-response.xml "$IP_SIEM" /tmp/active-response.xml
    PUSH scripts/provision_siem.sh         "$IP_SIEM" /tmp/prov.sh
    R "$IP_SIEM" 'bash /tmp/prov.sh'
    # WEB
    PUSH configs/apache/tiendacr.conf              "$IP_WEB" /tmp/tiendacr.conf
    PUSH configs/suricata/local.rules              "$IP_WEB" /tmp/local.rules
    PUSH configs/wazuh/ossec-agent-localfiles.xml  "$IP_WEB" /tmp/lf.xml
    PUSH scripts/provision_web.sh                  "$IP_WEB" /tmp/prov.sh
    R "$IP_WEB" "bash /tmp/prov.sh $IP_SIEM"
    # ATACANTE
    PUSH scripts/provision_atacante.sh "$IP_KALI" /tmp/prov.sh
    R "$IP_KALI" 'bash /tmp/prov.sh'
    # Hardening + DVWA + ataques
    bash scripts/hardening.sh
    bash scripts/dvwa_setup.sh
    bash scripts/ataques/run.sh
NOTE
echo "### Orquestador base listo. Continua segun EJECUTAR.md."
