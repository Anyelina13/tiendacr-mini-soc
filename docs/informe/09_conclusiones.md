# Conclusiones

1. **La defensa en profundidad funciona por capas complementarias.** Ningún control único basta:
   UFW acota la exposición, SSH solo-llaves cierra el acceso remoto, Suricata ve la red,
   Wazuh correlaciona host y red, y la respuesta automática contiene. Cada ataque fue frenado o
   detectado por una capa distinta.
2. **Detección ≠ prevención.** Suricata sigue alertando después de remediar porque detecta en la
   red, mientras ModSecurity previene en la aplicación. Un SOC necesita ambas: visibilidad para
   investigar y bloqueo para contener.
3. **El menor privilegio se paga en configuración, no en dinero.** Reglas UFW acotadas por IP y un
   SIEM separado del objetivo evitan que un host comprometido escale al resto del laboratorio, sin
   comprar herramientas de pago.
4. **La automatización tiene filo doble.** La respuesta automática reduce el tiempo de contención,
   pero sin listas blancas, timeouts y revisión humana puede convertirse en un vector de
   denegación de servicio (IP spoofing, falsos positivos).
5. **Medir, no suponer.** El análisis de riesgos (NIST 800-30) y los CVSS guían qué remediar
   primero; la reevaluación antes/después demuestra con datos que los controles bajan el riesgo
   residual.

## Mejoras con más presupuesto
Integrar **CrowdSec** (bloqueo colaborativo por reputación de IP), **Falco** (seguridad de runtime
de contenedores), alertas por correo/Slack desde Wazuh, y en un entorno de nube real, **AWS
GuardDuty** para la capa que el proveedor sí puede observar.

## Declaración de uso de IA
Este proyecto se desarrolló con asistencia de **Claude Code (Anthropic)** como operador de terminal
para generar scripts, configuraciones y redacción técnica, bajo supervisión y revisión de los
integrantes. Todo el contenido fue verificado y adaptado por el equipo; los datos medidos del
laboratorio provienen de la ejecución real y se marcan `PENDIENTE` hasta obtenerse (no se inventan).
Las referencias se consultaron en su documentación oficial vigente (nov. 2026).
