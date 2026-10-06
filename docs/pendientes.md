---
title: "Pendientes y mejoras"
tags: [pendientes, backlog]
---

# Pendientes y mejoras

↑ [[docs/README|Mapa del repositorio]]

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
- [ ] Cambiar la contraseña inicial de `admin` de Argo CD y borrar el secreto `argocd-initial-admin-secret`.
- [ ] Revisar el `ADR-0003` (Kustomize en lugar de Helm, `prune` y `ServerSideApply`).

## Kubernetes y red

- [ ] Puertos para clúster de varios nodos: `10250/tcp`, `8472/udp` (Flannel) y `2379-2380/tcp` (etcd).
- [ ] Vigilar la política `deny (routed)` de UFW al escalar a varios nodos y al publicar aplicaciones.
- [ ] Renombrar los contextos del kubeconfig (`tfg-onprem`, `tfg-cloud`) cuando exista el clúster cloud.

## Automatización y comodidad



## Documentación

- [ ] Completar `README.md` (está vacío) y `LICENSE`.
- [ ] Revisar `arquitectura.md`, `docs/README.md`, ADR-0001 y los runbooks de añadir nodo y restauración.
- [ ] Documentar el plan de IPs en `arquitectura.md`.
- [ ] Revisión general de formato del repositorio antes de la entrega.
- [ ] Añadir el texto de la licencia en `LICENSE` (por ejemplo, MIT).

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
