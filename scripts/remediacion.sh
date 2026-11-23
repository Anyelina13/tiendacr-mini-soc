#!/usr/bin/env bash
# Fase 2.8 — Remediacion en tiendacr-web. Requiere: source scripts/env.sh && source scripts/lib.sh
set -euo pipefail
# 1) WAF ModSecurity + OWASP CRS en modo bloqueo
R "$IP_WEB" 'sudo apt -y install libapache2-mod-security2 modsecurity-crs && \
  sudo cp /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf && \
  sudo sed -i "s/SecRuleEngine DetectionOnly/SecRuleEngine On/" /etc/modsecurity/modsecurity.conf && \
  sudo systemctl reload apache2'
# 2) Sin ejecucion de PHP en uploads
R "$IP_WEB" 'printf "<Directory /var/www/html/hackable/uploads>\n php_admin_flag engine off\n</Directory>\n" | sudo tee /etc/apache2/conf-available/no-php-uploads.conf && sudo a2enconf no-php-uploads && sudo systemctl reload apache2'
# 3) Parches del SO
R "$IP_WEB" 'sudo apt update && sudo apt -y upgrade'
echo "Remediacion aplicada. Re-ejecuta scripts/ataques/run.sh para la tabla antes/despues."
