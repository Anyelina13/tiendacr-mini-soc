#!/usr/bin/env bash
# Helpers de ejecucion remota. Uso: source scripts/env.sh && source scripts/lib.sh
R(){ local ip="$1"; shift; ssh -i "$SSH_KEY" ${ADMIN_USER}@"$ip" "$@"; }   # correr en Ubuntu
RK(){ ssh -i "$SSH_KEY" kali@"$IP_KALI" "$@"; }                            # correr en Kali
PUSH(){ scp -i "$SSH_KEY" "$1" ${ADMIN_USER}@"$2":"$3"; }                  # subir archivo
STAMP(){ date '+%F %T.%3N'; }                                              # marca de tiempo
