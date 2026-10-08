---
title: "Prueba: reconstrucción completa (intento 2)"
fecha: 2026-10-04
resultado: Superada
tags: [prueba, reproducibilidad]
---

# Prueba de reconstrucción completa — intento 2

↑ [Mapa del repositorio](../README.md) · [puesta-en-marcha](../runbooks/puesta-en-marcha.md) · Anterior: [2026-10-03-reconstruccion-1](2026-10-03-reconstruccion-1.md)

**Fecha:** 2026-10-04 · **Resultado:** ✅ Superada

## Objetivo

Repetir la reconstrucción completa tras corregir los fallos del [intento 1](2026-10-03-reconstruccion-1.md)
y verificar que la infraestructura on-prem se recrea desde el código sin intervención manual.

## Cambios desde el intento 1

- Rol `TerraformStorage` en Proxmox (`Datastore.*` solo en `/storage/local`).
- Agente QEMU instalado en el primer arranque mediante cloud-init (*vendor-data*):
  snippet `local:snippets/vendor-data-base.yaml` creado por Terraform.
- Almacenamiento `local` con tipo de contenido `snippets`; provider con acceso SSH al nodo.
- Rol `common`: arranque explícito del agente QEMU.

## Punto de partida

- Rama `main` en el commit `fe6379d`, sin cambios locales.

## Procedimiento

1. `terraform destroy` (imagen y VM).
2. `terraform apply` (imagen, snippet y VM).
3. `qm agent 100 ping` antes de ejecutar Ansible.
4. `scripts/tf-to-inventory.sh`, `ssh-keygen -R 192.168.1.101` y `ansible all -m ping`.
5. `ansible-playbook playbooks/base.yml`.
6. Verificaciones funcionales.
7. Idempotencia: `terraform plan` y segunda ejecución del playbook.

## Resultados

| Comprobación | Resultado |
|---|---|
| Destrucción de VM e imagen | ✅ Sin errores de permisos |
| Creación de imagen, snippet y VM | ✅ VM creada en 52 s |
| Agente QEMU activo antes de Ansible | ✅ `AGENTE_OK` |
| Inventario regenerado y conectividad de Ansible | ✅ |
| Configuración con Ansible (`base.yml`) | ✅ `changed=4`; tarea del agente en `ok` |
| Zona horaria `Europe/Madrid` y agente `active` | ✅ |
| Hardening: `root` rechazado | ✅ `Permission denied (publickey)` |
| Idempotencia de Terraform | ✅ `No changes` |
| Idempotencia de Ansible | ✅ `changed=0` |

**Tiempo total:** 9 min 26 s (11:03:00 → 11:12:26), incluyendo las verificaciones manuales.

## Comparativa con el intento 1

| | Intento 1 | Intento 2 |
|---|---|---|
| Creación de la VM | ~15 min (espera al agente) | 52 s |
| Tiempo total | 26 min 37 s | 9 min 26 s |
| Fallos | 3 | 0 |

## Conclusión

La infraestructura on-prem es reproducible: se destruye y se recrea íntegramente desde el
repositorio, y Terraform y Ansible convergen al mismo estado sin cambios pendientes.

## Pasos manuales que permanecen

- `ssh-keygen -R <IP>` tras recrear una VM con la misma IP.
- `source .env` y `ssh-add` al iniciar la sesión.
