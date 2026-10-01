---
title: "Runbook: Puesta en marcha"
tags: [runbook, despliegue]
---

# Runbook: Puesta en marcha de la plataforma

↑ [[docs/README|Mapa del repositorio]] · [[arquitectura]]

Despliegue completo desde cero, en cuatro fases: provisión → inventario → configuración → GitOps.

> [!todo] Estado
> Procedimiento previsto. Los ficheros referenciados aún están vacíos; los comandos se ajustarán (y se centralizarán en el [Makefile](../../Makefile)) a medida que se implementen.

**Decisiones de referencia:** [[0002-terraform-ansible-separacion]], [[0001-eleccion-k3s]], [[0003-gitops-argocd]], [[0004-gestion-secretos-sops]]

## Prerrequisitos

- Configuración inicial de Proxmox completada: [[configuracion-inicial]] (usuario, rol y token de API, `.env`).
- Terraform, Ansible, `kubectl`, `sops` y la clave de descifrado disponibles en la estación de trabajo.
- Acceso a la API de Proxmox y credenciales del proveedor cloud.
- `secrets.auto.tfvars` creado en cada entorno a partir de su `.example`.
- Colecciones de Ansible instaladas: `ansible-galaxy install -r ansible/requirements.yml` ([requirements.yml](../../ansible/requirements.yml)).

## Fase 1: Provisión (Terraform)

1. Plantilla base y VMs on-prem ([envs/onprem](../../terraform/envs/onprem/main.tf)):
   ```bash
   terraform -chdir=terraform/envs/onprem init
   terraform -chdir=terraform/envs/onprem apply
   ```
2. VMs cloud ([envs/cloud](../../terraform/envs/cloud/main.tf)):
   ```bash
   terraform -chdir=terraform/envs/cloud init
   terraform -chdir=terraform/envs/cloud apply
   ```

## Fase 2: Generación del inventario

3. Ejecutar [tf-to-inventory.sh](../../scripts/tf-to-inventory.sh) para generar [onprem/hosts.yml](../../ansible/inventories/onprem/hosts.yml) y [cloud/hosts.yml](../../ansible/inventories/cloud/hosts.yml) a partir de los `outputs.tf`.
4. Comprobar la conectividad:
   ```bash
   ansible -i ansible/inventories/onprem/hosts.yml all -m ping
   ```

## Fase 3: Configuración (Ansible)

5. Ejecutar el playbook principal [site.yml](../../ansible/playbooks/site.yml) en cada entorno:
   ```bash
   ansible-playbook -i ansible/inventories/onprem/hosts.yml ansible/playbooks/site.yml
   ansible-playbook -i ansible/inventories/cloud/hosts.yml  ansible/playbooks/site.yml
   ```
   Este playbook aplica [base.yml](../../ansible/playbooks/base.yml) → [core.yml](../../ansible/playbooks/core.yml) → [k3s.yml](../../ansible/playbooks/k3s.yml).
6. Recuperar el `kubeconfig` del servidor k3s y verificar: `kubectl get nodes`.

## Fase 4: GitOps (Argo CD)

7. Ejecutar [bootstrap.sh](../../scripts/bootstrap.sh), que instala Argo CD ([bootstrap/argocd](../../gitops/bootstrap/argocd/kustomization.yaml)) y aplica [root-app.yaml](../../gitops/bootstrap/root-app.yaml).
8. Argo CD sincroniza [platform.yaml](../../gitops/appsets/platform.yaml) y [apps.yaml](../../gitops/appsets/apps.yaml).

## Verificación

- [ ] `kubectl get nodes`: todos los nodos en `Ready`.
- [ ] `kubectl -n argocd get applications`: todas en `Synced` / `Healthy`.
- [ ] Grafana muestra las métricas de `node_exporter` de todos los hosts.
- [ ] `demo-app` accesible por Ingress con certificado TLS válido.

## Relacionado

-  [[configuracion-inicial]] · [[añadir-nodo]] · [[restauracion]]
- [[añadir-nodo]] · [[restauracion]]
- Diario: [[2026-10-01]]
