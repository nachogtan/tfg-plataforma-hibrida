---
title: "Prueba: reconstrucción completa (intento 3)"
fecha: 2026-10-05
resultado: Superada
tags: [prueba, reproducibilidad, k3s, seguridad]
---

# Prueba de reconstrucción completa — intento 3

↑ [[docs/README|Mapa del repositorio]] · [[puesta-en-marcha]] · Anterior: [[2026-10-04-reconstruccion-2]]

**Fecha:** 2026-10-05 · **Resultado:** ✅ Superada

## Objetivo

Verificar que la plataforma on-prem completa (VM, configuración base, hardening, firewall,
clúster k3s y acceso con `kubectl`) se reconstruye desde el código sin intervención manual.

## Novedades respecto al intento 2

- Rol `k3s` (k3s `v1.36.5+k3s1`, sin Traefik) y playbook principal `site.yml`.
- Firewall UFW: política de entrada denegada, SSH en `hardening` y reglas de k3s en su rol.
- `kubeconfig` copiado al equipo de administración (`~/.kube/tfg-onprem.yaml`, permisos `0600`).

## Punto de partida

- Rama `main` en el commit `1680ec3`, sin cambios locales.

## Procedimiento

1. `terraform destroy` (imagen, snippet y VM).
2. `terraform apply`.
3. `scripts/tf-to-inventory.sh`, `ssh-keygen -R 192.168.1.101` y `ansible all -m ping`.
4. `ansible-playbook playbooks/site.yml`.
5. Verificaciones funcionales y de seguridad.
6. Idempotencia de Terraform y Ansible.

## Resultados

| Comprobación | Resultado |
|---|---|
| Destrucción y creación de los 3 recursos | ✅ |
| `site.yml` sobre la VM nueva | ✅ `changed=11`, `failed=0` |
| Nodo `k3s-01` en `Ready` | ✅ |
| Pods del sistema en `Running` con el firewall activo desde el inicio | ✅ |
| `kubectl` desde el equipo de administración (kubeconfig regenerado) | ✅ |
| Firewall activo: 22/tcp, 6443/tcp, redes de pods y servicios | ✅ |
| Puerto no permitido (10250/tcp) bloqueado | ✅ `TIMEOUT` |
| Acceso de `root` por SSH rechazado | ✅ |
| Agente QEMU | ✅ `AGENTE_OK` |
| Idempotencia de Terraform | ✅ `No changes` |
| Idempotencia de Ansible | ✅ `changed=0` |

**Tiempo total:** 8 min 35 s (12:13:25 → 12:22:00), incluyendo verificaciones manuales.

## Evolución de las pruebas

| | Intento 1 | Intento 2 | Intento 3 |
|---|---|---|---|
| Alcance | VM + base + hardening | VM + base + hardening | + firewall + k3s + kubectl |
| Fallos | 3 | 0 | 0 |
| Tiempo total | 26 min 37 s | 9 min 26 s | 8 min 35 s |

## Conclusión

La plataforma on-prem, incluido el clúster k3s protegido por firewall, es reproducible
desde el repositorio: se destruye y se recrea en menos de 10 minutos y converge sin
cambios pendientes.

## Pasos manuales que permanecen

- `source .env` y `ssh-add` al iniciar la sesión.
- `ssh-keygen -R <IP>` tras recrear una VM con la misma IP.
