#!/usr/bin/env bash
# Se ejecuta DENTRO de la VM atacante (Ubuntu, sustituto de Kali). Instala las herramientas.
set -euo pipefail
sudo apt-get update
sudo apt-get -y install nmap hydra sqlmap curl
echo "[ATK] Herramientas de ataque instaladas (nmap, hydra, sqlmap, curl)."
