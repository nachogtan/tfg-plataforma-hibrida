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

## Atajos con make

Todo el procedimiento está disponible como objetivos del [Makefile](../../Makefile):

```bash
make help      # lista de objetivos
make deploy    # Fases 1–3: Terraform + inventario + Ansible
make check     # idempotencia de Terraform y Ansible
make rebuild   # destruye y vuelve a crear la plataforma
```

Las fases siguientes describen lo que hace cada paso por separado.

## Fase 1: Provisión (Terraform)

> On-prem implementado. Entorno cloud pendiente.

1. Cargar las credenciales de Proxmox y la clave SSH (el provider la usa para subir snippets):
```bash
   source .env
   ssh-add ~/.ssh/id_ed25519
```
2. Revisar las VMs a crear en [terraform.tfvars](../../terraform/envs/onprem/terraform.tfvars) (mapa `vms`).
3. Inicializar y aplicar el entorno on-prem ([envs/onprem](../../terraform/envs/onprem/main.tf)):
```bash
   terraform -chdir=terraform/envs/onprem init
   terraform -chdir=terraform/envs/onprem plan
   terraform -chdir=terraform/envs/onprem apply
```
   Terraform descarga la imagen oficial de Debian 13 *genericcloud* en `local`
   (módulo [proxmox-image](../../terraform/modules/proxmox-image/main.tf)), crea el snippet de
   cloud-init `vendor-data-base.yaml` (instala el agente QEMU en el primer arranque) y crea una VM
   por cada entrada del mapa `vms` (módulo [proxmox-vm](../../terraform/modules/proxmox-vm/main.tf)),
   inicializada con IP fija, usuario `admin` y clave SSH.
4. Si se ha recreado una VM con la misma IP, eliminar su huella SSH anterior:
```bash
   ssh-keygen -R <IP_VM>
```
5. Comprobar el acceso a cada VM y que el agente QEMU responde:
```bash
   ssh admin@<IP_VM> "hostname"
   ssh root@192.168.1.90 "qm agent <VMID> ping && echo AGENTE_OK"
```
6. Comprobar la idempotencia: un segundo `plan` debe indicar `No changes`.

## Fase 2: Generación del inventario

1. Ejecutar [tf-to-inventory.sh](../../scripts/tf-to-inventory.sh) para generar [onprem/hosts.yml](../../ansible/inventories/onprem/hosts.yml) y [cloud/hosts.yml](../../ansible/inventories/cloud/hosts.yml) a partir de los `outputs.tf`.
2. Comprobar la conectividad:
```bash
   ansible -i ansible/inventories/onprem/hosts.yml all -m ping
```

### Fase 3: Configuración (Ansible)

> Implementado: `base.yml` (roles `common` y `hardening` con firewall UFW), `k3s.yml` (rol `k3s` con
> reglas de firewall y kubeconfig local) y `site.yml`. Pendiente: `core.yml`.

1. Si el cambio afecta a SSH, abrir antes una sesión en la VM como red de seguridad.
2. Aplicar la configuración completa (desde `ansible/`):
```bash
   ansible-playbook playbooks/site.yml
```
   Una segunda ejecución debe terminar con `changed=0`.
3. Verificar el hardening de SSH:
```bash
   ssh admin@<IP_VM> "echo SSH_OK"            # debe funcionar
   ssh root@<IP_VM> "echo NO_DEBERIA_ENTRAR"  # debe fallar: Permission denied
```
4. Verificar el clúster desde el equipo de administración (el rol `k3s` copia el kubeconfig a
   `~/.kube/tfg-onprem.yaml`):
```bash
   export KUBECONFIG=~/.kube/tfg-onprem.yaml
   kubectl get nodes
   kubectl get pods -A
```
   Todos los nodos deben estar en `Ready`, los pods de `kube-system` en `Running` y no debe haber pods de Traefik.
5. Verificar el firewall:
```bash
   ssh admin@<IP_VM> "sudo ufw status"
   nc -zv -w 3 <IP_K3S> 10250    # debe fallar (TIMEOUT): puerto no permitido
```

### Fase 4: GitOps (Argo CD)

> Implementado: Argo CD v3.5.3, App of Apps y `demo-app`. Pendiente: componentes de plataforma (Traefik…).

1. Ejecutar el bootstrap (incluido en `make deploy`):
```bash
   make bootstrap
```
   Instala Argo CD si no existe ([bootstrap/argocd](../../gitops/bootstrap/argocd/kustomization.yaml))
   y aplica la [aplicación raíz](../../gitops/bootstrap/root-app.yaml). Si Argo CD ya existe,
   no lo reinstala: se gestiona a sí mismo desde Git.
2. Verificar las aplicaciones:
```bash
   kubectl -n argocd get applications
```
   Todas deben estar en `Synced` y `Healthy`.
3. Acceso a la interfaz web (temporal, hasta publicar Argo CD con Traefik):
```bash
   kubectl -n argocd port-forward svc/argocd-server 8080:443
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
```
   Abrir https://localhost:8080 con el usuario `admin`.

> Argo CD lee la rama `main` de GitHub: los cambios deben estar fusionados para aplicarse.

## Verificación

- [ ] `kubectl get nodes`: todos los nodos en `Ready`.
- [ ] `kubectl -n argocd get applications`: todas en `Synced` / `Healthy`.
- [ ] Grafana muestra las métricas de `node_exporter` de todos los hosts.
- [ ] `demo-app` accesible por Ingress con certificado TLS válido.
- [ ] Un cambio fusionado en `gitops/apps/` se aplica solo en menos de 3 minutos.
- [ ] Un cambio manual en el clúster es revertido por Argo CD (`selfHeal`).

## Relacionado

- [[configuracion-inicial]] · [[añadir-nodo]] · [[restauracion]] . [[2026-10-05-reconstruccion-3]]
- Diario: [[2026-10-01]] · [[2026-10-02]] . [[2026-10-05]]
