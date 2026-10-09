---
title: "Runbook: Restauración"
tags: [runbook, backup, recuperacion]
---

# Runbook: Restauración ante desastres

↑ [Mapa del repositorio](../README.md) · [arquitectura](../arquitectura.md)

Recuperación de la plataforma tras perder nodos, el clúster o el entorno completo.

> [!WARNING]
> **Estado (2026-10-09):** la reconstrucción desde Git está probada (escenarios A y B). Las copias de
> datos con Velero y el backend remoto de Terraform están **previstos, no implementados**: hoy el
> estado de Terraform es local en el equipo de administración.

**Decisiones de referencia:** [0003-gitops-argocd](../adr/0003-gitops-argocd.md), [0004-gestion-secretos-sops](../adr/0004-gestion-secretos-sops.md), [0002-terraform-ansible-separacion](../adr/0002-terraform-ansible-separacion.md)

## Qué se respalda y dónde

| Elemento | Mecanismo | Referencia |
|---|---|---|
| Código e infraestructura declarada | Repositorio Git | Este repositorio |
| Estado de Terraform | Local en el equipo de administración; backend remoto *(previsto)* | [onprem/backend.tf](../../terraform/envs/onprem/backend.tf), [cloud/backend.tf](../../terraform/envs/cloud/backend.tf) |
| Clave de descifrado SOPS | Custodia fuera de la plataforma | [0004-gestion-secretos-sops](../adr/0004-gestion-secretos-sops.md) |
| Recursos y volúmenes de Kubernetes | Velero *(previsto)* | `gitops/platform/velero/` |

> [!CAUTION]
> **Punto único de fallo.**
> Sin la clave privada de SOPS no se puede restaurar ningún secreto. Debe guardarse en al menos una ubicación externa a la plataforma.

## Escenario A: pérdida de una VM ✅ probado

Ejemplo verificado el 2026-10-08 con `core-01` (Warpgate), reconstruida y operativa en 47 s:

1. Recrear solo esa VM:
`````bash
   ( source .env && terraform -chdir=terraform/envs/onprem apply -replace='module.vms["<vm>"].proxmox_virtual_environment_vm.this' )
`````
2. Reconfigurarla: `make inventory ping configure`.
3. Si es `core-01`, borrar la huella antigua del bastión: `ssh-keygen -R '[192.168.1.110]:2222'`.

## Escenario B: pérdida total de la plataforma ✅ probado

Verificado en la [reconstrucción 4](../pruebas/2026-10-07-reconstruccion-4.md) (5 min 25 s):

1. Recuperar la clave `age` en el equipo de administración (desde el gestor de contraseñas).
2. `make rebuild` (o `make deploy` si no queda nada): VMs, configuración y Argo CD, que vuelve a
   desplegar la plataforma desde Git, con su contraseña de admin ya aplicada desde SOPS.
3. *(Previsto, con Velero)* Restaurar los datos con estado:
   ```bash
   velero backup get
   velero restore create --from-backup <backup>
   ```

## Verificación

- [ ] Todas las aplicaciones de Argo CD en `Synced` / `Healthy`.
- [ ] `make check`: Terraform sin cambios y Ansible con `changed=0`.
- [ ] *(Previsto)* Los datos de las aplicaciones coinciden con el último backup.
- [ ] RTO/RPO obtenidos registrados en `docs/pruebas/`.

## Relacionado

- [puesta-en-marcha](puesta-en-marcha.md) · [añadir-nodo](añadir-nodo.md) · [acceso-warpgate](acceso-warpgate.md)
- Diario: [2026-10-01](../diario/2026-10-01.md) · [2026-10-07](../diario/2026-10-07.md) · [2026-10-08](../diario/2026-10-08.md)
