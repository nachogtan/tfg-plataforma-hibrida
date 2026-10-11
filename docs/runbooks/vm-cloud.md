---
title: "Runbook: VMs cloud (crear, configurar, recrear y destruir)"
tags: [runbook, aws, cloud, terraform, ansible, netbird]
---

# Runbook: VMs cloud (crear, configurar, recrear y destruir)

↑ [Mapa del repositorio](../README.md) · Decisión: [ADR-0007](../adr/0007-vm-cloud-sin-puertos-entrada.md)

Las VMs cloud no tienen puertos de entrada: se administran solo por NetBird. Todos los comandos se
ejecutan desde la raíz del repositorio en el equipo de administración.

## Requisitos

- Sesión SSO activa con el perfil `tfg` (dura 2 horas):

```bash
  aws sso login --profile tfg --no-browser
```

- Clave de age para SOPS en `~/.config/sops/age/keys.txt`.
- El equipo de administración conectado a NetBird (`netbird status`).

> [!NOTE]
> La setup key de cloud se descifra con SOPS solo para el comando que la usa (`TF_VAR_...="$(sops ...)"`):
> no queda en la shell ni en el historial. No se usa `plan -out`: el fichero de plan la guardaría en claro.

## 1. Crear la VM

```bash
TF_VAR_netbird_setup_key="$(sops -d --extract '["netbird_setup_key_cloud"]' secrets/netbird.sops.yaml)" \
  terraform -chdir=terraform/envs/cloud apply
```

En 1–2 minutos cloud-init instala NetBird y la VM aparece en el panel de NetBird (grupo `cloud`).

## 2. Comprobar el acceso

```bash
ssh admin@cloud-01.netbird.cloud 'hostname; cloud-init status --wait'
```

Esperado: `cloud-01` y `status: done`.

## 3. Generar el inventario y configurar con Ansible

```bash
scripts/tf-to-inventory.sh cloud
(cd ansible && ansible-playbook -i inventories/cloud playbooks/site.yml --diff)
```

En la primera pasada cambian `common` y `hardening`; el rol `netbird` queda sin cambios porque
cloud-init ya lo dejó igual. Una segunda pasada debe dar `changed=0`.

> [!NOTE]
> `--check` no llega al final en una VM nueva: UFW no se instala en simulación y la tarea siguiente falla.

## 4. Recrear la VM desde cero

1. Borrar el peer `cloud-01` en el panel de NetBird (**Peers** → seleccionar → **Delete**).
   Si no, la VM nueva se registra con otro nombre (`cloud-01-xxxx`).
2. Reemplazar la instancia:

```bash
   TF_VAR_netbird_setup_key="$(sops -d --extract '["netbird_setup_key_cloud"]' secrets/netbird.sops.yaml)" \
     terraform -chdir=terraform/envs/cloud apply -replace=module.cloud_01.aws_instance.this
```

3. Cuando aparezca en NetBird, olvidar la clave de host vieja y vaciar la caché DNS:

```bash
   ssh-keygen -R cloud-01.netbird.cloud
   resolvectl flush-caches
```

4. Seguir con los pasos 2 y 3.

## 5. Destruir la VM

```bash
TF_VAR_netbird_setup_key="$(sops -d --extract '["netbird_setup_key_cloud"]' secrets/netbird.sops.yaml)" \
  terraform -chdir=terraform/envs/cloud destroy -target=module.cloud_01
```

Después, borrar el peer `cloud-01` en el panel de NetBird. La red (VPC, subred, security group) se
mantiene; para borrarla también, `destroy` sin `-target`.

> [!WARNING]
> Comprobar que no quedan discos ni IPs elásticas sueltos:
> `aws ec2 describe-volumes --profile tfg --query 'Volumes[].VolumeId'` y
> `aws ec2 describe-addresses --profile tfg --query 'Addresses[].PublicIp'` deben devolver `[]`.

## Problemas frecuentes

| Síntoma | Causa | Solución |
|---|---|---|
| `No route to host` con el peer `Connected` | La caché DNS da la IP de la VM anterior | `resolvectl flush-caches` |
| `REMOTE HOST IDENTIFICATION HAS CHANGED` | VM nueva, clave de host nueva | `ssh-keygen -R cloud-01.netbird.cloud` |
| `Could not resolve hostname` | La VM aún no se ha unido a la malla | Esperar 1–2 minutos y revisar el panel de NetBird |
| `--limit localhost` sin hosts | `localhost` es implícito y no está en el inventario | Lanzar el playbook sin `--limit` |
| Todo "acceso denegado" en la consola con `TFG-Terraform` | Región distinta de `eu-south-2` | Cambiar la región arriba a la derecha |

> [!TIP]
> Fuera de la LAN de casa, on-prem también se administra por la VPN:
> `ansible-playbook ... -e 'ansible_host={{ inventory_hostname }}.netbird.cloud'`.
