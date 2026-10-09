---
title: "Runbook: Acceso SSH por Warpgate"
tags: [runbook, warpgate, seguridad]
---

# Runbook: Acceso SSH por Warpgate

↑ [Mapa del repositorio](../README.md) · [arquitectura](../arquitectura.md)

Warpgate (`core-01`, `192.168.1.110`) es el punto de entrada SSH **humano** a las VMs: autentica
al usuario, comprueba sus roles, se conecta al destino con su propia clave y graba la sesión.
El acceso humano es para diagnóstico y emergencias; los cambios se hacen por Git.
Ansible no pasa por Warpgate: usa SSH directo al puerto 22 desde el equipo de administración.

| Puerto | Uso |
|---|---|
| `2222/tcp` | SSH de los usuarios hacia los destinos |
| `8888/tcp` | Panel web: `https://192.168.1.110:8888/@warpgate/admin` |

## Prerrequisitos

- Clave privada del usuario cargada en el agente (`ssh-add -l`).
- Para cambios de configuración: clave `age` en `~/.config/sops/age/keys.txt` (descifra
  [secrets/warpgate.sops.yaml](../../secrets/warpgate.sops.yaml)).

## Uso diario

Autenticación: **clave pública + código TOTP** de 6 dígitos (app de autenticación del móvil).
Warpgate pide el código tras validar la clave (`One-time password:`).

1. Entrar a una VM (el usuario de Warpgate y el destino van separados por `:`):
```bash
   ssh -p 2222 'ngtn:k3s-01@192.168.1.110'
```
2. Ejecutar un comando suelto:
```bash
   ssh -p 2222 'ngtn:k3s-01@192.168.1.110' 'hostname; whoami'
```
3. Opcional, alias en `~/.ssh/config` del equipo personal:
```
   Host k3s-01
       HostName 192.168.1.110
       Port 2222
       User ngtn:k3s-01
```
4. Consultar sesiones y grabaciones: panel → **Status → Sessions**.

## Cambiar la configuración (usuarios, claves, roles)

La configuración de Warpgate es código: [group_vars/core.yml](../../ansible/inventories/onprem/group_vars/core.yml),
aplicada por la API con [tasks/api.yml](../../ansible/roles/warpgate/tasks/api.yml).
**No se cambia en el panel**: lo creado a mano no está en Git y se pierde al reconstruir.

1. Rama nueva y editar `warpgate_users` o `warpgate_access_roles` en `group_vars/core.yml`.
2. Aplicar y comprobar la idempotencia:
```bash
   make configure
   make check        # changed=0
```
3. PR a `main`.

Las VMs nuevas (`terraform.tfvars` + `make deploy`) aparecen solas como destinos con el rol `infra`
y su huella registrada.

## Contraseña de admin del panel

```bash
sops decrypt --extract '["warpgate_admin_password"]' secrets/warpgate.sops.yaml | wl-copy
```

Pegarla en el navegador y vaciar el portapapeles con `wl-copy --clear`. Tras 5 intentos fallidos,
Warpgate bloquea el usuario temporalmente (panel → **Login protection**).

## Tras recrear `core-01`

`make inventory ping configure` reinstala Warpgate y lo reconfigura por la API (~1 min). La clave de
host de Warpgate cambia, así que hay que borrar la huella antigua del puerto 2222 en el equipo:

```bash
ssh-keygen -R '[192.168.1.110]:2222'
```

## Problemas frecuentes

| Síntoma | Causa | Solución |
|---|---|---|
| `Received disconnect … 11` | Huella del destino desconocida y sin terminal para preguntar | Ejecutar `make configure` (registra las huellas) o conectar una vez en modo interactivo |
| `REMOTE HOST IDENTIFICATION HAS CHANGED` en el 2222 | `core-01` recreada | `ssh-keygen -R '[192.168.1.110]:2222'` |
| `Permission denied` | Clave no registrada, rol que falta o IP fuera de `allowed_ip_ranges` | Revisar `group_vars/core.yml` y `make configure` |
| Código TOTP rechazado (vuelve a pedirlo) | Código caducado o reloj del móvil desincronizado | Esperar al siguiente código; activar la hora automática en el móvil |
| Diagnóstico general | — | `ssh admin@192.168.1.110 'sudo journalctl -u warpgate -n 30'` |

## Verificación

```bash
ssh -p 2222 'ngtn:k3s-01@192.168.1.110' 'hostname; whoami'   # k3s-01 / admin
make check                                                     # changed=0
```

## Limitaciones conocidas

- La configuración por API crea lo que falta, pero **no borra** lo que sobra.
- Se omite en modo `--check` (una API no se puede simular).
- El secreto TOTP se crea por la API solo si el usuario no tiene ninguno: la API no devuelve el
  secreto, así que no se puede comparar con el de SOPS.

## TOTP: alta, pérdida del móvil y rotación

- **Alta de un usuario:** generar su secreto `warpgate_totp_<usuario>` en
  [secrets/warpgate.sops.yaml](../../secrets/warpgate.sops.yaml), registrarlo en la app (QR con
  `qrencode -t ansiutf8`), poner `totp: true` y `ssh: [PublicKey, Totp]` en `group_vars/core.yml` y
  ejecutar `make configure` (crea el TOTP antes de exigirlo).
- **Pérdida del móvil:** volver a escanear el QR desde el secreto cifrado en un móvil nuevo. Si el
  secreto pudiera estar comprometido, rotarlo.
- **Rotación:** borrar la credencial TOTP del usuario en el panel, regenerar el secreto en SOPS,
  registrarlo en la app y ejecutar `make configure`.
- **Acceso de emergencia:** el SSH directo al puerto 22 desde el equipo de administración sigue
  disponible mientras no se restrinja (ver [pendientes](../pendientes.md)).
