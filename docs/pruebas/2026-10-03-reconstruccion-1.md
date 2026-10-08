---
title: "Prueba: reconstrucción completa (intento 1)"
fecha: 2026-10-03
resultado: Parcial
tags: [prueba, reproducibilidad]
---

# Prueba de reconstrucción completa — intento 1

↑ [Mapa del repositorio](../README.md) · [puesta-en-marcha](../runbooks/puesta-en-marcha.md)

**Fecha:** 2026-10-03 · **Resultado:** Parcial (reconstrucción correcta, 3 fallos detectados y 2 corregidos)

## Objetivo

Demostrar que la infraestructura on-prem puede destruirse y recrearse íntegramente
desde el código del repositorio, sin intervención manual en Proxmox ni en las VMs.

## Punto de partida

- Rama `main` sin cambios locales (`git status` vacío).
- Recursos gestionados: imagen Debian 13 y VM `k3s-01` (`192.168.1.101`).

## Procedimiento

1. `terraform destroy` del entorno `onprem`.
2. `terraform apply` del entorno `onprem`.
3. `scripts/tf-to-inventory.sh` y `ssh-keygen -R 192.168.1.101`.
4. `ansible all -m ping`.
5. `ansible-playbook playbooks/base.yml`.
6. Verificaciones: zona horaria, agente QEMU, acceso SSH de `admin` y bloqueo de `root`.

## Resultados

| Comprobación | Resultado |
|---|---|
| Destrucción de VM e imagen | ✅ (tras corregir permisos) |
| Recreación de imagen y VM | ✅ (con espera de 15 min al agente) |
| Inventario regenerado automáticamente | ✅ |
| Conectividad de Ansible | ✅ |
| Paquetes base y zona horaria `Europe/Madrid` | ✅ |
| Hardening SSH: `admin` con clave, `root` rechazado | ✅ |
| Agente QEMU activo | ❌ → ✅ tras corrección |

**Tiempo total:** 26 min 37 s (12:20:25 → 12:47:02), incluyendo la corrección de permisos
y ~15 min de espera al agente QEMU.

## Fallos detectados

### 1. Permiso insuficiente para borrar la imagen
- **Síntoma:** `Permission check failed (/storage/local, Datastore.Allocate)` en el `destroy`.
- **Causa:** el rol `TerraformProv` permitía descargar archivos en el almacenamiento, pero no borrarlos.
- **Corrección:** rol `TerraformStorage` (`Datastore.*`) asignado solo en `/storage/local`
  (mínimo privilegio). Documentado en [configuracion-inicial](../runbooks/configuracion-inicial.md).
- **Estado:** ✅ Corregido.

### 2. Terraform espera al agente QEMU en VMs nuevas
- **Síntoma:** `Still creating...` durante 15 min y aviso `timeout while waiting for the QEMU agent`.
- **Causa:** `agent.enabled = true`, pero la imagen *genericcloud* no incluye el agente;
  se instalaba después, con Ansible.
- **Corrección prevista:** instalar el agente en el primer arranque mediante cloud-init (*vendor-data*).
- **Estado:** ⏳ Pendiente.

### 3. El agente instalado por Ansible no arrancaba
- **Síntoma:** `systemctl is-active qemu-guest-agent` → `inactive`; `QEMU guest agent is not running`.
- **Causa:** en Debian el servicio se inicia al detectar el dispositivo durante el arranque.
  Al instalarlo con la VM ya arrancada, nadie lo iniciaba.
- **Corrección:** tarea `Arrancar el agente QEMU` en el rol `common`.
- **Estado:** ✅ Corregido y verificado (`AGENTE_OK`).

## Observación

Al recrear una VM con la misma IP cambia su huella SSH. Hay que eliminar la anterior con
`ssh-keygen -R <IP>`; si no, SSH bloquea la conexión por posible suplantación.

## Siguiente paso

Corregir el fallo 2 y repetir la prueba (intento 2), cronometrada y sin intervención manual.
