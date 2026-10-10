---
title: "Runbook: VPN en malla con NetBird"
tags: [runbook, vpn, netbird, seguridad]
---

# Runbook: VPN en malla con NetBird

↑ [Mapa del repositorio](../README.md) · [arquitectura](../arquitectura.md) · Decisión: [0005-vpn-netbird](../adr/0005-vpn-netbird.md)

NetBird une las VMs y el equipo de administración en una red privada cifrada (WireGuard), sin
abrir puertos en el router. Fase 1: plano de control en NetBird Cloud; clientes en versión fijada.

- **VMs:** rol de Ansible [netbird](../../ansible/roles/netbird/) (cliente 0.80.0, setup key cifrada con SOPS).
- **Grupos y políticas:** [group_vars/all.yml](../../ansible/inventories/onprem/group_vars/all.yml),
  aplicados por la API con [tasks/api.yml](../../ansible/roles/netbird/tasks/api.yml) (usuario de servicio
  `ansible`, rol Network Admin).
- **Todo lo que no permita una política está denegado.** Hoy: `admin` → `onprem` en TCP 22, 80, 443,
  2222, 6443 y 8888. Las VMs no se ven entre sí por la malla (usan la LAN).

## Prerrequisitos

- Clave `age` para descifrar [secrets/netbird.sops.yaml](../../secrets/netbird.sops.yaml)
  (`netbird_setup_key` y `netbird_api_token`).
- En la cuenta de NetBird, **Lazy connections desactivado** (ajuste manual del panel: con él activo,
  los túneles se quedaban en `Idle`).

## Añadir una VM

Automático: al crearla con Terraform, `make deploy` ejecuta `site.yml`, que instala el cliente y la
registra con la setup key en el grupo `onprem`.

## Añadir el equipo de administración (Fedora)

1. Repositorio y paquete (fuera del repo, con `sudo`):
```bash
   sudo tee /etc/yum.repos.d/netbird.repo > /dev/null <<'REPO'
   [netbird]
   name=netbird
   baseurl=https://pkgs.netbird.io/yum/
   enabled=1
   gpgcheck=1
   gpgkey=https://pkgs.netbird.io/yum/repodata/repomd.xml.key
   repo_gpgcheck=1
   REPO
   sudo dnf install netbird-0.80.0
```
   Huella esperada de la clave RPM: `AA9C 09AA 9DEA 2F58 112B 40DF DFFE AB2F D267 A61F` (Wiretrustee).
   La del repositorio Debian es otra: `EFE3 7DF0 47DF 7CCD F1FC 54FA 83F7 9AD0 2977 8355`.
2. Registro con la cuenta personal (abre el navegador): `netbird up`.
3. Añadir su nombre de equipo al grupo `admin` en `group_vars/all.yml` y aplicar:
   `cd ansible && ansible-playbook playbooks/netbird.yml`.

## Cambiar grupos o políticas

Editar `group_vars/all.yml` y ejecutar `ansible-playbook playbooks/netbird.yml` (desde `ansible/`).
Una segunda ejecución debe dar `changed=0`. No se cambian en el panel.

## Rotación de credenciales (cada 60 días)

- **Setup key:** crear una nueva en el panel (reutilizable, 20 usos, 60 días, grupo `onprem`) y
  sustituirla en `secrets/netbird.sops.yaml` con `read -rsp` + `sops encrypt` (nunca por el portapapeles
  ni en la pantalla). Las VMs ya registradas no la necesitan.
- **Token de la API:** crear uno nuevo para el usuario de servicio `ansible` y sustituirlo igual.

## Verificación

```bash
netbird status | grep -E "Management|Peers count"                     # Connected
timeout 3 bash -c '</dev/tcp/k3s-01.netbird.cloud/22' && echo abierto  # permitido por la política
```

## Problemas frecuentes

| Síntoma | Causa | Solución |
|---|---|---|
| Peer en `Status: Idle`, sin conexión | *Lazy connections* activo | Desactivarlo en el panel |
| `Name or service not known` para otro equipo | Ninguna política permite esa conexión | Es lo esperado; añadir política si hace falta |
| `ping` falla pero TCP funciona | Las políticas solo permiten TCP en puertos concretos | Comprobar con `/dev/tcp` |
| Equipos duplicados tras `make rebuild` | Cada VM nueva se registra como un equipo nuevo | Borrar los antiguos en el panel (pendiente automatizar) |

## Limitaciones

- Plano de control en NetBird Cloud: conoce los metadatos de la red, no el tráfico.
- *Lazy connections* y la limpieza de equipos antiguos se gestionan a mano.
- En modo `--check` no se aplica la parte de la API.
