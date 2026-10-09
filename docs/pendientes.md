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

- [ ] Rotar la clave SSH personal (passphrase olvidada; hoy funciona porque está cargada en el
      `ssh-agent`): clave nueva con passphrase guardada en un gestor de contraseñas, añadirla a
      Proxmox sin quitar la antigua, cambiarla en `terraform.tfvars` y en `group_vars/core.yml`
      (Warpgate) y retirar la antigua.
- [ ] Copia de seguridad de la clave `age` (`~/.config/sops/age/keys.txt`) y de la contraseña de
      admin de Warpgate en un gestor de contraseñas.
- [ ] Caducidad de la clave en el agente (`ssh-add -t`); opcional, clave FIDO2 `ed25519-sk`.
- [ ] Segundo factor (TOTP) en Warpgate: `ssh: [PublicKey, Totp]` y en el panel web (el login de
      Ansible por la API tendrá que contemplarlo).
- [ ] Restringir el puerto 22 de las VMs a `core-01` y al equipo de administración. Requiere IP fija
      del portátil (reserva DHCP en el router o IP de NetBird); después, cerrar también el 22 de
      `core-01` a la LAN.
- [ ] Claves de host fijas para Warpgate (`--import-ssh-host-keys`, cifradas con SOPS) para que su
      huella no cambie al recrear `core-01`.
- [ ] Hook de pre-commit que compruebe que los ficheros de `secrets/` están cifrados con SOPS.
- [ ] Certificado válido para Warpgate (puerto 8888) y `warpgate_api_validate_certs: true`.
- [ ] Usuario SSH dedicado con permisos mínimos para Terraform en Proxmox, en lugar de root.
- [ ] Endurecer el SSH del nodo Proxmox (`PermitRootLogin prohibit-password`, sin contraseñas).
- [ ] Certificado válido en Proxmox y eliminar `PROXMOX_VE_INSECURE`.
- [ ] Contraseña de `admin` de Argo CD declarativa (hash en `argocd-secret` cifrado con SOPS, ya
      disponible), para no tener que cambiarla a mano tras cada reconstrucción.
- [ ] DNS interno en lugar de sslip.io para los servicios con credenciales (Argo CD, Warpgate…),
      con certificados válidos emitidos por cert-manager.

## Kubernetes y red

- [ ] Modo *agent* en el rol `k3s` para unir nodos al clúster: hoy solo instala un servidor
      (ver [añadir-nodo](runbooks/añadir-nodo.md)).
- [ ] Puertos para clúster de varios nodos: `10250/tcp`, `8472/udp` (Flannel) y `2379-2380/tcp` (etcd).
- [ ] Vigilar la política `deny (routed)` de UFW al escalar a varios nodos y al publicar aplicaciones.
- [ ] Renombrar los contextos del kubeconfig (`tfg-onprem`, `tfg-cloud`) cuando exista el clúster cloud.
- [ ] Vigilar la RAM del nodo Proxmox (~800 MB de margen) hasta ampliarlo a 32 GB.

## Automatización y comodidad

- [ ] Fijar las GitHub Actions por SHA en lugar de etiqueta y activar Dependabot para actualizarlas.
- [ ] Validar los manifiestos de `gitops/` en CI (por ejemplo, con kubeconform).
- [ ] Warpgate por API: opción para eliminar los objetos que no estén en `group_vars/core.yml`
      (hoy solo crea lo que falta) y comprobar si admite `scp`/`sftp`.
- [ ] Actualizar `age` a 1.3.2 en el equipo de administración.

## Documentación

- [ ] Índice de la memoria del TFG y qué material del repositorio alimenta cada capítulo.
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
- [x] Enlaces de la documentación en formato Markdown en lugar de wikilinks. (2026-10-08, PR #36)
- [x] VM `core-01` y plan de IPs documentado en `arquitectura.md`. (2026-10-08, PR #37)
- [x] Gestión de secretos con SOPS + age (`.sops.yaml` y primer secreto cifrado). (2026-10-08, PR #37)
- [x] Bastión Warpgate en `core-01` con rol de Ansible. (2026-10-08, PR #37)
- [x] Acceso SSH a las VMs a través de Warpgate. (2026-10-08, PR #38)
- [x] Configuración de Warpgate como código con su API; probada recreando `core-01` (47 s). (2026-10-08, PR #39)
- [x] Documentación al día tras la auditoría: README, mapa, arquitectura, ADR, runbooks y diarios. (2026-10-09)
- [x] Revisión del ADR-0003 (Kustomize, `prune`, `selfHeal` y `ServerSideApply`). (2026-10-09)
