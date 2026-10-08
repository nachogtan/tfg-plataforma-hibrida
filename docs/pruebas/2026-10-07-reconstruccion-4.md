---
title: "Prueba: reconstrucción completa (intento 4)"
fecha: 2026-10-07
resultado: Superada
tags: [prueba, reproducibilidad, k3s, gitops, argocd, traefik]
---

# Prueba de reconstrucción completa — intento 4

↑ [Mapa del repositorio](../README.md) · [puesta-en-marcha](../runbooks/puesta-en-marcha.md) · Anterior: [2026-10-05-reconstruccion-3](2026-10-05-reconstruccion-3.md)

**Fecha:** 2026-10-07 · **Resultado:** ✅ Superada

## Objetivo

Verificar que la plataforma on-prem completa se reconstruye desde el código con un solo comando:
desde la VM hasta las aplicaciones desplegadas por Argo CD y publicadas por Traefik.

## Novedades respecto al intento 3

- Todo el proceso con un único comando: `make rebuild`.
- Bootstrap de Argo CD v3.5.3 (`scripts/bootstrap.sh`) y patrón App of Apps.
- Traefik desplegado por Argo CD (aplicación `platform`) y puertos 80/443 en el firewall.
- `demo-app` publicada por Ingress e interfaz de Argo CD por HTTPS (TLS terminado en Traefik).
- Limpieza automática de huellas SSH y carga automática de `.env` desde el Makefile.

## Punto de partida

- Rama `main` en el commit `d01768a`, sin cambios locales.
- Clúster anterior funcionando, con las 5 aplicaciones en `Synced` / `Healthy`.

## Procedimiento

1. `make rebuild`: destrucción y creación con Terraform, inventario, `ping`, `site.yml` y bootstrap.
2. Espera a que Argo CD despliegue el resto de aplicaciones desde Git.
3. Verificaciones de aplicaciones, Traefik e Ingress.
4. Cambio de la contraseña inicial de `admin` de Argo CD (paso manual).
5. Idempotencia con `make check`.

## Resultados

| Comprobación | Resultado |
|---|---|
| Destrucción y creación de los 3 recursos | ✅ `3 destroyed` / `3 added` |
| `site.yml` sobre la VM nueva | ✅ `failed=0` |
| Bootstrap de Argo CD (instalación limpia) y aplicación raíz | ✅ |
| Aplicaciones `root`, `argocd`, `platform`, `traefik` y `demo-app` | ✅ `Synced` / `Healthy` |
| Servicio de Traefik con IP externa | ✅ `192.168.1.101:80/443` |
| `demo-app` por Ingress (`http://demo.192.168.1.101.sslip.io`) | ✅ responde un pod |
| Argo CD por HTTPS (`https://argocd.192.168.1.101.sslip.io`) | ✅ `HTTP/2 200`, sin reiniciar `argocd-server` |
| Contraseña de `admin` cambiada y secreto inicial eliminado | ✅ |
| Idempotencia de Terraform | ✅ `No changes` |
| Idempotencia de Ansible | ✅ `ok=19`, `changed=0` |

**Tiempo de `make rebuild`:** 5 min 25 s (10:07:49 → 10:13:14), medido con las fechas de
creación y última modificación del log. Argo CD tardó unos minutos más en desplegar Traefik
y `demo-app` desde Git.

## Incidencias

- **Bloqueo del usuario `admin` de Argo CD.** El navegador autorrellenó la contraseña de la
  instalación anterior y, tras 5 intentos fallidos, Argo CD bloqueó temporalmente el usuario
  (`too many failed logins` en los logs de `argocd-server`), rechazando incluso la contraseña
  correcta. Se resolvió esperando 5 minutos sin intentos y comprobando primero la contraseña
  contra la API con `curl`.
- **El secreto `argocd-initial-admin-secret` no desapareció al instante** tras el cambio de
  contraseña; unos minutos después ya no existía. El runbook indica comprobarlo y borrarlo si sigue.
- `argocd-secret` tiene ahora 3 campos en lugar de 5: con `server.insecure` desde la instalación,
  Argo CD no genera su propio certificado (`tls.crt`, `tls.key`).

## Evolución de las pruebas

| | Intento 1 | Intento 2 | Intento 3 | Intento 4 |
|---|---|---|---|---|
| Alcance | VM + base + hardening | VM + base + hardening | + firewall + k3s + kubectl | + Argo CD + Traefik + Ingress |
| Comandos | varios | varios | varios | `make rebuild` |
| Fallos | 3 | 0 | 0 | 0 |
| Tiempo | 26 min 37 s | 9 min 26 s | 8 min 35 s | 5 min 25 s* |

\* Solo `make rebuild`; los intentos anteriores incluyen las verificaciones manuales.

## Conclusión

La plataforma on-prem completa (VM, sistema endurecido, clúster k3s, Argo CD, Traefik y
aplicaciones publicadas) se reconstruye desde el repositorio con un solo comando en menos de
6 minutos, y converge sin cambios pendientes.

## Pasos manuales que permanecen

- `ssh-add` al iniciar la sesión.
- Cambiar la contraseña inicial de `admin` de Argo CD tras cada instalación nueva
  (pendiente: contraseña declarativa con SOPS).
