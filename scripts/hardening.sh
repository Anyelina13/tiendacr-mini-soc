#!/usr/bin/env bash
# Fase 2.2 — Control de acceso: SSH solo-llaves + UFW deny-by-default. Idempotente.
# Requiere: source scripts/env.sh && source scripts/lib.sh
set -euo pipefail

# 1) SSH solo con llaves (ambas VMs)
for ip in "$IP_WEB" "$IP_SIEM"; do
  PUSH configs/ssh/99-hardening.conf "$ip" /tmp/ssh.conf
  R "$ip" 'sudo mv /tmp/ssh.conf /etc/ssh/sshd_config.d/99-hardening.conf && sudo sshd -t && sudo systemctl reload ssh'
done
# Evidencia: debe FALLAR sin llave
R "$IP_WEB" 'ssh -o PubkeyAuthentication=no -o PasswordAuthentication=yes -o BatchMode=yes localhost true' 2>&1 \
  | tee evidencias/ssh_sin_llave.txt || true

# 2) UFW en tiendacr-web
R "$IP_WEB" 'sudo ufw --force reset && sudo ufw default deny incoming && sudo ufw default allow outgoing
sudo ufw allow from '"$IP_HOST"'  to any port 22 proto tcp comment "SSH admin"
sudo ufw allow from '"$IP_KALI"'  to any port 22 proto tcp comment "SSH pruebas"
sudo ufw allow from '"$IP_HOST"'  to any port 80 proto tcp comment "App laptop"
sudo ufw allow from '"$IP_KALI"'  to any port 80 proto tcp comment "App kali"
sudo ufw logging medium && sudo ufw --force enable'
R "$IP_WEB" 'sudo ufw status verbose numbered' | tee evidencias/ufw_web.txt

# 3) UFW en tiendacr-siem
R "$IP_SIEM" 'sudo ufw --force reset && sudo ufw default deny incoming && sudo ufw default allow outgoing
sudo ufw allow from '"$IP_HOST"' to any port 22  proto tcp comment "SSH admin"
sudo ufw allow from '"$IP_HOST"' to any port 443 proto tcp comment "Panel Wazuh"
sudo ufw allow from '"$IP_WEB"'  to any port 1514 proto tcp comment "Eventos agente"
sudo ufw allow from '"$IP_WEB"'  to any port 1515 proto tcp comment "Registro agente"
sudo ufw --force enable'
R "$IP_SIEM" 'sudo ufw status verbose numbered' | tee evidencias/ufw_siem.txt
echo "Hardening aplicado. Revisa que NINGUNA regla sea Anywhere/0.0.0.0/0."
