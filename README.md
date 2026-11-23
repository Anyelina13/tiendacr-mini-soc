# TiendaCR — Mini SOC automatizado

Proyecto 2 · **ITI-922 Seguridad de TI II** · Entrega: Informe PDF + Repositorio + Demo.

Laboratorio de seguridad defensiva construido **por línea de comandos** sobre VirtualBox: una
tienda ficticia (DVWA) monitorizada por un SOC en miniatura con **Wazuh** (HIDS/SIEM) + **Suricata**
(NIDS), control de acceso por menor privilegio, respuesta automática, cuatro ataques controlados y
una remediación medida antes/después.

## Arquitectura (red host-only `192.168.56.0/24`)

| VM | IP | Rol |
|----|----|-----|
| `kali-atacante` | .10 | Atacante (nmap, hydra, sqlmap) |
| `tiendacr-web` | .20 | Apache proxy + DVWA (Docker) + Suricata + agente Wazuh + UFW |
| `tiendacr-siem` | .30 | Wazuh manager/indexer/dashboard + Active Response |

Diagrama: [`docs/diagramas/arquitectura.mmd`](docs/diagramas/arquitectura.mmd).

## Requisitos de la laptop anfitriona
- VirtualBox + `VBoxManage` en el PATH.
- `ssh sshpass curl jq git ssh-keygen genisoimage`.
- ≥ 16 GB RAM (el SIEM usa 4–6 GB).
- **ISO de Ubuntu 24.04 server** y **OVA de Kali** en `~/isos/` (ver `scripts/env.sh.example`).

## Cómo reproducir TODO (orden de scripts)
```bash
cp scripts/env.sh.example scripts/env.sh   # completa IPs, rutas de ISO/OVA y PW_HASH
source scripts/env.sh && source scripts/lib.sh

# 1. Infraestructura (red, llaves, VMs desatendidas, Kali, snapshots)
bash scripts/crear_vm_ubuntu.sh            # descomenta la orquestación al final

# 2. Control de acceso (SSH solo-llaves + UFW)   -> S1-hardening
bash scripts/hardening.sh

# 3. Monitoreo: Wazuh + agente + Suricata + FIM  -> S2-monitoreo   (ver docs/informe/03_implementacion.md)

# 4. Objetivo: DVWA + Apache                     -> S3-vulnerable-listo
bash scripts/dvwa_setup.sh

# 5. Ataques 1-4 con tiempos y evidencias
bash scripts/ataques/run.sh
bash scripts/tiempo_alerta.sh "<t0>" 100101

# 6. Remediación + reevaluación                  -> S4-remediado
bash scripts/remediacion.sh
```

## Verificación rápida
- `R $IP_WEB 'sudo ss -tlnp'` → 8080 **solo** en 127.0.0.1.
- `R $IP_WEB 'sudo ufw status verbose numbered'` → ninguna regla `Anywhere`.
- `R $IP_SIEM 'sudo /var/ossec/bin/agent_control -l'` → agente activo.

## Estructura
```
docs/{diagramas,informe,riesgos,notas-defensa.md,demo.md}
configs/{ufw,ssh,apache,suricata,wazuh,modsecurity}
scripts/{env.sh.example,lib.sh,crear_vm_ubuntu.sh,hardening.sh,dvwa_setup.sh,
         remediacion.sh,tiempo_alerta.sh,revisar_secretos.sh,ataques/run.sh}
evidencias/   # salidas saneadas por ataque y antes/después (PENDIENTE: corrida en vivo)
```

## Informe
Secciones en [`docs/informe/`](docs/informe/) (00_resumen … 09_conclusiones). **Ya compilado** a
Word y PDF con estilo UTN: [`docs/informe/P1_ChaconMora-MiniSOC.docx`](docs/informe/P1_ChaconMora-MiniSOC.docx)
y `.pdf` (15 págs, portada, 9 tablas, diagrama embebido, Anexo A de riesgos). Para recompilar tras
llenar los datos en vivo, usa el builder de Word COM (ver [`EJECUTAR.md`](EJECUTAR.md) §8).

## Corrida en vivo
Procedimiento de una sola pasada en [`EJECUTAR.md`](EJECUTAR.md): crea las 3 VMs con
`VBoxManage unattended` (sin `mkisofs`), provisiona SIEM/web/atacante, aplica hardening, lanza los
4 ataques y mide tiempos. Orquestador: [`scripts/desplegar_lab.sh`](scripts/desplegar_lab.sh).

## Seguridad y secretos
Nunca se suben llaves, contraseñas ni la clave del panel Wazuh: están en `.gitignore` y se usan
`scripts/env.sh` y `.env` (locales). Antes de cada commit: `bash scripts/revisar_secretos.sh`.

## Uso de IA
Este repositorio se desarrolló con asistencia de **Claude Code (Anthropic)** como operador de
terminal, bajo supervisión y revisión del equipo. Los datos medidos del laboratorio provienen de la
ejecución real; lo no medido se marca `PENDIENTE` (no se inventan datos). Ver la declaración
completa en [`docs/informe/09_conclusiones.md`](docs/informe/09_conclusiones.md).

## Estado
Repositorio, scripts, configuraciones, **informe compilado (Word+PDF)**, diagrama y runbook de
ejecución: **completos**. Ejecución del lab en vivo y evidencias medidas: **PENDIENTE** (requiere
levantar las 3 VMs con ~9 GB de RAM libre; `scripts/desplegar_lab.sh` + `EJECUTAR.md` las generan
en una sola pasada).
