# Análisis de riesgos — TiendaCR (NIST SP 800-30 r1 simplificado)

> Metodología: inventario de activos con valoración C/I/D (1–3), identificación de amenazas y
> vulnerabilidades por activo, estimación de **probabilidad × impacto** en escala 1–5 (matriz 5×5)
> y plan de tratamiento. El detalle tabular está en [`matriz_riesgos.csv`](matriz_riesgos.csv).

## 1. Inventario de activos y valoración C/I/D

| Activo | Confidencialidad | Integridad | Disponibilidad | Valor |
|--------|:---:|:---:|:---:|:---:|
| Servidor web (tiendacr-web) | 2 | 3 | 3 | Alto |
| App DVWA | 2 | 3 | 2 | Medio-Alto |
| BD MariaDB del contenedor | 3 | 3 | 2 | Alto |
| SIEM Wazuh (tiendacr-siem) | 3 | 3 | 3 | Crítico |
| Llaves SSH del laboratorio | 3 | 3 | 1 | Alto |
| Credencial del panel Wazuh | 3 | 2 | 1 | Alto |
| Logs de seguridad | 2 | 3 | 2 | Medio-Alto |
| Red del laboratorio (192.168.56.0/24) | 2 | 3 | 3 | Alto |
| Laptop administradora | 3 | 3 | 3 | Crítico |

Escala: 1 = bajo, 2 = medio, 3 = alto.

## 2. Matriz de riesgo 5×5 (Probabilidad × Impacto)

|  | I=1 | I=2 | I=3 | I=4 | I=5 |
|---|:--:|:--:|:--:|:--:|:--:|
| **P=5** | 5 | 10 (R06) | 15 | 20 (R02) | 25 (R01) |
| **P=4** | 4 | 8 | 12 (R05) | 16 | 20 (R04) |
| **P=3** | 3 | 6 | 9 (R11) | 12 (R08) | 15 (R03,R07) |
| **P=2** | 2 | 4 | 6 | 8 (R13) | 10 (R09,R10,R12) |
| **P=1** | 1 | 2 | 3 | 4 | 5 |

Umbrales: **1–6** bajo · **7–12** medio · **13–19** alto · **20–25** crítico.

Se identifican **13 riesgos** (≥10 requeridos). Los dos críticos (R01 SQLi, R02 fuerza bruta) son
precisamente los que se atacan y detectan en vivo, y los que la remediación (§8) debe reducir.

## 3. Cálculo CVSS v3.1 de vulnerabilidades reales

Vectores calculados con la calculadora de FIRST (https://www.first.org/cvss/calculator/3.1).

### 3.1 SQL Injection en DVWA (R01 · A03:2021 · CWE-89)
- **Vector:** `CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:N`
- **Puntaje base: 8.1 (Alto).**
- Justificación: explotable por red (AV:N), baja complejidad (AC:L), requiere una sesión
  autenticada de bajo privilegio (PR:L), sin interacción de usuario (UI:N). Permite leer y
  alterar la base de datos → C:H, I:H. Disponibilidad no afectada directamente (A:N).

### 3.2 Fuerza bruta sin bloqueo en el login (R02 · A07:2021 · CWE-307)
- **Vector:** `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:N/A:N`
- **Puntaje base: 7.5 (Alto).**
- Justificación: sin credenciales previas (PR:N); el éxito compromete la confidencialidad de la
  cuenta (C:H). No altera datos por sí mismo (I:N) ni tumba el servicio en una lista corta (A:N).

### 3.3 File upload → webshell (R04 · CWE-434)
- **Vector:** `CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:H`
- **Puntaje base: 8.8 (Alto).**
- Justificación: subir y ejecutar código arbitrario da control del servidor → C:H/I:H/A:H.
  Requiere sesión de bajo privilegio (PR:L).

### 3.4 CVE real del host (Vulnerability Detection de Wazuh)
- **Estado: PENDIENTE.** Se toma del inventario de vulnerabilidades que reporta Wazuh sobre
  `tiendacr-web` (§6.4, `evidencias/vuln_inventory.json`) y se anota su CVE y puntaje de NVD.
  No se inventa: se mide en la corrida en vivo conforme al contrato §0.7.

## 4. Plan de tratamiento y riesgo residual

El tratamiento por riesgo (mitigar/transferir/aceptar/evitar), el control aplicado y el
responsable (A/B) están en `matriz_riesgos.csv`. La columna **Riesgo_residual** queda en
`PENDIENTE` y se completa en §8 tras ejecutar la remediación y repetir los ataques A2/A3:
se re-estima P×I sobre el estado remediado (p. ej. R01 baja de 25 a nivel medio por el WAF, y
R02 baja porque Active Response bloquea al atacante tras 8 intentos).
