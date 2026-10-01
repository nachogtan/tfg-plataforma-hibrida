---
title: "ADR-0001: Elección de k3s"
estado: Aceptado
fecha: 2026-10-01
tags: [adr, kubernetes, k3s]
---

# ADR-0001: Elección de k3s como distribución de Kubernetes

↑ [[docs/README|Mapa del repositorio]] · [[arquitectura]]

**Estado:** Aceptado · **Fecha:** 2026-10-01

## Contexto

La plataforma necesita un orquestador de contenedores que funcione sobre VMs de Proxmox con recursos limitados (laboratorio doméstico/académico) y que se pueda extender a nodos en la nube a través de la malla NetBird. El clúster tiene que instalarse de forma reproducible con Ansible y gestionarse después mediante GitOps ([[0003-gitops-argocd]]).

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

## Relacionado

- ADR: [[0002-terraform-ansible-separacion]], [[0003-gitops-argocd]]
- Runbooks: [[puesta-en-marcha]], [[añadir-nodo]], [[restauracion]]
- Diario: [[2026-10-01]]
