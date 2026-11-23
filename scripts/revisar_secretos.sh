#!/usr/bin/env bash
# Revision de secretos antes de cada commit (OBLIGATORIO, §10).
set -uo pipefail
if git diff --cached | grep -inE 'password|passwd|secret|token|BEGIN .*PRIVATE KEY|api[_-]?key|PHPSESSID' ; then
  echo "posible secreto en el staging — revisa antes de commitear"; exit 1
else
  echo "OK — sin secretos evidentes"; fi
