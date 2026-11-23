#!/usr/bin/env bash
# Mide segundos entre t0 (inicio del ataque) y la 1a alerta de una regla en el SIEM.
# Uso: scripts/tiempo_alerta.sh "<t0: YYYY-MM-DD HH:MM:SS>" <rule_id>
# Requiere: source scripts/env.sh && source scripts/lib.sh
set -euo pipefail
T0="$1"; RID="$2"
TS=$(R "$IP_SIEM" "sudo jq -r 'select(.rule.id==\"$RID\") | .timestamp' /var/ossec/logs/alerts/alerts.json | head -1")
if [ -z "$TS" ] || [ "$TS" = "null" ]; then
  echo "PENDIENTE: no se encontro alerta de la regla $RID (revisa ingesta/umbral)"; exit 0
fi
t0=$(date -d "$T0" +%s); t1=$(date -d "$TS" +%s)
echo "Regla $RID — t0=$T0  alerta=$TS  -> $((t1 - t0)) s"
