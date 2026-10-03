---
title: "Runbook: Puesta en marcha"
tags: [runbook, despliegue]
---

# Runbook: Puesta en marcha de la plataforma

↑ [[docs/README|Mapa del repositorio]] · [[arquitectura]]

Despliegue completo desde cero, en cuatro fases: provisión → inventario → configuración → GitOps.

> [!todo] Estado
> Fase 1 implementada para on-prem. Las fases 2–4 y el entorno cloud están pendientes; los comandos
> se ajustarán (y se centralizarán en el [Makefile](../../Makefile)) a medida que se implementen.

**Decisiones de referencia:** [[0002-terraform-ansible-separacion]], [[0001-eleccion-k3s]], [[0003-gitops-argocd]], [[0004-gestion-secretos-sops]]

## Prerrequisitos

- Configuración inicial completada: [[configuracion-inicial]] (herramientas, requisitos de Proxmox, red, token de API y `.env`).
- `secrets.auto.tfvars` creado en el entorno cloud a partir de su `.example` (cuando se implemente).
- Colecciones de Ansible instaladas: `ansible-galaxy install -r ansible/requirements.yml` ([requirements.yml](../../ansible/requirements.yml)).

## Fase 1: Provisión (Terraform)

> On-prem implementado. Entorno cloud pendiente.

1. Cargar las credenciales de Proxmox:
```bash
   source .env
```
2. Revisar las VMs a crear en [terraform.tfvars](../../terraform/envs/onprem/terraform.tfvars) (mapa `vms`).
3. Inicializar y aplicar el entorno on-prem ([envs/onprem](../../terraform/envs/onprem/main.tf)):
```bash
   terraform -chdir=terraform/envs/onprem init
   terraform -chdir=terraform/envs/onprem plan
   terraform -chdir=terraform/envs/onprem apply
```
   Terraform descarga la imagen oficial de Debian 13 *genericcloud* en `local`
   (módulo [proxmox-image](../../terraform/modules/proxmox-image/main.tf)) y crea una VM por cada
   entrada del mapa `vms` (módulo [proxmox-vm](../../terraform/modules/proxmox-vm/main.tf)),
   inicializada con cloud-init (IP fija, usuario `admin` y clave SSH).
4. Comprobar el acceso a cada VM:
```bash
   ssh admin@<IP_VM>
```
5. Comprobar la idempotencia: un segundo `plan` debe indicar `No changes`.

## Fase 2: Generación del inventario

1. Ejecutar [tf-to-inventory.sh](../../scripts/tf-to-inventory.sh) para generar [onprem/hosts.yml](../../ansible/inventories/onprem/hosts.yml) y [cloud/hosts.yml](../../ansible/inventories/cloud/hosts.yml) a partir de los `outputs.tf`.
2. Comprobar la conectividad:
```bash
   ansible -i ansible/inventories/onprem/hosts.yml all -m ping
```

## Fase 3: Configuración (Ansible)

1. Ejecutar el playbook principal [site.yml](../../ansible/playbooks/site.yml) en cada entorno:
```bash
   ansible-playbook -i ansible/inventories/onprem/hosts.yml ansible/playbooks/site.yml
   ansible-playbook -i ansible/inventories/cloud/hosts.yml  ansible/playbooks/site.yml
```
   Este playbook aplica [base.yml](../../ansible/playbooks/base.yml) → [core.yml](../../ansible/playbooks/core.yml) → [k3s.yml](../../ansible/playbooks/k3s.yml).
2. Recuperar el `kubeconfig` del servidor k3s y verificar: `kubectl get nodes`.

## Fase 4: GitOps (Argo CD)

1. Ejecutar [bootstrap.sh](../../scripts/bootstrap.sh), que instala Argo CD ([bootstrap/argocd](../../gitops/bootstrap/argocd/kustomization.yaml)) y aplica [root-app.yaml](../../gitops/bootstrap/root-app.yaml).
2. Argo CD sincroniza [platform.yaml](../../gitops/appsets/platform.yaml) y [apps.yaml](../../gitops/appsets/apps.yaml).

## Verificación

- [ ] `kubectl get nodes`: todos los nodos en `Ready`.
- [ ] `kubectl -n argocd get applications`: todas en `Synced` / `Healthy`.
- [ ] Grafana muestra las métricas de `node_exporter` de todos los hosts.
- [ ] `demo-app` accesible por Ingress con certificado TLS válido.

## Relacionado

- [[configuracion-inicial]] · [[añadir-nodo]] · [[restauracion]]
- Diario: [[2026-10-01]] · [[2026-10-02]]
