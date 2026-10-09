---
title: "Prueba: reconstrucción completa (intento 5)"
fecha: 2026-10-09
resultado: Superada
tags: [prueba, reproducibilidad, warpgate, sops, totp, argocd]
---

# Prueba de reconstrucción completa — intento 5

↑ [Mapa del repositorio](../README.md) · [puesta-en-marcha](../runbooks/puesta-en-marcha.md) · Anterior: [2026-10-07-reconstruccion-4](2026-10-07-reconstruccion-4.md)

**Fecha:** 2026-10-09 · **Resultado:** ✅ Superada

## Objetivo

Verificar que la plataforma completa, con el bastión Warpgate y los secretos gestionados con SOPS,
se reconstruye desde el código **sin ningún paso manual**.

## Novedades respecto al intento 4

- Segunda VM, `core-01`, con el bastión Warpgate configurado por su API (roles, destinos, huellas y usuarios).
- Secretos cifrados con SOPS + age: contraseña de admin de Warpgate, contraseña de admin de Argo CD
  y secreto TOTP del usuario.
- Contraseña de Argo CD aplicada por `bootstrap.sh` (antes, paso manual).
- Acceso SSH por Warpgate con doble factor (clave pública + TOTP).

## Punto de partida

- Rama `main` en el commit `6be7b7e` (PR #43), sin cambios locales.
- Plataforma anterior funcionando: dos VMs y 5 aplicaciones en `Synced` / `Healthy`.

## Procedimiento

1. `time make rebuild 2>&1 | tee /tmp/rebuild-5.log`: destrucción y creación con Terraform,
   inventario, `ping`, `site.yml` (base, k3s y core) y bootstrap.
2. Espera a que Argo CD despliegue el resto de aplicaciones desde Git.
3. Login de Argo CD por API con la contraseña de SOPS.
4. Acceso por Warpgate a `k3s-01` con clave + TOTP, sin volver a registrar el TOTP en la app.
5. Idempotencia con `make check`.

## Resultados

| Comprobación | Resultado |
|---|---|
| Destrucción y creación de los 4 recursos (2 VMs, imagen y snippet) | ✅ `4 destroyed` / `4 added` |
| `site.yml` sobre las VMs nuevas | ✅ `failed=0` (`core-01`: 24 cambios; `k3s-01`: 12) |
| Contraseña de Argo CD aplicada en instalación limpia y secreto inicial eliminado | ✅ |
| Aplicaciones `root`, `argocd`, `platform`, `traefik` y `demo-app` | ✅ `Synced` / `Healthy` |
| Login de Argo CD con la contraseña de SOPS | ✅ `200` |
| Acceso `ngtn:k3s-01` por Warpgate con clave + TOTP | ✅ sin volver a escanear el QR |
| Huella de `k3s-01` registrada por Ansible | ✅ sin pregunta de Warpgate |
| Idempotencia de Terraform | ✅ `No changes` |
| Idempotencia de Ansible | ✅ `changed=0` (`core-01`: `ok=36`; `k3s-01`: `ok=22`) |

**Tiempo de `make rebuild`:** 6 min 33 s (13:04:46 → 13:11:19), medido con las fechas de
creación y última modificación del log. Incluye las dos confirmaciones de Terraform.

## Incidencias

- Ninguna en la reconstrucción.
- Al recrear `core-01`, Warpgate tiene una clave de host nueva: hubo que borrar su huella antigua
  del puerto 2222 en el equipo de administración (`ssh-keygen -R '[192.168.1.110]:2222'`).
  Mejora pendiente: claves de host fijas cifradas con SOPS.

## Evolución de las pruebas

| | Intento 1 | Intento 2 | Intento 3 | Intento 4 | Intento 5 |
|---|---|---|---|---|---|
| Alcance | VM + base + hardening | VM + base + hardening | + firewall + k3s + kubectl | + Argo CD + Traefik + Ingress | + Warpgate + SOPS + TOTP |
| VMs | 1 | 1 | 1 | 1 | 2 |
| Comandos | varios | varios | varios | `make rebuild` | `make rebuild` |
| Fallos | 3 | 0 | 0 | 0 | 0 |
| Pasos manuales | varios | varios | varios | contraseña de Argo CD | ninguno |
| Tiempo | 26 min 37 s | 9 min 26 s | 8 min 35 s | 5 min 25 s* | 6 min 33 s* |

\* Solo `make rebuild`; los intentos anteriores incluyen las verificaciones manuales.

## Conclusión

La plataforma completa (dos VMs, sistema endurecido, clúster k3s, Argo CD, Traefik, aplicaciones
publicadas y bastión Warpgate con doble factor) se reconstruye desde el repositorio con un solo
comando en menos de 7 minutos, sin pasos manuales, y converge sin cambios pendientes. Los secretos
solo necesitan la clave `age` del administrador.

## Requisitos que permanecen

- `ssh-add` al iniciar la sesión y clave `age` en el equipo de administración.
- Borrar la huella antigua de Warpgate en el equipo de administración tras recrear `core-01`.
