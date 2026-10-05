---
title: "Pendientes y mejoras"
tags: [pendientes, backlog]
---

# Pendientes y mejoras

↑ [[docs/README|Mapa del repositorio]]

Lista viva de tareas pendientes y mejoras identificadas durante el proyecto.
Al completar una, se marca con `[x]` y se indica la fecha o el PR.

## Seguridad

- [ ] Usuario SSH dedicado con permisos mínimos para Terraform en Proxmox, en lugar de root.
- [ ] Endurecer el SSH del nodo Proxmox (`PermitRootLogin prohibit-password`, sin contraseñas).
- [ ] Certificado válido en Proxmox y eliminar `PROXMOX_VE_INSECURE`.

## Kubernetes y red

- [ ] Puertos para clúster de varios nodos: `10250/tcp`, `8472/udp` (Flannel) y `2379-2380/tcp` (etcd).
- [ ] Vigilar la política `deny (routed)` de UFW al escalar a varios nodos y al publicar aplicaciones.
- [ ] Renombrar los contextos del kubeconfig (`tfg-onprem`, `tfg-cloud`) cuando exista el clúster cloud.

## Automatización y comodidad

- [ ] Automatizar la carga de `.env` (direnv o Makefile).
- [ ] Rellenar el `Makefile` con los comandos del runbook.

## Documentación

- [ ] Completar `README.md` (está vacío) y `LICENSE`.
- [ ] Revisar `arquitectura.md`, `docs/README.md`, ADR-0001 y los runbooks de añadir nodo y restauración.
- [ ] Documentar el plan de IPs en `arquitectura.md`.
- [ ] Revisión general de formato del repositorio antes de la entrega.

## Completados

- [x] Reglas de `.gitignore` para `kubeconfig*`, `*.key` y `*.pem`. (2026-10-05)
- [x] Firewall en el rol `hardening` con los puertos de k3s. (2026-10-05)
- [x] Instalar el agente QEMU con cloud-init. (2026-10-04)
