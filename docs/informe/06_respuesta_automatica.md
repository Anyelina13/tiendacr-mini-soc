# Respuesta automática (Fase 2.5)

La respuesta automática se configura en el **manager** Wazuh
([`configs/wazuh/active-response.xml`](../../configs/wazuh/active-response.xml)): ante la regla
`100101` (fuerza bruta a la app) o `5763` (fuerza bruta SSH), ejecuta el comando **`firewall-drop`**
en el agente afectado, que inserta una regla iptables para **bloquear la IP atacante durante 180 s**.

```
<active-response>
  <command>firewall-drop</command>
  <location>local</location>
  <rules_id>100101,5763</rules_id>
  <timeout>180</timeout>
</active-response>
```

**Lista blanca** (nunca bloquear): el host administrador `192.168.56.1` y el propio SIEM
`192.168.56.30`. Esto evita el **DoS autoinducido** (que el admin o el SIEM se queden fuera).

## Evidencias (al atacar)
- `active-responses.log` del agente (ejecución del comando).
- `sudo iptables -S | grep 192.168.56.10` (regla de bloqueo contra Kali).
- Alerta **651** en el SIEM (confirmación de Active Response).

> Estado: **PENDIENTE** de la corrida en vivo (se genera al ejecutar A2).

## Riesgos de la respuesta automática y mitigaciones

| Riesgo | Descripción | Mitigación aplicada |
|--------|-------------|---------------------|
| Falso positivo | Bloquear a un cliente legítimo por un pico de peticiones | Umbral de frecuencia (8/60 s) + nivel de regla alto |
| IP spoofing → DoS | Un atacante falsifica la IP de un tercero para que el sistema la bloquee | `timeout` corto (180 s) + revisión humana de bloqueos repetidos |
| Quedarse fuera | Bloquear al admin o al SIEM | **Lista blanca** de 192.168.56.1 y 192.168.56.30 |
| Bloqueo permanente | Regla que no caduca | `timeout` en vez de bloqueo definitivo; expira sola |

**Conclusión:** la respuesta automática reduce el tiempo de contención, pero debe combinarse con
listas blancas, timeouts y revisión humana para no convertirse en un vector de denegación de
servicio contra la propia organización.
