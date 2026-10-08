---
title: "Runbook: Configuración inicial"
tags: [runbook, proxmox, prerrequisitos]
---

# Runbook: Configuración inicial

↑ [Mapa del repositorio](../README.md) · Siguiente: [puesta-en-marcha](puesta-en-marcha.md)

Pasos manuales que se realizan **una sola vez** antes del primer despliegue.

## 0. Requisitos previos

### 0.1 Equipo de administración

Herramientas necesarias: `git`, `terraform`, `ansible`, `kubectl`, `sops`, `age`, `make`, `pre-commit` y `podman`.

En Fedora:

```bash
sudo dnf install git ansible make pre-commit
```

> Terraform, kubectl, SOPS y age se instalan desde sus repositorios oficiales.

Tras clonar el repositorio, activar pre-commit (se guarda en `.git/hooks/`, que no se versiona,
por lo que hay que repetirlo en cada clon):

```bash
pre-commit install
pre-commit run --all-files
```

Variable para usar el clúster con `kubectl` (se recomienda añadirla a `~/.bashrc`):

```bash
export KUBECONFIG=~/.kube/tfg-onprem.yaml
```

### 0.2 Proxmox VE

- Proxmox VE 9.x instalado y accesible por red.
- Almacenamiento `local` con los tipos de contenido `import` (imágenes cloud) y `snippets`
  (configuración de cloud-init):
```bash
  pvesh set /storage/local --content iso,vztmpl,backup,import,snippets
```
  > `--content` sustituye la lista completa: incluir siempre los tipos existentes.
- Almacenamiento `local-lvm` con el tipo de contenido `images` (para los discos de las VMs).
- Bridge `vmbr0` activo y conectado a la red local.
- Acceso SSH como root con clave desde el equipo de administración. El provider de Terraform lo usa
  para subir snippets (la API de Proxmox no lo permite). La clave debe estar cargada con `ssh-add`.
  > Mejora pendiente: usuario SSH dedicado con permisos mínimos.

Verificación en el nodo:

```bash
cat /etc/pve/storage.cfg
ip -br addr | grep vmbr
```

En `storage.cfg`, la línea `content` de `local` debe incluir `import` y `snippets`.

Verificación del acceso SSH desde el equipo de administración:

```bash
ssh root@192.168.1.90 "hostname"
```

Debe responder con el nombre del nodo sin pedir contraseña (más allá de la de la clave, si no está cargada).

```bash
cat /etc/pve/storage.cfg
ip -br addr | grep vmbr
```

### 0.3 Red

| Elemento | Valor |
|---|---|
| Red | `192.168.1.0/24` |
| Puerta de enlace | `192.168.1.1` |
| Nodo Proxmox | `192.168.1.90` |
| Bloque reservado para la plataforma | `192.168.1.100` – `192.168.1.119` |
| Rango DHCP del router | a partir de `192.168.1.120` |

Las VMs usan IP fija dentro del bloque reservado. Antes de asignar una IP nueva, comprobar que está libre:

```bash
ping -c 2 -W 1 <IP>
```

## 1. Usuario y token de API para Terraform

Terraform se conecta a Proxmox mediante su API con un usuario dedicado y un token,
con los permisos mínimos necesarios para crear y gestionar máquinas virtuales.

**Probado en:** Proxmox VE 9.2

### 1.1 En el nodo Proxmox (como root, por SSH o consola)

Crear el rol con los privilegios necesarios:

```bash
pveum role add TerraformProv -privs "Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit Pool.Audit SDN.Audit SDN.Use Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.PowerMgmt VM.GuestAgent.Audit"
```

> En Proxmox VE 9 ya no existe `VM.Monitor`; se sustituye por `VM.GuestAgent.Audit`.
> En Proxmox VE 8, usar `VM.Monitor` en su lugar.

Crear el usuario (sin contraseña: solo se usará mediante token):

```bash
pveum user add terraform-prov@pve --comment "Usuario de servicio para Terraform"
```

Asignar el rol al usuario sobre toda la jerarquía (`/`):

```bash
pveum aclmod / -user terraform-prov@pve -role TerraformProv
```

Crear el token de API sin separación de privilegios (hereda los permisos del usuario):

```bash
pveum user token add terraform-prov@pve terraform --privsep 0
```

> El secreto (`value`) solo se muestra una vez. Guardarlo directamente en `.env`
> (ver 1.2). Nunca debe subirse al repositorio ni compartirse.

### 1.2 En el equipo de administración

Crear `.env` en la raíz del repositorio (con el usuario normal, sin `sudo`):

```bash
export PROXMOX_VE_ENDPOINT="https://<IP_PROXMOX>:8006/"
export PROXMOX_VE_API_TOKEN="terraform-prov@pve!terraform=<SECRETO>"
export PROXMOX_VE_INSECURE=true
```

> `PROXMOX_VE_INSECURE=true` es necesario mientras Proxmox use su certificado
> autofirmado. Mejora pendiente: certificado válido y eliminar esta variable.
> El token debe incluir sus tres partes: `usuario@realm!id_token=secreto`.
> Si solo se pone el secreto, Terraform devuelve `the API token must be in the format 'USER@REALM!TOKENID=UUID'`.

Proteger el archivo, comprobar que Git lo ignora y cargar las variables:

```bash
chmod 600 .env
git check-ignore .env      # debe devolver: .env
source .env
```

### 1.3 Verificación

En el nodo Proxmox:

```bash
pveum role list | grep TerraformProv
pveum acl list | grep terraform-prov
pveum user token permissions terraform-prov@pve terraform
```

Resultado esperado: el rol con los privilegios listados, la ACL sobre `/` con
propagación (`1`) y los permisos efectivos del token.

### 1.4 Revocación o rotación del token

Si el token se compromete o se quiere renovar:

```bash
pveum user token remove terraform-prov@pve terraform
pveum user token add terraform-prov@pve terraform --privsep 0
```

Actualizar después el secreto en `.env`.

### 1.5 Permisos sobre el almacenamiento de imágenes

Terraform necesita borrar imágenes del almacenamiento `local` al ejecutar `destroy`
(`Datastore.Allocate`). Ese permiso se concede **solo en esa ruta**, no en todo Proxmox:

```bash
pveum role add TerraformStorage -privs "Datastore.Allocate Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit"
pveum aclmod /storage/local -user terraform-prov@pve -role TerraformStorage
```

Verificación:

```bash
pveum user permissions terraform-prov@pve --path /storage/local | grep Datastore
```

Deben aparecer cuatro permisos, incluido `Datastore.Allocate`.

## Relacionado

- Siguiente paso: [puesta-en-marcha](puesta-en-marcha.md)
- Diario: [2026-10-01](../diario/2026-10-01.md)
- Diario: [2026-10-01](../diario/2026-10-01.md) · [2026-10-02](../diario/2026-10-02.md)
