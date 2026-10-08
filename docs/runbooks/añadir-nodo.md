---
title: "Runbook: Añadir nodo"
tags: [runbook, k3s, escalado]
---

# Runbook: Añadir un nodo al clúster k3s

↑ [Mapa del repositorio](../README.md) · [arquitectura](../arquitectura.md)

Amplía el clúster con un nuevo nodo *agent* sin afectar a los existentes.

> [!todo] Estado
> Procedimiento previsto, pendiente de validar cuando estén implementados el módulo [proxmox-vm](../../terraform/modules/proxmox-vm/main.tf) y el rol `k3s`.

**Decisiones de referencia:** [0002-terraform-ansible-separacion](../adr/0002-terraform-ansible-separacion.md), [0001-eleccion-k3s](../adr/0001-eleccion-k3s.md)

## Prerrequisitos

- Clúster operativo (ver [puesta-en-marcha](puesta-en-marcha.md)).
- Capacidad libre en Proxmox (CPU, RAM, almacenamiento) o cuota en el proveedor cloud.

## Pasos

1. **Declarar el nodo** en [terraform/envs/onprem/terraform.tfvars](../../terraform/envs/onprem/terraform.tfvars) (o en [cloud](../../terraform/envs/cloud/terraform.tfvars) si es un nodo remoto) y revisar el plan:
   ```bash
   terraform -chdir=terraform/envs/onprem plan
   terraform -chdir=terraform/envs/onprem apply
   ```
   El plan solo debe mostrar recursos **nuevos**; si propone recrear nodos existentes, abortar.
2. **Regenerar el inventario** con [tf-to-inventory.sh](../../scripts/tf-to-inventory.sh) y comprobar que el nodo aparece en el grupo `k3s` de [hosts.yml](../../ansible/inventories/onprem/hosts.yml).
3. **Configurar solo el nodo nuevo**:
   ```bash
   ansible-playbook -i ansible/inventories/onprem/hosts.yml ansible/playbooks/base.yml --limit <nodo>
   ansible-playbook -i ansible/inventories/onprem/hosts.yml ansible/playbooks/k3s.yml  --limit <nodo>
   ```
   Si es un nodo cloud, debe unirse antes a la malla NetBird (rol `netbird`) para alcanzar el servidor k3s.

## Verificación

- [ ] `kubectl get nodes`: el nodo aparece en `Ready`.
- [ ] El nodo expone métricas de `node_exporter` en Grafana.
- [ ] Un pod de prueba se planifica en el nodo nuevo.

## Relacionado

- [puesta-en-marcha](puesta-en-marcha.md) · [restauracion](restauracion.md)
- Diario: [2026-10-01](../diario/2026-10-01.md)
