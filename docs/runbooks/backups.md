---
title: "Runbook: copias de seguridad con Proxmox Backup Server"
tags: [runbook, backups, proxmox, pbs]
---

# Runbook: copias de seguridad con Proxmox Backup Server

↑ [Mapa del repositorio](../README.md) · Decisión: [ADR-0009](../adr/0009-copias-pbs.md)

| Pieza | Valor |
|---|---|
| Servidor de copias | `pbs-01`, `192.168.1.91` (web: `https://192.168.1.91:8007`) |
| Datastore | `backup-tfg` (`/backup-tfg`) |
| Almacenamiento en Proxmox VE | `pbs-01` (token `pve@pbs!pve-backup`, cifrado, *keep all*) |
| Trabajo de copia | Diario a las 21:00, VMs 100 y 101, modo *snapshot* |
| Mantenimiento en PBS | Retención 3 últimas + 7 diarias; limpieza diaria; verificación 21:30 (cada copia como mucho cada 30 días) |
| Secretos | `secrets/pbs.sops.yaml` (`pbs_token_id`, `pbs_token_secret`, `pbs_encryption_key`) y gestor de contraseñas |

> [!CAUTION]
> Sin la **clave de cifrado** las copias no se pueden restaurar. Está en `secrets/pbs.sops.yaml` y en
> el gestor de contraseñas; no borrar ninguna de las dos.

## 1. Instalación de PBS (una vez)

1. Instalar desde la ISO oficial: disco completo, **ext4**, hostname `pbs-01`, IP `192.168.1.91/24`.
2. Repositorios: en *Administration → Repositories*, desactivar `pbs-enterprise` y añadir
   **No-Subscription**.
3. Actualizar por SSH (la consola web puede verse con artefactos en Firefox):

```bash
   ssh -t root@192.168.1.91 'apt update && apt full-upgrade'
```

   Reiniciar si se instala un kernel nuevo.
4. Datastore: *Datastore → Add Datastore*: nombre `backup-tfg`, ruta `/backup-tfg`, GC `daily`.

## 2. Usuario y token de mínimo privilegio

```bash
ssh root@192.168.1.91 'proxmox-backup-manager user create pve@pbs --comment "Proxmox VE: copias de las VMs del TFG" \
  && proxmox-backup-manager acl update /datastore/backup-tfg DatastoreBackup --auth-id pve@pbs'
```

El token se genera y se cifra con SOPS sin mostrarse (el secreto solo aparece una vez):

```bash
set -o pipefail; ssh root@192.168.1.91 'proxmox-backup-manager user generate-token pve@pbs pve-backup \
  && proxmox-backup-manager acl update /datastore/backup-tfg DatastoreBackup --auth-id "pve@pbs!pve-backup"' \
  | tr -d '\n' | grep -o '{.*}' | jq '{pbs_token_id: .tokenid, pbs_token_secret: .value}' \
  | sops -e --filename-override secrets/pbs.sops.yaml --input-type json --output-type yaml /dev/stdin > secrets/pbs.sops.yaml
set +o pipefail
```

Comprobar que el token solo tiene `Datastore.Backup`:

```bash
ssh root@192.168.1.91 'proxmox-backup-manager user permissions "pve@pbs!pve-backup" --path /datastore/backup-tfg'
```

## 3. Almacenamiento en Proxmox VE

1. Huella del certificado de PBS: `ssh root@192.168.1.91 'proxmox-backup-manager cert info | grep -i fingerprint'`.
2. *Datacenter → Storage → Add → Proxmox Backup Server*: ID `pbs-01`, server `192.168.1.91`,
   username `pve@pbs!pve-backup`, password = secreto del token
   (`sops -d --extract '["pbs_token_secret"]' secrets/pbs.sops.yaml`), datastore `backup-tfg`,
   huella del paso 1. En *Backup Retention*: **Keep all backups** (la retención la hace PBS; el token
   no puede borrar).
3. Clave de cifrado, generada en el nodo y copiada a SOPS sin mostrarla:

```bash
   ssh root@192.168.1.90 'pvesm set pbs-01 --encryption-key autogen >/dev/null'
   set -o pipefail; { sops -d --output-type json secrets/pbs.sops.yaml; ssh root@192.168.1.90 'cat /etc/pve/priv/storage/pbs-01.enc'; } \
     | jq -s '.[0] + {pbs_encryption_key: (.[1] | tojson)}' \
     | sops -e --filename-override secrets/pbs.sops.yaml --input-type json --output-type yaml /dev/stdin > secrets/pbs.sops.yaml.tmp \
     && mv secrets/pbs.sops.yaml.tmp secrets/pbs.sops.yaml; set +o pipefail
```

   Comprobar que la huella de la copia coincide con la del nodo
   (`proxmox-backup-client key show /etc/pve/priv/storage/pbs-01.enc`) y guardar el JSON completo
   de la clave también en el gestor de contraseñas.

## 4. Trabajo de copia y mantenimiento

- Proxmox VE: *Datacenter → Backup → Add*: storage `pbs-01`, schedule `21:00`, VMs 100 y 101,
  mode *Snapshot*.
- PBS (retención y verificación):

```bash
  ssh root@192.168.1.91 'proxmox-backup-manager prune-job update <id-de-la-tarea> --keep-last 3 --keep-daily 7 \
    && proxmox-backup-manager verify-job create verify-backup-tfg --store backup-tfg --schedule "21:30" \
       --ignore-verified true --outdated-after 30'
```

  El id de la tarea de retención se ve con `proxmox-backup-manager prune-job list`.

## 5. Comprobar las copias

Copia inmediata: seleccionar el trabajo en *Datacenter → Backup* y pulsar **Run now**.

Listar las copias y la clave con la que están cifradas (debe ser `f0:da:…:3a:13`):

```bash
ssh root@192.168.1.90 'pvesh get /nodes/ngtn-server/storage/pbs-01/content --output-format json' \
  | jq -r '.[] | [.volid, .encrypted] | @tsv'
```

## 6. Probar una restauración (sin tocar la VM original)

Se restaura como VM nueva **sin red**, para que no choque con la IP ni con la identidad de NetBird
de la original, y se comprueba con el agente QEMU:

```bash
ssh root@192.168.1.90 'time qmrestore pbs-01:backup/vm/100/<fecha> 900 --storage local-lvm --unique 1 \
  && qm set 900 --delete net0 --name core-01-restore --onboot 0 && qm start 900'
# esperar 2-3 minutos (sin red, el arranque espera a la red antes de rendirse)
ssh root@192.168.1.90 'qm agent 900 ping && qm guest exec 900 -- ls /var/lib/warpgate'
ssh root@192.168.1.90 'qm stop 900 && qm destroy 900 --purge'
```

Resultado del 2026-10-13: restauración en **1 min 19 s**; `/var/lib/warpgate` con `db`,
`recordings` y certificados.

## 7. Recuperación ante desastre (nodo Proxmox nuevo)

1. Añadir el almacenamiento `pbs-01` como en el apartado 3 y, en *Encryption*, **subir la clave
   existente** (la de `secrets/pbs.sops.yaml` o la del gestor de contraseñas). No generar una nueva:
   las copias anteriores no se podrían leer.
2. Restaurar cada VM con su ID original desde *pbs-01 → Backups → Restore*.

## Problemas frecuentes

| Síntoma | Causa | Solución |
|---|---|---|
| Consola web de PBS/Proxmox con artefactos de colores | Dibujo de xterm.js con aceleración gráfica en Firefox | Usar SSH, o desactivar la aceleración por hardware de Firefox |
| `REMOTE HOST IDENTIFICATION HAS CHANGED` al entrar en PBS | Claves de host nuevas tras reinstalar | Verificar la huella en la consola de la máquina y `ssh-keygen -R 192.168.1.91` |
| `generate-token`: `'output-format': schema does not allow additional properties` | El comando no admite esa opción | Extraer el JSON de la salida (`tr -d '\n' \| grep -o '{.*}'`) |
| La tarea de retención no borra nada | Creada sin reglas `keep-*` | `prune-job update ... --keep-last 3 --keep-daily 7` |
| No aparece `pbs-01.enc` tras elegir *Auto-generate* en la web | El cambio no se guardó | `pvesm set pbs-01 --encryption-key autogen` |
| `QEMU guest agent is not running` en la VM restaurada | Sin red, el arranque espera a la red (~2 min) | Esperar y repetir |
| La VM restaurada se llama `core-01-restore` y Warpgate queda en `activating` | Instancia nueva para cloud-init y sin red | Esperado en la prueba; en una restauración real (mismo ID y red) no ocurre |
| El trabajo de las 21:00 falla | `pbs-01` apagado | Encender el portátil y lanzar *Run now* |
