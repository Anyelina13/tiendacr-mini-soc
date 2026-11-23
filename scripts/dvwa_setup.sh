#!/usr/bin/env bash
# Inicializa DVWA sin navegador: crea BD y baja seguridad a low por HTTP (curl).
# Requiere: source scripts/env.sh
set -euo pipefail
J=/tmp/dvwa.cookies
TOKEN=$(curl -s -c $J "http://$IP_WEB/setup.php" | grep -oP "user_token' value='\K[0-9a-f]+")
curl -s -b $J -c $J -d "create_db=Create / Reset Database&user_token=$TOKEN" "http://$IP_WEB/setup.php" -o /dev/null
TOKEN=$(curl -s -b $J -c $J "http://$IP_WEB/login.php" | grep -oP "user_token' value='\K[0-9a-f]+")
curl -s -b $J -c $J -d "username=admin&password=password&Login=Login&user_token=$TOKEN" "http://$IP_WEB/login.php" -o /dev/null
TOKEN=$(curl -s -b $J -c $J "http://$IP_WEB/security.php" | grep -oP "user_token' value='\K[0-9a-f]+")
curl -s -b $J -c $J -d "security=low&seclev_submit=Submit&user_token=$TOKEN" "http://$IP_WEB/security.php" -o /dev/null
echo "DVWA inicializado; cookie en $J (usar PHPSESSID para los ataques)"
