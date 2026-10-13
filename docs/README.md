---
title: Mapa del repositorio
tags: [moc, tfg]
---

# Mapa del repositorio

Nodo central de la documentación del TFG **Plataforma híbrida** (on-premise sobre Proxmox y cloud en
AWS). Desde aquí se enlazan las decisiones de arquitectura, los procedimientos operativos, las
pruebas y el diario de trabajo.

> [!NOTE]
> **Estado (2026-10-13):** plataforma operativa y reproducible en los dos entornos: VMs con
> Terraform, configuración y hardening con Ansible, clúster k3s, GitOps con Argo CD, bastión Warpgate,
> secretos con SOPS, VPN en malla con NetBird, entorno cloud efímero en AWS, monitorización con
> Grafana Cloud y copias de seguridad con Proxmox Backup Server (restauración probada).
> Mejoras abiertas en [pendientes](pendientes.md).

## Visión general

- [arquitectura](arquitectura.md): capas de la plataforma, flujo de despliegue, topología, plan de IPs y dependencias.
- [pendientes](pendientes.md): mejoras, hardening y tareas abiertas.

## Componentes

| Capa | Responsabilidad | Código | Documentación |
|---|---|---|---|
| Provisión (IaC) | VMs en Proxmox; red y VMs en AWS | [terraform/](../terraform/) | [0002-terraform-ansible-separacion](adr/0002-terraform-ansible-separacion.md), [0006-aws-credenciales-sso](adr/0006-aws-credenciales-sso.md) |
| Configuración | Sistema base, hardening, servicios core y k3s | [ansible/](../ansible/) | [0002-terraform-ansible-separacion](adr/0002-terraform-ansible-separacion.md), [0001-eleccion-k3s](adr/0001-eleccion-k3s.md) |
| Orquestación | Clúster Kubernetes ligero | [ansible/playbooks/k3s.yml](../ansible/playbooks/k3s.yml) | [0001-eleccion-k3s](adr/0001-eleccion-k3s.md) |
| Entrega continua | Despliegue declarativo con Argo CD | [gitops/](../gitops/) | [0003-gitops-argocd](adr/0003-gitops-argocd.md) |
| Acceso | Bastión SSH Warpgate en `core-01` | [ansible/roles/warpgate/](../ansible/roles/warpgate/), [group_vars/core.yml](../ansible/inventories/onprem/group_vars/core.yml) | [acceso-warpgate](runbooks/acceso-warpgate.md) |
| Red | VPN en malla NetBird; VMs cloud sin puertos de entrada | [ansible/roles/netbird/](../ansible/roles/netbird/) | [0005-vpn-netbird](adr/0005-vpn-netbird.md), [0007-vm-cloud-sin-puertos-entrada](adr/0007-vm-cloud-sin-puertos-entrada.md) |
| Observabilidad | Métricas, panel y alertas | [ansible/roles/node_exporter/](../ansible/roles/node_exporter/), [gitops/platform/monitoring/](../gitops/platform/monitoring/) | [0008-monitorizacion-grafana-cloud](adr/0008-monitorizacion-grafana-cloud.md) |
| Copias de seguridad | Copias cifradas de las VMs en Proxmox Backup Server | Configuración manual documentada | [0009-copias-pbs](adr/0009-copias-pbs.md) |
| Secretos | Cifrado de secretos en el repositorio | [.sops.yaml](../.sops.yaml), [secrets/](../secrets/) | [0004-gestion-secretos-sops](adr/0004-gestion-secretos-sops.md) |
| Automatización | Puente Terraform → Ansible, bootstrap y Makefile multientorno | [scripts/](../scripts/), [Makefile](../Makefile) | [puesta-en-marcha](runbooks/puesta-en-marcha.md) |
| CI / Seguridad | Validación de IaC y detección de secretos | [.github/workflows/](../.github/workflows/), [.pre-commit-config.yaml](../.pre-commit-config.yaml) | [CI y seguridad](arquitectura.md#ci-y-seguridad) |

## Decisiones de arquitectura (ADR)

- [0001-eleccion-k3s](adr/0001-eleccion-k3s.md): k3s como distribución de Kubernetes.
- [0002-terraform-ansible-separacion](adr/0002-terraform-ansible-separacion.md): Terraform provisiona, Ansible configura.
- [0003-gitops-argocd](adr/0003-gitops-argocd.md): Argo CD con el patrón *App of Apps*.
- [0004-gestion-secretos-sops](adr/0004-gestion-secretos-sops.md): SOPS + age para cifrar secretos versionados.
- [0005-vpn-netbird](adr/0005-vpn-netbird.md): VPN en malla con NetBird (plano de control en SaaS en la fase 1).
- [0006-aws-credenciales-sso](adr/0006-aws-credenciales-sso.md): AWS con credenciales temporales (IAM Identity Center) y mínimo privilegio.
- [0007-vm-cloud-sin-puertos-entrada](adr/0007-vm-cloud-sin-puertos-entrada.md): VMs cloud sin puertos de entrada, administradas por NetBird.
- [0008-monitorizacion-grafana-cloud](adr/0008-monitorizacion-grafana-cloud.md): monitorización con Grafana Cloud y un único agente (Alloy) en el clúster.
- [0009-copias-pbs](adr/0009-copias-pbs.md): copias de seguridad cifradas con Proxmox Backup Server.

## Runbooks

- [configuracion-inicial](runbooks/configuracion-inicial.md): requisitos del equipo de administración y de Proxmox.
- [puesta-en-marcha](runbooks/puesta-en-marcha.md): despliegue completo desde cero.
- [acceso-warpgate](runbooks/acceso-warpgate.md): acceso SSH a las VMs a través del bastión.
- [acceso-vpn](runbooks/acceso-vpn.md): VPN en malla con NetBird (equipos, políticas y rotación).
- [vm-cloud](runbooks/vm-cloud.md): entorno cloud en AWS (crear, configurar por la VPN y destruir).
- [monitorizacion](runbooks/monitorizacion.md): métricas en Grafana Cloud, alerta por Telegram y rotación del token.
- [backups](runbooks/backups.md): copias con Proxmox Backup Server, cifrado, mantenimiento y prueba de restauración.
- [añadir-nodo](runbooks/añadir-nodo.md): ampliar el clúster k3s con un nodo nuevo.
- [restauracion](runbooks/restauracion.md): recuperación ante desastres (reconstruir y restaurar).

## Pruebas de reproducibilidad y recuperación

- [Reconstrucción 1](pruebas/2026-10-03-reconstruccion-1.md): VM y configuración base (parcial, 26 min 37 s).
- [Reconstrucción 2](pruebas/2026-10-04-reconstruccion-2.md): VM y configuración base (9 min 26 s).
- [Reconstrucción 3](pruebas/2026-10-05-reconstruccion-3.md): + firewall, k3s y kubectl (8 min 35 s).
- [Reconstrucción 4](pruebas/2026-10-07-reconstruccion-4.md): plataforma completa con `make rebuild` (5 min 25 s).
- [Reconstrucción 5](pruebas/2026-10-09-reconstruccion-5.md): + Warpgate, SOPS y TOTP, sin pasos manuales (6 min 33 s).
- Entorno cloud (2026-10-12): `make deploy`, `check` y `destroy` con `ENV=cloud` ([vm-cloud](runbooks/vm-cloud.md)).
- Restauración desde PBS (2026-10-13): `core-01` con sus datos en 1 min 19 s ([backups](runbooks/backups.md)).

## Diario de trabajo

- [2026-10-01](diario/2026-10-01.md): estructura del repositorio, herramientas y usuario de Terraform en Proxmox.
- [2026-10-02](diario/2026-10-02.md): pre-commit, conexión de Terraform con Proxmox y primera VM.
- [2026-10-03](diario/2026-10-03.md): inventario desde Terraform, Ansible y reconstrucción 1.
- [2026-10-04](diario/2026-10-04.md): agente QEMU con cloud-init, rol `k3s` y reconstrucción 2.
- [2026-10-05](diario/2026-10-05.md): kubeconfig, firewall UFW, Makefile y reconstrucción 3.
- [2026-10-06](diario/2026-10-06.md): repositorio público, Argo CD, Traefik e Ingress.
- [2026-10-07](diario/2026-10-07.md): reconstrucción 4 y CI real en GitHub Actions.
- [2026-10-08](diario/2026-10-08.md): `core-01`, SOPS + age y bastión Warpgate configurado por API.
- [2026-10-09](diario/2026-10-09.md): documentación al día, contraseña de Argo CD con SOPS, TOTP y reconstrucción 5.
- [2026-10-10](diario/2026-10-10.md): ADR-0005 y VPN en malla con NetBird (clientes y políticas por API).
- [2026-10-11](diario/2026-10-11.md): AWS con SSO y VM `cloud-01` sin puertos de entrada, unida a NetBird.
- [2026-10-12](diario/2026-10-12.md): Makefile con `ENV=cloud` y monitorización con Grafana Cloud.
- [2026-10-13](diario/2026-10-13.md): alertas por Telegram, copias con Proxmox Backup Server y documentación al día.

## Otros recursos

- Diagramas: en Mermaid dentro de [arquitectura](arquitectura.md) y del [README](../README.md);
  `docs/diagramas/` queda para diagramas exportados (pendiente).

## Convenciones

- **ADR**: `docs/adr/NNNN-titulo.md`, con formato *Contexto / Decisión / Consecuencias* y estado (`Propuesto`, `Aceptado`, `Sustituido`).
- **Runbook**: `docs/runbooks/accion.md`, con prerrequisitos, pasos numerados y verificación.
- **Diario**: `docs/diario/AAAA-MM-DD.md`, una entrada por sesión de trabajo.
- **Pruebas**: `docs/pruebas/AAAA-MM-DD-nombre.md`, con alcance, procedimiento, resultado y tiempo.
- **Enlaces**: Markdown con rutas relativas (`[texto](ruta.md)`), visibles en GitHub.
- **Avisos**: formato de GitHub (`> [!NOTE]`, `> [!WARNING]`, `> [!CAUTION]`).
