---
title: Mapa del repositorio
tags: [moc, tfg]
---

# Mapa del repositorio

Nodo central de la documentación del TFG **Plataforma híbrida** (on-premise sobre Proxmox, preparada
para extenderse a la nube). Desde aquí se enlazan las decisiones de arquitectura, los procedimientos
operativos, las pruebas y el diario de trabajo.

> [!NOTE]
> **Estado (2026-10-09):** entorno on-premise operativo y reproducible: VMs con Terraform, configuración
> y hardening con Ansible, clúster k3s, GitOps con Argo CD, bastión Warpgate y secretos con SOPS.
> Pendiente: entorno cloud, VPN, monitorización y copias de seguridad ([pendientes](pendientes.md)).

## Visión general

- [arquitectura](arquitectura.md): capas de la plataforma, flujo de despliegue, plan de IPs y dependencias.
- [pendientes](pendientes.md): mejoras, hardening y tareas abiertas.

## Componentes

| Capa | Responsabilidad | Código | Documentación |
|---|---|---|---|
| Provisión (IaC) | Crear VMs en Proxmox (y en la nube) | [terraform/](../terraform/) | [0002-terraform-ansible-separacion](adr/0002-terraform-ansible-separacion.md) |
| Configuración | Sistema base, hardening, servicios core y k3s | [ansible/](../ansible/) | [0002-terraform-ansible-separacion](adr/0002-terraform-ansible-separacion.md), [0001-eleccion-k3s](adr/0001-eleccion-k3s.md) |
| Orquestación | Clúster Kubernetes ligero | [ansible/playbooks/k3s.yml](../ansible/playbooks/k3s.yml) | [0001-eleccion-k3s](adr/0001-eleccion-k3s.md) |
| Entrega continua | Despliegue declarativo con Argo CD | [gitops/](../gitops/) | [0003-gitops-argocd](adr/0003-gitops-argocd.md) |
| Acceso | Bastión SSH Warpgate en `core-01` | [ansible/roles/warpgate/](../ansible/roles/warpgate/), [group_vars/core.yml](../ansible/inventories/onprem/group_vars/core.yml) | [acceso-warpgate](runbooks/acceso-warpgate.md) |
| Secretos | Cifrado de secretos en el repositorio | [.sops.yaml](../.sops.yaml), [secrets/](../secrets/) | [0004-gestion-secretos-sops](adr/0004-gestion-secretos-sops.md) |
| Automatización | Puente Terraform → Ansible y bootstrap | [scripts/](../scripts/), [Makefile](../Makefile) | [puesta-en-marcha](runbooks/puesta-en-marcha.md) |
| CI / Seguridad | Validación de IaC y detección de secretos | [.github/workflows/](../.github/workflows/), [.pre-commit-config.yaml](../.pre-commit-config.yaml) | [CI y seguridad](arquitectura.md#ci-y-seguridad) |

## Decisiones de arquitectura (ADR)

- [0001-eleccion-k3s](adr/0001-eleccion-k3s.md): k3s como distribución de Kubernetes.
- [0002-terraform-ansible-separacion](adr/0002-terraform-ansible-separacion.md): Terraform provisiona, Ansible configura.
- [0003-gitops-argocd](adr/0003-gitops-argocd.md): Argo CD con el patrón *App of Apps*.
- [0004-gestion-secretos-sops](adr/0004-gestion-secretos-sops.md): SOPS + age para cifrar secretos versionados.

## Runbooks

- [configuracion-inicial](runbooks/configuracion-inicial.md): requisitos del equipo de administración y de Proxmox.
- [puesta-en-marcha](runbooks/puesta-en-marcha.md): despliegue completo desde cero.
- [acceso-warpgate](runbooks/acceso-warpgate.md): acceso SSH a las VMs a través del bastión.
- [añadir-nodo](runbooks/añadir-nodo.md): ampliar el clúster k3s con un nodo nuevo.
- [restauracion](runbooks/restauracion.md): recuperación ante desastres.

## Pruebas de reproducibilidad

- [Reconstrucción 1](pruebas/2026-10-03-reconstruccion-1.md): VM y configuración base (parcial, 26 min 37 s).
- [Reconstrucción 2](pruebas/2026-10-04-reconstruccion-2.md): VM y configuración base (9 min 26 s).
- [Reconstrucción 3](pruebas/2026-10-05-reconstruccion-3.md): + firewall, k3s y kubectl (8 min 35 s).
- [Reconstrucción 4](pruebas/2026-10-07-reconstruccion-4.md): plataforma completa con `make rebuild` (5 min 25 s).

## Diario de trabajo

- [2026-10-01](diario/2026-10-01.md): estructura del repositorio, herramientas y usuario de Terraform en Proxmox.
- [2026-10-02](diario/2026-10-02.md): pre-commit, conexión de Terraform con Proxmox y primera VM.
- [2026-10-03](diario/2026-10-03.md): inventario desde Terraform, Ansible y reconstrucción 1.
- [2026-10-04](diario/2026-10-04.md): agente QEMU con cloud-init, rol `k3s` y reconstrucción 2.
- [2026-10-05](diario/2026-10-05.md): kubeconfig, firewall UFW, Makefile y reconstrucción 3.
- [2026-10-06](diario/2026-10-06.md): repositorio público, Argo CD, Traefik e Ingress.
- [2026-10-07](diario/2026-10-07.md): reconstrucción 4 y CI real en GitHub Actions.
- [2026-10-08](diario/2026-10-08.md): `core-01`, SOPS + age y bastión Warpgate configurado por API.

## Otros recursos

- `docs/diagramas/`: diagramas de arquitectura (pendiente).

## Convenciones

- **ADR**: `docs/adr/NNNN-titulo.md`, con formato *Contexto / Decisión / Consecuencias* y estado (`Propuesto`, `Aceptado`, `Sustituido`).
- **Runbook**: `docs/runbooks/accion.md`, con prerrequisitos, pasos numerados y verificación.
- **Diario**: `docs/diario/AAAA-MM-DD.md`, una entrada por sesión de trabajo.
- **Pruebas**: `docs/pruebas/AAAA-MM-DD-nombre.md`, con alcance, procedimiento, resultado y tiempo.
- **Enlaces**: Markdown con rutas relativas (`[texto](ruta.md)`), visibles en GitHub.
- **Avisos**: formato de GitHub (`> [!NOTE]`, `> [!WARNING]`).
