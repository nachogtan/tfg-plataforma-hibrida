---
title: "Runbook: Restauración"
tags: [runbook, backup, recuperacion]
---

# Runbook: Restauración ante desastres

↑ [Mapa del repositorio](../README.md) · [arquitectura](../arquitectura.md)

Recuperación de la plataforma tras perder una VM, sus datos, el clúster o el nodo Proxmox.
Hay dos estrategias complementarias: **reconstruir desde el código** (recupera la configuración) y
**restaurar desde Proxmox Backup Server** (recupera los datos).

> [!NOTE]
> **Estado (2026-10-13):** probados los escenarios A, B y C. El estado de Terraform sigue siendo
> local en el equipo de administración por decisión (ver escenario E).

**Decisiones de referencia:** [0002-terraform-ansible-separacion](../adr/0002-terraform-ansible-separacion.md),
[0003-gitops-argocd](../adr/0003-gitops-argocd.md), [0004-gestion-secretos-sops](../adr/0004-gestion-secretos-sops.md),
[0009-copias-pbs](../adr/0009-copias-pbs.md)

## Qué se respalda y dónde

| Elemento | Mecanismo | Referencia |
|---|---|---|
| Código e infraestructura declarada | Repositorio Git | Este repositorio |
| VMs on-prem completas (incluidos los datos de Warpgate) | Proxmox Backup Server, copia diaria cifrada | [backups](backups.md) |
| Secretos de la plataforma | Cifrados con SOPS en `secrets/` | [0004-gestion-secretos-sops](../adr/0004-gestion-secretos-sops.md) |
| Clave privada de age (SOPS) y clave de cifrado de PBS | Gestor de contraseñas (fuera de la plataforma) | — |
| Estado de Terraform | Local en el equipo de administración, sin copia por decisión (escenario E) | [onprem/backend.tf](../../terraform/envs/onprem/backend.tf), [cloud/backend.tf](../../terraform/envs/cloud/backend.tf) |
| Panel y alerta de Grafana Cloud | Configuración manual documentada | [monitorizacion](monitorizacion.md) |

> [!CAUTION]
> **Puntos únicos de fallo.**
> Sin la clave privada de age no se puede descifrar ningún secreto, y sin la clave de cifrado de PBS
> no se puede restaurar ninguna copia. Las dos deben guardarse fuera de la plataforma.

## Escenario A: pérdida de una VM (reconstruir) ✅ probado

Ejemplo verificado el 2026-10-08 con `core-01` (Warpgate), reconstruida y operativa en 47 s:

1. Recrear solo esa VM:

```bash
   ( source .env && terraform -chdir=terraform/envs/onprem apply -replace='module.vms["<vm>"].proxmox_virtual_environment_vm.this' )
```

2. Reconfigurarla: `make inventory ping configure`.
3. Si es `core-01`, borrar la huella antigua del bastión: `ssh-keygen -R '[192.168.1.110]:2222'`.

Recupera la configuración, pero **no los datos** (por ejemplo, las grabaciones de Warpgate). Para
los datos, ver el escenario C.

## Escenario B: pérdida total de la plataforma (reconstruir) ✅ probado

Verificado en la [reconstrucción 4](../pruebas/2026-10-07-reconstruccion-4.md) (5 min 25 s):

1. Recuperar la clave `age` en el equipo de administración (desde el gestor de contraseñas).
2. `make rebuild` (o `make deploy` si no queda nada): VMs, configuración y Argo CD, que vuelve a
   desplegar la plataforma desde Git, con su contraseña de admin ya aplicada desde SOPS.
3. Entorno cloud, si hace falta: `make deploy ENV=cloud` (ver [vm-cloud](vm-cloud.md)).
4. Si se necesitan los datos anteriores, restaurarlos desde PBS (escenario C).

## Escenario C: recuperar una VM con sus datos desde PBS ✅ probado

Verificado el 2026-10-13: `core-01` restaurada como VM nueva en **1 min 19 s**, con los datos de
Warpgate intactos (procedimiento de prueba en [backups](backups.md#6-probar-una-restauración-sin-tocar-la-vm-original)).

Para sustituir la VM original por su copia:

1. Elegir la copia: *pbs-01 → Backups* en Proxmox VE (o el listado del runbook de backups).
2. Apagar la VM afectada y restaurar encima con su mismo ID:

```bash
   ssh root@192.168.1.90 'qm stop <id>; qmrestore pbs-01:backup/vm/<id>/<fecha> <id> --force 1 --storage local-lvm && qm start <id>'
```

3. Comprobar con `make check` que Terraform y Ansible no detectan diferencias.

## Escenario D: pérdida del nodo Proxmox

1. Reinstalar Proxmox VE en el nodo (misma IP, `192.168.1.90`) y preparar el acceso de Terraform
   ([configuracion-inicial](configuracion-inicial.md)).
2. Añadir el almacenamiento `pbs-01` con la **clave de cifrado existente**
   ([backups](backups.md#7-recuperación-ante-desastre-nodo-proxmox-nuevo)).
3. Restaurar las VMs desde PBS con sus IDs originales, o reconstruirlas con `make deploy` y restaurar
   solo los datos que hagan falta.

## Escenario E: pérdida del estado de Terraform

El estado es local por decisión ([0009-copias-pbs](../adr/0009-copias-pbs.md)). Perderlo no supone
perder datos:

- **Cloud:** si el entorno estaba destruido, no hay nada que recuperar. Si estaba creado, borrar en
  la consola de AWS los recursos con la etiqueta `proyecto = tfg-plataforma-hibrida` (o importarlos
  con `terraform import`) y volver a crearlos con `make deploy ENV=cloud`.
- **On-prem:** borrar las VMs en Proxmox (`qm stop <id> && qm destroy <id> --purge`) y ejecutar
  `make deploy` (~6 min). Si hacen falta sus datos, restaurarlos después desde PBS (escenario C).

> [!TIP]
> Antes de borrar las VMs on-prem, lanzar una copia manual en PBS (*Run now*) para no perder los
> datos más recientes.

## Tiempos de recuperación medidos

| Prueba | Fecha | Tiempo |
|---|---|---|
| Reconstrucción de `core-01` (A) | 2026-10-08 | 47 s |
| Reconstrucción completa (B) | 2026-10-07 / 2026-10-09 | 5 min 25 s / 6 min 33 s |
| Restauración de `core-01` desde PBS (C) | 2026-10-13 | 1 min 19 s |

## Verificación

- [ ] Todas las aplicaciones de Argo CD en `Synced` / `Healthy`.
- [ ] `make check`: Terraform sin cambios y Ansible con `changed=0`.
- [ ] Los datos de las VMs restauradas coinciden con la copia (por ejemplo, `/var/lib/warpgate`).
- [ ] Tiempos de recuperación registrados en `docs/pruebas/` o en la tabla de arriba.

## Relacionado

- [puesta-en-marcha](puesta-en-marcha.md) · [añadir-nodo](añadir-nodo.md) · [acceso-warpgate](acceso-warpgate.md) · [backups](backups.md) · [vm-cloud](vm-cloud.md)
- Diario: [2026-10-07](../diario/2026-10-07.md) · [2026-10-08](../diario/2026-10-08.md) · [2026-10-13](../diario/2026-10-13.md)
