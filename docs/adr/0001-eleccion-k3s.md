---
title: "ADR-0001: Elección de k3s"
estado: Aceptado
fecha: 2026-10-01
tags: [adr, kubernetes, k3s]
---

# ADR-0001: Elección de k3s como distribución de Kubernetes

↑ [Mapa del repositorio](../README.md) · [arquitectura](../arquitectura.md)

**Estado:** Aceptado · **Fecha:** 2026-10-01

## Contexto

La plataforma necesita un orquestador de contenedores que funcione sobre VMs de Proxmox con recursos limitados (laboratorio doméstico/académico) y que se pueda extender a nodos en la nube a través de la malla NetBird. El clúster tiene que instalarse de forma reproducible con Ansible y gestionarse después mediante GitOps ([0003-gitops-argocd](0003-gitops-argocd.md)).

## Opciones consideradas

| Opción | Ventajas | Inconvenientes |
|---|---|---|
| **k3s** | Binario único, bajo consumo de memoria, distribución certificada por la CNCF, instalación sencilla | Trae componentes empaquetados (Traefik, ServiceLB) que hay que desactivar o asumir |
| kubeadm | Kubernetes «estándar», máximo control | Más pasos de instalación y mantenimiento, mayor consumo |
| RKE2 | Orientado a seguridad (CIS) | Más pesado que k3s para el hardware disponible |
| Kubernetes gestionado (EKS/AKS/GKE) | Sin plano de control que mantener | Coste y no cubre la parte on-prem |

## Decisión

Se adopta **k3s**, instalado con el rol de Ansible `k3s` sobre el grupo de hosts `k3s`.

- Traefik se gestiona desde GitOps (`gitops/platform/traefik/`), así que se prevé desactivar el Traefik integrado (`--disable traefik`).
- El resto de componentes de plataforma (cert-manager, monitorización, Loki, Velero) se despliegan con Argo CD.

## Consecuencias

- ✅ Despliegue rápido y reproducible, adecuado al hardware disponible.
- ✅ Compatible con todo el ecosistema Kubernetes (Helm, Argo CD, Velero).
- ⚠️ Hay que documentar qué componentes integrados se desactivan y por qué.
- ⚠️ La alta disponibilidad del plano de control (etcd embebido con 3 servidores) queda fuera del alcance inicial.

## Implementación

- Playbook: [k3s.yml](../../ansible/playbooks/k3s.yml)
- Rol: [roles/k3s/](../../ansible/roles/k3s/)
- Variables del grupo: [group_vars/k3s.yml](../../ansible/inventories/onprem/group_vars/k3s.yml)
- VMs: [terraform/envs/onprem/main.tf](../../terraform/envs/onprem/main.tf) (módulo [proxmox-vm](../../terraform/modules/proxmox-vm/main.tf))

## Actualización (2026-10-09)

- Implementado con k3s `v1.36.5+k3s1` (versión fijada en el rol) y `--disable=traefik`: Traefik se
  despliega con Argo CD desde [gitops/platform/traefik/](../../gitops/platform/traefik/application.yaml).
- ServiceLB (integrado en k3s) se mantiene: publica Traefik en los puertos 80/443 de la IP del nodo.
- Clúster de un nodo (`k3s-01`); la ampliación a varios nodos sigue pendiente.

## Relacionado

- ADR: [0002-terraform-ansible-separacion](0002-terraform-ansible-separacion.md), [0003-gitops-argocd](0003-gitops-argocd.md)
- Runbooks: [puesta-en-marcha](../runbooks/puesta-en-marcha.md), [añadir-nodo](../runbooks/añadir-nodo.md), [restauracion](../runbooks/restauracion.md)
- Diario: [2026-10-01](../diario/2026-10-01.md)
