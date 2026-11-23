# Demo (10 min + 5 preguntas)

**Antes de empezar:** restaurar el snapshot del estado vulnerable listo.
```bash
for vm in kali-atacante tiendacr-web tiendacr-siem; do
  VBoxManage snapshot "$vm" restore S3-vulnerable-listo; VBoxManage startvm "$vm" --type headless
done
```

## Guion por minutos (A y B se alternan)

| Min | Quién | Acción | Qué mostrar |
|-----|-------|--------|-------------|
| 0–2 | A | Problema + arquitectura | Diagrama; red host-only; las 3 VMs |
| 2–3 | A | Control de acceso | `sudo ufw status verbose numbered` (deny-by-default); SSH sin llave **falla** |
| 3–5 | B | Ataque 2 en vivo (fuerza bruta) | `hydra`; en el SIEM alerta **100101** + Suricata **1000004** |
| 5–7 | B | Respuesta automática | Hydra queda colgado; `sudo iptables -S | grep 192.168.56.10`; alerta **651** |
| 7–9 | A | Antes/después SQLi | SQLi funciona (antes) → con ModSecurity responde **403** (después) |
| 9–10 | A+B | Riesgo residual + cierre | Tabla antes/después y matriz residual |

## Plan B (si algo falla)
- **Video grabado** de la corrida (usar `scripts/ataques/run.sh` con `asciinema` o grabación de
  pantalla) y las capturas de `evidencias/`.
- **Si Kali queda bloqueada** por el Active Response: esperar el timeout (180 s) o borrar la regla
  manualmente: `sudo iptables -D <cadena> <n>`.
- Tener el SIEM ya abierto en `https://192.168.56.30` para no perder tiempo logueándose.

## Reparto de preguntas
Repasar [`notas-defensa.md`](notas-defensa.md); cada integrante domina al menos: una regla de
Suricata opción por opción, el flujo de Active Response, y el cálculo de un CVSS.
