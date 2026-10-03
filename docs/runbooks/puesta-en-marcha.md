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
6. Si se ha recreado una VM con la misma IP, eliminar su huella SSH anterior:
```bash
   ssh-keygen -R <IP_VM>
```

> [!warning] Problema conocido
> Con el agente QEMU activado, `apply` espera hasta 15 minutos a que el agente responda en VMs nuevas,
> y termina con un aviso (`timeout while waiting for the QEMU agent`). La VM se crea correctamente.
> Pendiente de corregir instalando el agente con cloud-init.

## Fase 2: Generación del inventario

1. Ejecutar [tf-to-inventory.sh](../../scripts/tf-to-inventory.sh) para generar [onprem/hosts.yml](../../ansible/inventories/onprem/hosts.yml) y [cloud/hosts.yml](../../ansible/inventories/cloud/hosts.yml) a partir de los `outputs.tf`.
2. Comprobar la conectividad:
```bash
   ansible -i ansible/inventories/onprem/hosts.yml all -m ping
```

## Fase 3: Configuración (Ansible)

> Implementado: playbook `base.yml` (roles `common` y `hardening`).
> Pendiente: `core.yml`, `k3s.yml` y `site.yml`.

1. Ensayar los cambios sin aplicarlos (desde `ansible/`):
```bash
   ansible-playbook playbooks/base.yml --check --diff
```
2. Si el cambio afecta a SSH, abrir antes una sesión en la VM como red de seguridad:
```bash
   ssh admin@<IP_VM>
```
3. Aplicar la configuración base:
```bash
   ansible-playbook playbooks/base.yml
```
   Una segunda ejecución debe terminar con `changed=0` (idempotencia).
4. Verificar el hardening de SSH:
```bash
   ssh admin@<IP_VM> "echo SSH_OK"            # debe funcionar
   ssh root@<IP_VM> "echo NO_DEBERIA_ENTRAR"  # debe fallar: Permission denied
```
5. Si es la primera vez, activar el agente QEMU en Terraform (`agent.enabled = true`) y comprobarlo:
```bash
   ssh root@192.168.1.90 "qm agent <VMID> ping"
```

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
