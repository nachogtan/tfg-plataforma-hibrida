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

## Fase 3: Configuración (Ansible)

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

## Fase 4: GitOps (Argo CD)

> Implementado: Argo CD v3.5.3, App of Apps, `demo-app`, Traefik e Ingress con sslip.io.
> Pendiente: DNS interno y certificados válidos (cert-manager).

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
   Deben aparecer `root`, `argocd`, `platform`, `traefik` y `demo-app`, todas en `Synced` y `Healthy`.
   Traefik puede tardar unos minutos: lo despliega `platform` después de que `root` la cree.
3. Verificar Traefik:
```bash
   kubectl -n traefik get svc traefik
```
   `EXTERNAL-IP` debe ser la IP del nodo (ServiceLB de k3s), con los puertos `80` y `443`.
4. Verificar `demo-app` a través del Ingress:
```bash
   curl -s http://demo.<IP_K3S>.sslip.io
```
   Debe responder `whoami` con el nombre del pod (`Hostname`). Repetir para ver el reparto entre réplicas.
5. Acceder a la interfaz web de Argo CD en `https://argocd.<IP_K3S>.sslip.io`.
   Traefik usa un certificado autofirmado: aceptar el aviso del navegador. Usuario `admin`.
   - Primer acceso tras una instalación nueva: obtener la contraseña inicial.
```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
```
   - Cambiarla en *User Info → Update Password* y comprobar que el secreto inicial ya no existe
     (`kubectl -n argocd get secrets`); si sigue, borrarlo con
     `kubectl -n argocd delete secret argocd-initial-admin-secret`.
   - Sin Ingress (acceso de emergencia): `kubectl -n argocd port-forward svc/argocd-server 8080:80`
     y abrir http://localhost:8080.

> Argo CD lee la rama `main` de GitHub: los cambios deben estar fusionados para aplicarse.
> Los parámetros de `argocd-cmd-params-cm` (por ejemplo, `server.insecure`) solo se leen al arrancar:
> si se cambian con Argo CD ya en marcha, ejecutar `kubectl -n argocd rollout restart deployment argocd-server`.
> En una instalación nueva no hace falta, porque ya están presentes desde el principio.

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
