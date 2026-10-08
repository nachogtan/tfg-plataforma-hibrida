---
title: "Pendientes y mejoras"
tags: [pendientes, backlog]
---

# Pendientes y mejoras

↑ [Mapa del repositorio](README.md)

Lista viva de tareas pendientes y mejoras identificadas durante el proyecto.
Al completar una, se marca con `[x]` y se indica la fecha o el PR.

## Posibles ampliaciones

- [ ] Agente de IA OpenClaw en un namespace aislado: NetworkPolicies (solo salida a la API del LLM),
      RBAC mínimo, secretos con SOPS, límites de recursos y sin exposición pública.
- [ ] Versión en inglés de la documentación (`README.md` en inglés y `README.es.md` en español).

## Seguridad

- [ ] Usuario SSH dedicado con permisos mínimos para Terraform en Proxmox, en lugar de root.
- [ ] Endurecer el SSH del nodo Proxmox (`PermitRootLogin prohibit-password`, sin contraseñas).
- [ ] Certificado válido en Proxmox y eliminar `PROXMOX_VE_INSECURE`.
- [ ] Contraseña de `admin` de Argo CD declarativa (hash en `argocd-secret` cifrado con SOPS), para no
      tener que cambiarla a mano tras cada reconstrucción.
- [ ] DNS interno en lugar de sslip.io para los servicios con credenciales (Argo CD, Warpgate…),
      con certificados válidos emitidos por cert-manager.
- [ ] Revisar el `ADR-0003` (Kustomize en lugar de Helm, `prune` y `ServerSideApply`).

## Kubernetes y red

- [ ] Puertos para clúster de varios nodos: `10250/tcp`, `8472/udp` (Flannel) y `2379-2380/tcp` (etcd).
- [ ] Vigilar la política `deny (routed)` de UFW al escalar a varios nodos y al publicar aplicaciones.
- [ ] Renombrar los contextos del kubeconfig (`tfg-onprem`, `tfg-cloud`) cuando exista el clúster cloud.

## Automatización y comodidad

- [ ] Fijar las GitHub Actions por SHA en lugar de etiqueta y activar Dependabot para actualizarlas.
- [ ] Validar los manifiestos de `gitops/` en CI (por ejemplo, con kubeconform).

## Documentación

- [ ] Revisar `arquitectura.md`, `docs/README.md`, ADR-0001 y los runbooks de añadir nodo y restauración.
- [ ] Documentar el plan de IPs en `arquitectura.md`.
- [ ] Revisión general de formato del repositorio antes de la entrega.

## Completados

- [x] Reglas de `.gitignore` para `kubeconfig*`, `*.key` y `*.pem`. (2026-10-05)
- [x] Firewall en el rol `hardening` con los puertos de k3s. (2026-10-05)
- [x] Instalar el agente QEMU con cloud-init. (2026-10-04)
- [x] Makefile con los comandos del runbook y carga automática de `.env`. (2026-10-05)
- [x] README.md del proyecto y `.env.example`. (2026-10-05)
- [x] Limpieza automática de huellas SSH al recrear VMs (`make inventory`). (2026-10-05)
- [x] Repositorio público tras escanear el historial con gitleaks y `LICENSE` con derechos reservados. (2026-10-06)
- [x] GitOps con Argo CD, App of Apps y `demo-app`. (2026-10-06)
- [x] Bootstrap de Argo CD automatizado en `make deploy`. (2026-10-06)
- [x] Protección de `main` con ruleset (PR obligatorio, sin force push ni borrado). (2026-10-06)
- [x] Traefik desplegado por Argo CD y puertos 80/443 en el firewall. (2026-10-06)
- [x] `demo-app` publicada por Ingress en sslip.io. (2026-10-06)
- [x] Interfaz de Argo CD por HTTPS a través de Traefik. (2026-10-06)
- [x] Cambiar la contraseña inicial de `admin` de Argo CD y eliminar `argocd-initial-admin-secret`. (2026-10-06)
- [x] `git config fetch.prune true` en el repositorio. (2026-10-07)
- [x] Reconstrucción 4: plataforma completa con `make rebuild` en 5 min 25 s. (2026-10-07)
- [x] CI real en GitHub Actions (Terraform, Ansible, gitleaks y pre-commit) y checks obligatorios en `main`. (2026-10-07)
