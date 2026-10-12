---
title: "Runbook: entorno cloud (crear, configurar, recrear y destruir)"
tags: [runbook, aws, cloud, terraform, ansible, netbird, make]
---

# Runbook: entorno cloud (crear, configurar, recrear y destruir)

↑ [Mapa del repositorio](../README.md) · Decisión: [ADR-0007](../adr/0007-vm-cloud-sin-puertos-entrada.md)

El entorno cloud (red y VMs en AWS) es efímero: se crea entero cuando hace falta y se destruye entero
después. Las VMs no tienen puertos de entrada; se administran solo por NetBird. Se usan los mismos
objetivos del Makefile que en on-prem, con `ENV=cloud`, desde la raíz del repositorio.

## Requisitos

- Sesión SSO activa con el perfil `tfg` (dura 2 horas):

```bash
  aws sso login --profile tfg --no-browser
```

- Clave de age para SOPS en `~/.config/sops/age/keys.txt`.
- El equipo de administración conectado a NetBird (`netbird status`).

> [!NOTE]
> Con `ENV=cloud`, el Makefile no carga `.env` (credenciales de Proxmox) y descifra la setup key de
> NetBird con SOPS solo para cada comando de Terraform (`TF_VAR_netbird_setup_key`).

## 1. Crear y configurar

```bash
make deploy ENV=cloud
```

Ejecuta, en orden:

1. `apply`: crea la red y las VMs (pide confirmación).
2. `inventory`: genera `ansible/inventories/cloud/hosts.yml`, olvida las huellas SSH antiguas y vacía
   la caché DNS.
3. `ping`: espera hasta 5 minutos a que cada VM se una a NetBird y acepte SSH.
4. `configure`: aplica `site.yml` por la VPN.

En la primera pasada cambian `common` y `hardening`; el rol `netbird` queda sin cambios porque
cloud-init ya lo dejó igual.

## 2. Comprobar la idempotencia

```bash
make check ENV=cloud
```

Esperado: `No changes` en Terraform y `changed=0` en todas las VMs.

## 3. Destruir

```bash
make destroy ENV=cloud
```

Borra todo el entorno cloud (VMs y red). Después:

1. Borrar los peers de las VMs cloud en el panel de NetBird (**Peers** → seleccionar → **Delete**).
   Si no, al volver a crear una VM se registra con otro nombre (`cloud-01-xxxx`).
2. Comprobar que no queda nada del proyecto en AWS (las tres deben devolver `[]`):

```bash
   aws ec2 describe-vpcs --profile tfg --filters Name=tag:proyecto,Values=tfg-plataforma-hibrida --query 'Vpcs[].VpcId'
   aws ec2 describe-volumes --profile tfg --query 'Volumes[].VolumeId'
   aws ec2 describe-addresses --profile tfg --query 'Addresses[].PublicIp'
```

## 4. Recrear desde cero

Borrar los peers en NetBird (paso 3.1) y después:

```bash
make rebuild ENV=cloud
```

## Problemas frecuentes

| Síntoma | Causa | Solución |
|---|---|---|
| `No route to host` con el peer `Connected` | La caché DNS da la IP de la VM anterior | `resolvectl flush-caches` (`make inventory ENV=cloud` ya lo hace) |
| `REMOTE HOST IDENTIFICATION HAS CHANGED` | VM nueva, clave de host nueva | `ssh-keygen -R cloud-01.netbird.cloud` (`make inventory ENV=cloud` ya lo hace) |
| `make ping` agota los 5 minutos | La VM no se ha unido a la malla (peer viejo sin borrar, setup key caducada o sin usos) | Revisar el panel de NetBird y la setup key `cloud-vms` |
| `ExpiredToken` o `Token has expired` | La sesión SSO ha caducado (2 h) | `aws sso login --profile tfg --no-browser` |
| Todo "acceso denegado" en la consola | Región distinta de `eu-south-2` | Cambiar la región arriba a la derecha |

> [!NOTE]
> `ansible-playbook --check` no llega al final en una VM nueva: UFW no se instala en simulación y la
> tarea siguiente falla. Es una limitación del modo check.

> [!TIP]
> Fuera de la LAN de casa, on-prem también se administra por la VPN:
> `ansible-playbook ... -e 'ansible_host={{ inventory_hostname }}.netbird.cloud'`.
