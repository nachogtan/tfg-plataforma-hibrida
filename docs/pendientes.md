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

- [ ] Caducidad de la clave en el agente (`ssh-add -t`); opcional, clave FIDO2 `ed25519-sk`.
- [ ] Usuario de API propio para Ansible en Warpgate (por ejemplo, `ansible-api`) con un rol de
      administración limitado, para distinguir en la auditoría la automatización del acceso humano.
- [ ] TOTP en el panel web de Warpgate para `admin` (requiere antes el usuario de API para Ansible).
- [ ] Restringir el puerto 22 de las VMs a `core-01` y al equipo de administración, usando la IP fija
      del equipo de administración en NetBird; después, cerrar también el 22 de `core-01` a la LAN.
- [ ] Claves de host fijas para Warpgate (`--import-ssh-host-keys`, cifradas con SOPS) para que su
      huella no cambie al recrear `core-01`.
- [ ] Hook de pre-commit que compruebe que los ficheros de `secrets/` están cifrados con SOPS.
- [ ] Certificado válido para Warpgate (puerto 8888) y `warpgate_api_validate_certs: true`.
- [ ] Usuario SSH dedicado con permisos mínimos para Terraform en Proxmox, en lugar de root.
- [ ] Endurecer el SSH del nodo Proxmox (`PermitRootLogin prohibit-password`, sin contraseñas).
- [ ] Certificado válido en Proxmox y eliminar `PROXMOX_VE_INSECURE`.
- [ ] DNS interno en lugar de sslip.io para los servicios con credenciales (Argo CD, Warpgate…),
      con certificados válidos emitidos por cert-manager.
- [ ] Gestionar IAM Identity Center (usuario, conjuntos de permisos y política `TFG-Terraform`)
      con Terraform; hoy se crearon en la consola.
- [ ] Desactivar y borrar las claves de acceso permanentes del usuario IAM `admin-ngtn`.
- [ ] Sacar la setup key de NetBird del `user_data` de las VMs cloud (por ejemplo, leerla de
      SSM Parameter Store con un rol IAM de la instancia).
- [ ] Rotar el token de Grafana Cloud (caduca a los 90 días; ver [monitorizacion](runbooks/monitorizacion.md)).
- [ ] Descifrar los secretos dentro del clúster (KSOPS o Sealed Secrets) en lugar de crearlos en `bootstrap.sh`.

## Red

- [ ] VPN fase 2: plano de control de NetBird autoalojado en una VM de AWS.
- [ ] Añadir Proxmox y el móvil (app de NetBird + Termux) a la malla, con políticas propias.
- [ ] Gestionar por la API el ajuste *Lazy connections* y borrar equipos antiguos tras `make rebuild` y al recrear VMs cloud.
- [ ] Posible mejora: borrar por la API los peers del grupo `cloud` tras `make destroy ENV=cloud`
      (hoy se borran a mano en el panel).
- [ ] Rotar la setup key y el token de la API de NetBird (caducan a los 60 días).
- [ ] Rotar la setup key de cloud (`cloud-vms`, caduca a los 30 días).
- [ ] Mover los grupos y políticas de NetBird de `inventories/onprem` a un sitio común a todos los entornos.
- [ ] Monitorizar las VMs cloud: política de NetBird del clúster al grupo `cloud` y destinos en Alloy.

## Kubernetes

- [ ] Modo *agent* en el rol `k3s` para unir nodos al clúster: hoy solo instala un servidor
      (ver [añadir-nodo](runbooks/añadir-nodo.md)).
- [ ] Puertos para clúster de varios nodos: `10250/tcp`, `8472/udp` (Flannel) y `2379-2380/tcp` (etcd).
- [ ] Vigilar la política `deny (routed)` de UFW al escalar a varios nodos y al publicar aplicaciones.
- [ ] Renombrar los contextos del kubeconfig (`tfg-onprem`, `tfg-cloud`) cuando exista el clúster cloud.
- [ ] Vigilar la RAM del nodo Proxmox (~1,2 GiB disponibles, medido el 2026-10-13) hasta ampliarlo a 32 GB.
- [ ] Añadir `k3s-01.netbird.cloud` a `--tls-san` de k3s para usar `kubectl` por la VPN fuera de casa.
- [ ] Métricas de Kubernetes (cAdvisor y kubelet) en Alloy, filtradas para no superar el plan Free.

## Automatización y comodidad

- [ ] Fijar las GitHub Actions por SHA en lugar de etiqueta y activar Dependabot para actualizarlas.
- [ ] Validar los manifiestos de `gitops/` en CI (por ejemplo, con kubeconform).
- [ ] Warpgate por API: opción para eliminar los objetos que no estén en `group_vars/core.yml`
      (hoy solo crea lo que falta) y comprobar si admite `scp`/`sftp`.
- [ ] Actualizar `age` a 1.3.2 en el equipo de administración.
- [ ] Versión y huella de NetBird en un solo sitio (hoy, en variables de Terraform y en el rol).
- [ ] Rol `k3s`: la descarga del instalador sale `changed` en `--check`.
- [ ] Panel y alerta de Grafana Cloud como código (provider de Terraform de Grafana); hoy se crean a mano.
- [ ] `make check` con progreso visible (hoy `| tail` no muestra nada hasta el final).

## Copias de seguridad

- [ ] Backend remoto del estado de Terraform (por ejemplo, S3 con versionado y bloqueo): hoy es local
      y no tiene copia.
- [ ] Copia fuera de casa (regla 3-2-1): sincronizar el datastore de PBS con otro destino externo.
- [ ] Configuración de PBS y del almacenamiento `pbs-01` en Proxmox VE como código (Ansible o el
      recurso del provider `bpg/proxmox`); hoy es manual y está documentada.
- [ ] Alerta de "sin copias recientes" (notificaciones de PBS o métrica en Grafana Cloud).
- [ ] Acceso a PBS con clave SSH y sin contraseña de root; certificado válido para su web.
- [ ] Revisar por qué Warpgate queda en `activating` en una VM restaurada sin red.

## Documentación

- [ ] Índice de la memoria del TFG y qué material del repositorio alimenta cada capítulo (en curso).
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
- [x] Documentación al día tras la auditoría: README, mapa, arquitectura, ADR, runbooks y diarios. (2026-10-09, PR #41)
- [x] Revisión del ADR-0003 (Kustomize, `prune`, `selfHeal` y `ServerSideApply`). (2026-10-09, PR #41)
- [x] Contraseña de `admin` de Argo CD declarativa con SOPS: `make rebuild` sin pasos manuales. (2026-10-09, PR #42)
- [x] TOTP en Warpgate para el acceso SSH (clave pública + código), con el secreto cifrado con SOPS. (2026-10-09, PR #43)
- [x] Copia de seguridad de la clave `age` y de la passphrase SSH en el gestor de contraseñas. (2026-10-09)
- [x] Reconstrucción 5: plataforma completa sin pasos manuales en 6 min 33 s. (2026-10-09)
- [x] ADR-0005 y VPN en malla con NetBird (fase 1): cliente en las VMs, equipo de administración y
      políticas por API sin la política Default. (2026-10-10)
- [x] Credenciales de AWS temporales con IAM Identity Center y mínimo privilegio (ADR-0006). (2026-10-11)
- [x] Entorno cloud en AWS: red, VM `cloud-01` sin puertos de entrada y alta en NetBird con cloud-init (ADR-0007). (2026-10-11)
- [x] Inventario cloud generado con `tf-to-inventory.sh` y política de NetBird `admin-a-cloud`. (2026-10-11)
- [x] Rol `common`: agente QEMU solo en VMs de Proxmox. (2026-10-11)
- [x] Makefile con `ENV=cloud`: crear, comprobar y destruir el entorno cloud completo; `ping` espera a que las VMs respondan. (2026-10-12)
- [x] Monitorización: `node_exporter` en las VMs, Grafana Alloy en el clúster y métricas en Grafana Cloud (ADR-0008). (2026-10-12)
- [x] Panel *Node Exporter Full* y alerta "VM sin métricas" por Telegram, probada con caída y recuperación. (2026-10-13)
- [x] Proxmox Backup Server en `pbs-01` con token de mínimo privilegio, copias diarias cifradas,
      retención, limpieza y verificación (ADR-0009). (2026-10-13)
- [x] Prueba de restauración: `core-01` desde PBS en 1 min 19 s, con los datos de Warpgate. (2026-10-13)
- [x] Velero descartado y Loki replanteado como logs hacia Grafana Cloud. (2026-10-13)
- [x] Revisión de la documentación: arquitectura, README, mapa y runbook de restauración. (2026-10-13)
