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
