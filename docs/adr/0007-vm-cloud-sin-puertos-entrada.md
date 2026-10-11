---
title: "ADR-0007: VMs cloud sin puertos de entrada, administradas por la VPN"
estado: Aceptado
fecha: 2026-10-11
tags: [adr, aws, cloud, seguridad, netbird, cloud-init]
---

# ADR-0007: VMs cloud sin puertos de entrada, administradas por la VPN

↑ [Mapa del repositorio](../README.md) · [arquitectura](../arquitectura.md)

**Estado:** Aceptado · **Fecha:** 2026-10-11

## Contexto

Las VMs del entorno cloud (AWS, [ADR-0006](0006-aws-credenciales-sso.md)) tienen que poder
administrarse con Ansible por SSH, igual que las on-prem. Abrir el puerto 22 a Internet expone la VM
a escaneos y ataques de fuerza bruta, y el equipo de administración tiene IP dinámica, así que
limitarlo a una IP de origen obliga a cambiar la regla cada vez.

## Opciones consideradas

| Opción | Ventajas | Inconvenientes |
|---|---|---|
| **Sin puertos de entrada; acceso por NetBird** | Superficie expuesta nula; misma VPN y mismas políticas que on-prem | La VM debe unirse a la malla sola en el primer arranque |
| Puerto 22 abierto solo a la IP del administrador | Sencillo | IP dinámica; puerto expuesto igualmente |
| AWS Systems Manager (Session Manager) | Sin puertos de entrada | Rol IAM y agente extra; solo sirve en AWS, distinto de on-prem |
| Bastión SSH en AWS | Patrón clásico | Otra VM que mantener y exponer |

## Decisión

- El security group `tfg-cloud-vm` **no tiene reglas de entrada**; solo salida.
- En el primer arranque, **cloud-init** (plantilla `terraform/envs/cloud/templates/cloud-init.yaml.tftpl`):
  - pone el nombre de la VM y autoriza la clave SSH pública del administrador;
  - instala NetBird con versión fijada, comprobando el SHA-256 de la clave del repositorio, con los
    mismos ficheros que genera el rol `netbird` (Ansible no cambia nada después);
  - une la VM a la malla con una **setup key propia** (`cloud-vms`: grupo `cloud`, pocos usos,
    caducidad corta), guardada cifrada con SOPS y pasada a Terraform por `TF_VAR_`.
- La política de NetBird `admin-a-cloud` permite solo **TCP 22** desde el grupo `admin`.
- El inventario de Ansible se genera con `scripts/tf-to-inventory.sh cloud`; `ansible_host` es el
  nombre en la malla (`cloud-01.netbird.cloud`). Se usa el mismo `site.yml` que on-prem, con
  variables por entorno (`common_qemu_guest_agent: false`, setup key de cloud).
- Imagen oficial de **Debian 13 arm64** (propietario `136693071363`) fijada por **nombre exacto**,
  instancia `t4g.micro`, IMDSv2 obligatorio y disco gp3 cifrado.
- Las VMs cloud son **efímeras**: se crean cuando hacen falta y se destruyen después; la red se mantiene.

## Consecuencias

- ✅ Verificado: SSH y Ansible llegan a `cloud-01` por NetBird sin ninguna regla de entrada en AWS.
- ✅ Verificado: tras recrear la VM (`apply -replace`), la primera pasada de `site.yml` deja el rol
  `netbird` sin cambios y la segunda pasada completa da `changed=0`.
- ⚠ La setup key va en el `user_data`, legible desde dentro de la VM y con permisos de lectura en
  EC2. Se mitiga con una clave dedicada, de pocos usos y caducidad corta, cuyo grupo solo recibe
  conexiones del administrador.
- ⚠ Recrear una VM exige borrar el peer viejo en NetBird, olvidar su clave de host SSH y vaciar la
  caché DNS (ver [runbook](../runbooks/vm-cloud.md)). Pendiente: limpieza de peers por API.
- ⚠ Si NetBird Cloud no está disponible, no hay acceso de administración. Plan de emergencia: abrir
  temporalmente el 22 a la IP propia en el security group con Terraform.
- ⚠ La versión y la huella de NetBird están duplicadas en las variables de Terraform y en el rol de
  Ansible; hay que cambiarlas a la vez.

## Relacionado

- ADR: [0005-vpn-netbird](0005-vpn-netbird.md), [0006-aws-credenciales-sso](0006-aws-credenciales-sso.md)
- Runbook: [vm-cloud](../runbooks/vm-cloud.md)
