---
title: Mapa del repositorio
tags: [moc, tfg]
---

# Mapa del repositorio (MOC)

Nodo central de la documentación del TFG **Plataforma híbrida** (on-premise sobre Proxmox + nube). Desde aquí se enlazan todas las decisiones de arquitectura, procedimientos operativos y entradas del diario.

> [!info] Estado del repositorio
> El repositorio se encuentra en fase de **estructura inicial** (commit `bd80756`): los ficheros de Terraform, Ansible, GitOps y scripts existen pero aún están vacíos. Esta documentación describe la arquitectura **prevista** y se irá actualizando a medida que se implemente cada componente.

## Visión general

- [[arquitectura]]: capas de la plataforma, flujo de despliegue y dependencias entre componentes.

## Componentes

| Capa | Responsabilidad | Código | Documentación |
|---|---|---|---|
| Provisión (IaC) | Crear VMs en Proxmox y en la nube | [terraform/](../terraform/) | [[0002-terraform-ansible-separacion]] |
| Configuración | Sistema base, hardening, servicios core y k3s | [ansible/](../ansible/) | [[0002-terraform-ansible-separacion]], [[0001-eleccion-k3s]] |
| Orquestación | Clúster Kubernetes ligero | [ansible/playbooks/k3s.yml](../ansible/playbooks/k3s.yml) | [[0001-eleccion-k3s]] |
| Entrega continua | Despliegue declarativo con Argo CD | [gitops/](../gitops/) | [[0003-gitops-argocd]] |
| Secretos | Cifrado de secretos en el repositorio | [.sops.yaml](../.sops.yaml), [secrets/](../secrets/) | [[0004-gestion-secretos-sops]] |
| Automatización | Puente Terraform → Ansible y bootstrap | [scripts/](../scripts/), [Makefile](../Makefile) | [[puesta-en-marcha]] |
| CI / Seguridad | Validación de IaC y análisis de seguridad | [.github/workflows/](../.github/workflows/), [.pre-commit-config.yaml](../.pre-commit-config.yaml) | [[arquitectura#CI y seguridad]] |

## Decisiones de arquitectura (ADR)

- [[0001-eleccion-k3s]]: k3s como distribución de Kubernetes.
- [[0002-terraform-ansible-separacion]]: Terraform provisiona, Ansible configura.
- [[0003-gitops-argocd]]: Argo CD con patrón *App of Apps* y ApplicationSets.
- [[0004-gestion-secretos-sops]]: SOPS para cifrar secretos versionados.

## Runbooks

- [[puesta-en-marcha]]: despliegue completo desde cero.
- [[añadir-nodo]]: ampliar el clúster k3s con un nodo nuevo.
- [[restauracion]]: recuperación ante desastres (estado, secretos y cargas de trabajo).

## Diario de trabajo

- [[2026-10-01]]: estructura inicial del repositorio y base documental.

## Otros recursos

- `docs/diagramas/`: diagramas de arquitectura (pendiente).
- `docs/pruebas/`: evidencias y resultados de pruebas (pendiente).

## Convenciones

- **ADR**: `docs/adr/NNNN-titulo.md`, con formato *Contexto / Decisión / Consecuencias* y estado (`Propuesto`, `Aceptado`, `Sustituido`).
- **Runbook**: `docs/runbooks/accion.md`, con prerrequisitos, pasos numerados y verificación.
- **Diario**: `docs/diario/AAAA-MM-DD.md`, una entrada por sesión de trabajo.
- Notas enlazadas con `[[nota]]`; código enlazado con rutas relativas al fichero.
