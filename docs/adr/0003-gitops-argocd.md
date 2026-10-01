---
title: "ADR-0003: GitOps con Argo CD"
estado: Aceptado
fecha: 2026-10-01
tags: [adr, gitops, argocd]
---

# ADR-0003: GitOps con Argo CD (App of Apps + ApplicationSets)

↑ [[docs/README|Mapa del repositorio]] · [[arquitectura]]

**Estado:** Aceptado · **Fecha:** 2026-10-01

## Contexto

Una vez que Ansible deja el clúster k3s operativo ([[0001-eleccion-k3s]]), los componentes de plataforma y las aplicaciones tienen que desplegarse de forma declarativa, auditable y reproducible, con el repositorio Git como única fuente de verdad.

## Decisión

Se usa **Argo CD** con este esquema:

| Pieza | Ruta | Función |
|---|---|---|
| Instalación de Argo CD | [bootstrap/argocd/kustomization.yaml](../../gitops/bootstrap/argocd/kustomization.yaml), [values.yaml](../../gitops/bootstrap/argocd/values.yaml) | Se aplica una sola vez desde [bootstrap.sh](../../scripts/bootstrap.sh) |
| Root application | [bootstrap/root-app.yaml](../../gitops/bootstrap/root-app.yaml) | Patrón *App of Apps*: apunta a `gitops/appsets/` |
| ApplicationSet de plataforma | [appsets/platform.yaml](../../gitops/appsets/platform.yaml) | Una `Application` por directorio en `gitops/platform/*` |
| ApplicationSet de aplicaciones | [appsets/apps.yaml](../../gitops/appsets/apps.yaml) | Una `Application` por directorio en `gitops/apps/*` |

Componentes de plataforma y su relación con la infraestructura base:

- `traefik`: Ingress controller; sustituye al Traefik integrado de k3s.
- `cert-manager`: certificados TLS para los Ingress.
- `monitoring`: - `monitoring`: kube-prometheus-stack (Prometheus, Grafana, Alertmanager). Los nodos k3s se monitorizan con el node-exporter que incluye el chart; las VMs fuera del clúster (`core-01`, `cloud-01`, PBS) con el rol Ansible `node_exporter`.
- `loki`: agregación de logs.
- `velero`: copias de seguridad del clúster (ver [[restauracion]]).

## Alternativas consideradas

- **Flux CD:** alternativa GitOps equivalente. Se elige Argo CD por su interfaz web,
  que facilita visualizar el estado de sincronización y demostrarlo.
- **Despliegue desde la CI (`kubectl apply` / `helm upgrade` en GitHub Actions):**
  descartada. Requiere dar a la CI credenciales del clúster y no corrige las derivas:
  si alguien cambia algo a mano, nadie lo detecta.
- **Despliegue con Ansible:** descartada para las aplicaciones. Ansible se ejecuta
  puntualmente y no reconcilia de forma continua el estado del clúster.

## Consecuencias

- ✅ Añadir un componente consiste en crear un directorio; la ApplicationSet lo detecta sola.
- ✅ Cualquier deriva entre el clúster y Git queda visible en Argo CD.
- ⚠️ Los secretos no pueden guardarse en claro en Git: dependen de [[0004-gestion-secretos-sops]].
- ⚠️ El orden de arranque entre componentes (p. ej. CRDs de cert-manager) debe controlarse con *sync waves*.
- ⚠️ El rol Ansible `k3s` debe instalar k3s con `--disable traefik` para evitar dos
  Ingress controllers.

## Relacionado

- ADR: [[0001-eleccion-k3s]], [[0004-gestion-secretos-sops]]
- Runbooks: [[puesta-en-marcha]], [[restauracion]]
- Diario: [[2026-10-01]]
