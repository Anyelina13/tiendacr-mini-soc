# Fase 1 — Investigación

## 1.1 Comparativa de soluciones de detección y protección

Se comparan cinco soluciones representativas: una **nativa de nube** (AWS GuardDuty) y cuatro de
**código abierto** (Wazuh, Suricata, CrowdSec y Falco), cubriendo HIDS, NIDS, IDS de red de nube y
seguridad de runtime.

| Criterio | AWS GuardDuty | Wazuh | Suricata | CrowdSec | Falco |
|----------|---------------|-------|----------|----------|-------|
| Qué detecta y cómo | Amenazas en cuentas/cargas AWS analizando CloudTrail, VPC Flow y DNS con ML e inteligencia de amenazas | HIDS + SIEM: logs, FIM, detección de vulnerabilidades, respuesta activa | NIDS/IPS por firmas e inspección profunda de paquetes sobre el tráfico de red | IDS colaborativo: analiza logs y comparte/consume listas de IPs maliciosas (crowdsourcing) | Seguridad en runtime: detecta comportamiento anómalo de contenedores/kernel vía eventos syscall (eBPF) |
| Despliegue y recursos | Servicio gestionado, se activa en la consola; sin infraestructura propia | Manager + indexer + dashboard; agente ligero por host (all-in-one ~4–6 GB) | Un binario por host/segmento; ligero, ajustable a CPU | Agente + "bouncers"; muy ligero | DaemonSet/servicio por nodo; ligero |
| Costo y licencia | De pago, por volumen de eventos analizados (modelo por uso) | Gratis, GPLv2 | Gratis, GPLv2 | Gratis, MIT (hub colaborativo gratuito) | Gratis, Apache 2.0 (proyecto CNCF) |
| Respuesta automática | Integra con EventBridge/Lambda/Security Hub | **Active Response** nativa (p. ej. firewall-drop) | Modo IPS (drop) si se despliega inline | "Bouncers" que bloquean en firewall/proxy | Alertas; respuesta vía herramientas externas |
| Integraciones | Ecosistema AWS (Security Hub, Detective) | Suricata (eve.json), VirusTotal, MISP, Slack, correo | Wazuh, ELK, Zeek, cualquier SIEM vía eve.json | Firewall, Nginx, Cloudflare, etc. | Kubernetes, Prometheus, Falcosidekick |
| Limitaciones | Solo nube AWS; no ve tráfico interno ni hosts on-prem; de pago | Curva de reglas/decoders; el indexer consume RAM | Solo red; no correlaciona logs de host por sí solo | Enfocado a abuso por IP; menos profundidad en host | Enfocado a runtime; no es SIEM ni NIDS |

### Justificación de la elección: **Wazuh + Suricata**

Para un laboratorio **local** (sin nube) se eligen **Wazuh + Suricata** porque:

1. **Cobertura completa gratis:** Wazuh aporta HIDS/SIEM (logs, FIM, detección de
   vulnerabilidades, correlación y respuesta activa) y Suricata aporta NIDS (firmas sobre el
   tráfico). Juntos cubren host **y** red, que es justo lo que pide el proyecto.
2. **Integración nativa:** Suricata escribe `eve.json` y el agente de Wazuh lo ingiere
   directamente, permitiendo correlacionar una firma de red con eventos de host en una sola alerta.
3. **Respuesta automática incluida:** el `firewall-drop` de Wazuh bloquea al atacante sin comprar
   nada extra, lo que habilita la Fase 2.5 del proyecto.
4. **Sin costo ni dependencia de proveedor:** licencias GPLv2, se ejecutan en las VMs del lab.

No se elige **AWS GuardDuty** porque es exclusivo de AWS y de pago: no puede inspeccionar tráfico
ni hosts de un laboratorio local en VirtualBox y añadiría costo sin aportar visibilidad on-prem.
CrowdSec y Falco son excelentes complementos (se citan como mejora futura en la defensa), pero no
sustituyen la combinación HIDS+NIDS+SIEM que se necesita aquí.

## 1.2 Modelo de responsabilidad compartida (referencia: AWS EC2 / IaaS)

En IaaS el proveedor asegura la nube y el cliente asegura lo que pone **en** la nube. Cada fila se
relaciona con lo implementado en el laboratorio (donde "el cliente" somos nosotros administrando
las VMs):

| Capa | Responsable en AWS EC2 (IaaS) | Equivalente en el laboratorio |
|------|------------------------------|-------------------------------|
| Hardware / data center | **Proveedor** | Hipervisor VirtualBox + laptop (lo asumimos como "infra") |
| Virtualización / hipervisor | **Proveedor** | VirtualBox (host-only, snapshots) |
| Sistema operativo invitado | **Cliente** | Hardening de Ubuntu, parches `apt upgrade` |
| Configuración de red / firewall | **Cliente** | Security Group → **emulado con UFW** (deny-by-default por IP) |
| Control de acceso / IAM | **Cliente** | SSH solo-llaves, `AllowUsers soc`, usuarios A/B |
| Aplicación y datos | **Cliente** | DVWA/BD, WAF ModSecurity, saneo de entradas |
| Cifrado y gestión de llaves | **Cliente** | Llave `ed25519`, `.gitignore`, rotación |
| Monitoreo y respuesta | **Cliente** (con servicios del proveedor) | Wazuh + Suricata + Active Response |

Conclusión: en IaaS el grueso de la seguridad recae en el cliente; el laboratorio ejercita
precisamente esas capas (SO, red, acceso, app, monitoreo).

## 1.3 Análisis de riesgos

Desarrollado en [`../riesgos/analisis_riesgos.md`](../riesgos/analisis_riesgos.md) y
[`../riesgos/matriz_riesgos.csv`](../riesgos/matriz_riesgos.csv): inventario con valoración C/I/D,
matriz 5×5 con 13 riesgos, CVSS v3.1 de tres vulnerabilidades reales (SQLi 8.1, fuerza bruta 7.5,
file upload→webshell 8.8) más el CVE del host (PENDIENTE de medición), y plan de tratamiento con
riesgo residual.

## Referencias (APA 7)

- Amazon Web Services. (2026). *Shared Responsibility Model*. https://aws.amazon.com/compliance/shared-responsibility-model/ (consultado nov. 2026).
- Amazon Web Services. (2026). *Amazon GuardDuty — Features and pricing*. https://aws.amazon.com/guardduty/ (consultado nov. 2026).
- Dotson, C. (2019). *Practical Cloud Security: A Guide for Secure Design and Deployment*. O'Reilly Media.
- FIRST. (2019). *Common Vulnerability Scoring System v3.1: Specification Document*. https://www.first.org/cvss/v3.1/specification-document
- Guijarro Olivares, J., et al. (2021). *DevOps y seguridad cloud*. Editorial UOC.
- MITRE. (2026). *MITRE ATT&CK Matrix for Enterprise*. https://attack.mitre.org/ (consultado nov. 2026).
- National Institute of Standards and Technology. (2012). *Guide for Conducting Risk Assessments* (NIST SP 800-30 Rev. 1). https://doi.org/10.6028/NIST.SP.800-30r1
- National Institute of Standards and Technology. (2012). *Computer Security Incident Handling Guide* (NIST SP 800-61 Rev. 2). https://doi.org/10.6028/NIST.SP.800-61r2
- OISF. (2026). *Suricata User Guide*. https://docs.suricata.io/ (consultado nov. 2026).
- OWASP. (2021). *OWASP Top 10:2021*. https://owasp.org/Top10/
- Wazuh Inc. (2026). *Wazuh Documentation (v4.x)*. https://documentation.wazuh.com/ (consultado nov. 2026).

> Nota de verificación: los precios/licencias y versiones se consultaron en la documentación
> oficial vigente (nov. 2026). Cualquier dato no verificable por restricción de red queda marcado
> `PENDIENTE: verificar`.
