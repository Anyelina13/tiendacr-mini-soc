#!/usr/bin/env bash
# Se ejecuta DENTRO de tiendacr-web. Despliega DVWA + Apache + Suricata + agente Wazuh + FIM.
# Uso: provision_web.sh <IP_SIEM>
set -euo pipefail
IP_SIEM="${1:?falta IP_SIEM}"
echo "[WEB] Docker + Apache + DVWA..."
sudo apt-get update
sudo apt-get -y install docker.io apache2 curl jq
sudo systemctl enable --now docker
sudo mkdir -p /opt/tiendacr/uploads && sudo chown 33:33 /opt/tiendacr/uploads
sudo docker run -d --name tiendacr-dvwa --restart unless-stopped \
  -p 127.0.0.1:8080:80 -v /opt/tiendacr/uploads:/var/www/html/hackable/uploads vulnerables/web-dvwa \
  || sudo docker run -d --name tiendacr-dvwa --restart unless-stopped \
     -p 127.0.0.1:8080:80 -v /opt/tiendacr/uploads:/var/www/html/hackable/uploads ghcr.io/digininja/dvwa
sudo a2enmod proxy proxy_http headers
[ -f /tmp/tiendacr.conf ] && sudo mv /tmp/tiendacr.conf /etc/apache2/sites-available/tiendacr.conf
sudo a2dissite 000-default || true
sudo a2ensite tiendacr && sudo systemctl reload apache2

echo "[WEB] Suricata NIDS..."
sudo add-apt-repository -y ppa:oisf/suricata-stable
sudo apt-get -y install suricata
[ -f /tmp/local.rules ] && sudo mv /tmp/local.rules /etc/suricata/rules/local.rules
sudo sed -i 's#^\( *HOME_NET:\).*#\1 "[192.168.56.0/24]"#' /etc/suricata/suricata.yaml
sudo sed -i '/af-packet:/,/interface:/ s/interface: .*/interface: enp0s8/' /etc/suricata/suricata.yaml
grep -q "local.rules" /etc/suricata/suricata.yaml || sudo sed -i '/rule-files:/a \  - local.rules' /etc/suricata/suricata.yaml
sudo suricata-update || true
sudo suricata -T -c /etc/suricata/suricata.yaml -v
sudo systemctl enable --now suricata

echo "[WEB] Agente Wazuh -> $IP_SIEM ..."
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo gpg --dearmor -o /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list
sudo apt-get update
sudo WAZUH_MANAGER="$IP_SIEM" WAZUH_AGENT_NAME="tiendacr-web" apt-get -y install wazuh-agent
# Ingesta de logs + FIM
if [ -f /tmp/lf.xml ] && ! grep -q tiendacr_error.log /var/ossec/etc/ossec.conf; then
  sudo python3 -I - <<'PY'
p="/var/ossec/etc/ossec.conf"; s=open(p).read(); add=open("/tmp/lf.xml").read()
if "tiendacr_error.log" not in s:
    s=s.replace("</ossec_config>", add+"\n</ossec_config>"); open(p,"w").write(s)
print("localfiles+FIM inyectado")
PY
fi
sudo systemctl enable --now wazuh-agent
sudo systemctl restart wazuh-agent
echo "[WEB] Listo."
