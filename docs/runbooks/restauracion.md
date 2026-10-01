---
title: "Runbook: Restauración"
tags: [runbook, backup, recuperacion]
---

# Runbook: Restauración ante desastres

↑ [[docs/README|Mapa del repositorio]] · [[arquitectura]]

Recuperación de la plataforma tras perder nodos, el clúster o el entorno completo.

> [!todo] Estado
> Procedimiento previsto. Hay que definir y **probar** la ubicación de las copias de Velero y del estado de Terraform; las evidencias se guardarán en `docs/pruebas/`.

**Decisiones de referencia:** [[0003-gitops-argocd]], [[0004-gestion-secretos-sops]], [[0002-terraform-ansible-separacion]]

## Qué se respalda y dónde

| Elemento | Mecanismo | Referencia |
|---|---|---|
| Código e infraestructura declarada | Repositorio Git | Este repositorio |
| Estado de Terraform | Backend remoto | [onprem/backend.tf](../../terraform/envs/onprem/backend.tf), [cloud/backend.tf](../../terraform/envs/cloud/backend.tf) |
| Clave de descifrado SOPS | Custodia fuera de la plataforma | [[0004-gestion-secretos-sops]] |
| Recursos y volúmenes de Kubernetes | Velero | `gitops/platform/velero/` |

> [!warning] Punto único de fallo
> Sin la clave privada de SOPS no se puede restaurar ningún secreto. Debe guardarse en al menos una ubicación externa a la plataforma.

## Escenario A: pérdida de un nodo

1. Eliminar el nodo del clúster: `kubectl delete node <nodo>`.
2. Recrearlo siguiendo [[añadir-nodo]] (Terraform reemplaza la VM y Ansible la reconfigura).

## Escenario B: pérdida total del clúster

1. Recuperar la clave SOPS en la estación de trabajo.
2. Reconstruir la infraestructura con las fases 1–3 de [[puesta-en-marcha]].
3. Ejecutar [bootstrap.sh](../../scripts/bootstrap.sh): Argo CD vuelve a desplegar toda la plataforma desde Git, Velero incluido.
4. Restaurar los datos con estado:
   ```bash
   velero backup get
   velero restore create --from-backup <backup>
   ```

## Verificación

- [ ] Todas las aplicaciones de Argo CD en `Synced` / `Healthy`.
- [ ] Los datos de las aplicaciones coinciden con el último backup.
- [ ] RTO/RPO obtenidos registrados en `docs/pruebas/`.

## Relacionado

- [[puesta-en-marcha]] · [[añadir-nodo]]
- Diario: [[2026-10-01]]
