#!/usr/bin/env bash
# Se ejecuta DENTRO de tiendacr-siem. Instala Wazuh all-in-one + reglas propias + Active Response.
set -euo pipefail
echo "[SIEM] Instalando Wazuh all-in-one (puede tardar ~15 min)..."
curl -sO https://packages.wazuh.com/4.x/wazuh-install.sh
sudo bash ./wazuh-install.sh -a -i
# Guardar la contrasena del panel FUERA del repo:
sudo tar -xf wazuh-install-files.tar -O wazuh-install-files/wazuh-passwords.txt 2>/dev/null \
  | grep -A1 "admin" | sudo tee /root/wazuh_admin.txt >/dev/null || true
echo "[SIEM] Clave del panel guardada en /root/wazuh_admin.txt (NO subir al repo)."
# Reglas propias + Active Response (archivos subidos por el orquestador a /tmp)
[ -f /tmp/local_rules.xml ]   && sudo cp /tmp/local_rules.xml /var/ossec/etc/rules/local_rules.xml
if [ -f /tmp/active-response.xml ] && ! grep -q firewall-drop /var/ossec/etc/ossec.conf; then
  sudo python3 -I - <<'PY'
p="/var/ossec/etc/ossec.conf"; s=open(p).read(); ar=open("/tmp/active-response.xml").read()
if "firewall-drop" not in s:
    s=s.replace("</ossec_config>", ar+"\n</ossec_config>"); open(p,"w").write(s)
print("active-response inyectado")
PY
fi
sudo systemctl restart wazuh-manager
echo "[SIEM] Listo. Panel: https://$(hostname -I | awk '{print $2}')"
