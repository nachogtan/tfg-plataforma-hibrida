---
title: "ADR-0009: Copias de seguridad con Proxmox Backup Server"
estado: Aceptado
fecha: 2026-10-13
tags: [adr, backups, proxmox, pbs, seguridad]
---

# ADR-0009: Copias de seguridad con Proxmox Backup Server

↑ [Mapa del repositorio](../README.md) · [arquitectura](../arquitectura.md)

**Estado:** Aceptado · **Fecha:** 2026-10-13

## Contexto

La plataforma se reconstruye desde el código (Terraform + Ansible + GitOps), lo que recupera la
**configuración** pero no los **datos**. Hay datos que no están en Git: la base de datos y las
grabaciones de sesiones de Warpgate (`core-01`) y el estado de Terraform. El nodo Proxmox no tiene
RAM libre para más servicios, pero hay un portátil disponible (i7 de 6.ª generación, 8 GB, HDD de 1 TB).

## Opciones consideradas

| Opción | Ventajas | Inconvenientes |
|---|---|---|
| **Proxmox Backup Server en el portátil** | Integración nativa con Proxmox VE; copias incrementales con deduplicación; cifrado en el cliente; otro hardware | Sigue en la misma casa; HDD (lento en verificación) |
| Copias `vzdump` a un disco o NFS | Sencillo | Sin deduplicación ni cifrado integrado; copias completas cada vez |
| Velero en el clúster | Copias de recursos de Kubernetes | El estado del clúster ya está en Git; no protege las VMs ni Warpgate |
| Solo reconstrucción desde código | Ya implementado | No recupera datos |

## Decisión

- **Proxmox Backup Server 4.2** en el portátil `pbs-01` (`192.168.1.91`), datastore `backup-tfg`
  en ext4.
- **Mínimo privilegio:** usuario `pve@pbs` y token `pve@pbs!pve-backup` con el único rol
  `DatastoreBackup` sobre el datastore: puede crear copias y leer las suyas, pero **no borrarlas**.
- **Cifrado en el cliente:** Proxmox VE cifra las copias antes de enviarlas; PBS solo guarda datos
  ilegibles. La clave y el token se guardan cifrados en `secrets/pbs.sops.yaml` y en el gestor de
  contraseñas.
- **Trabajo diario** (21:00, modo *snapshot*) de `core-01` y `k3s-01`. PBS aplica la retención
  (3 últimas + 7 diarias), la limpieza diaria y una verificación (cada copia, como mucho una vez al mes).
- **Configuración manual** (web de Proxmox VE y CLI de PBS), documentada en el runbook.
- **Velero descartado:** el estado del clúster se reconstruye desde Git y las VMs se copian enteras.
- Dos estrategias de recuperación complementarias: **reconstruir** (configuración) y **restaurar** (datos).
- **Estado de Terraform local** (decisión consciente, fuera del alcance del TFG): perderlo no supone
  perder datos. En cloud el entorno es efímero (destruido, el estado queda vacío) y en on-prem las
  VMs se recrean con `make deploy` (~6 min) tras borrarlas en Proxmox; los datos están en PBS. En
  producción se usaría un backend remoto: bucket S3 privado con versionado y bloqueo (`use_lockfile`).

## Consecuencias

- ✅ Verificado: copias cifradas con la clave guardada (huella `f0:da:…:3a:13`); `core-01` restaurada
  como VM nueva en 1 min 19 s, con los datos de Warpgate intactos.
- ✅ Un atacante con acceso a Proxmox VE no puede borrar las copias con el token.
- ⚠ Todas las copias están en la misma casa (sin copia externa de la regla 3-2-1).
- ⚠ Las copias solo se hacen si el portátil está encendido a la hora programada.
- ⚠ HDD: la verificación y la limpieza son lentas con mucho volumen.
- ⚠ Sin la clave de cifrado las copias no se pueden restaurar: hay dos copias de la clave (SOPS y
  gestor de contraseñas).
- ⚠ La configuración de PBS y del almacenamiento en Proxmox VE no está como código.
- ⚠ El estado de Terraform es local y sin copia; su pérdida se resuelve recreando (ver [restauracion](../runbooks/restauracion.md), escenario E).

## Relacionado

- ADR: [0004-gestion-secretos-sops](0004-gestion-secretos-sops.md)
- Runbook: [backups](../runbooks/backups.md)
