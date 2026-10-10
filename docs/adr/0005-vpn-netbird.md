---
title: "ADR-0005: VPN en malla con NetBird"
estado: Aceptado
fecha: 2026-10-10
tags: [adr, red, vpn, netbird, seguridad]
---

# ADR-0005: VPN en malla con NetBird (plano de control en SaaS en la fase 1)

↑ [Mapa del repositorio](../README.md) · [arquitectura](../arquitectura.md)

**Estado:** Aceptado · **Fecha:** 2026-10-10

## Contexto

La plataforma necesita una red privada que una el entorno on-prem con el futuro entorno cloud y
que dé al equipo de administración una IP estable, para poder restringir el SSH de las VMs
(ver [pendientes](../pendientes.md)).

Restricciones:

- El nodo Proxmox (8 GB) tiene unos 800 MB libres y no se va a ampliar a corto plazo.
- El plano de control autoalojado de NetBird (management, signal y relay) necesita ~1 GB de RAM.
- El proveedor cloud aún no está decidido.
- Alojar el plano de control en casa obligaría a abrir puertos del router a Internet para los
  nodos cloud.

## Opciones consideradas

| Opción | Ventajas | Inconvenientes |
|---|---|---|
| NetBird autoalojado on-prem | Control total | No cabe en la RAM disponible; exige exponer la red doméstica |
| NetBird autoalojado en la nube | Control total; ubicación natural en una arquitectura híbrida | Depende de elegir proveedor cloud; coste de una VM |
| **NetBird Cloud (SaaS)** | Sin consumo on-prem salvo los clientes; sin puertos abiertos en casa; plan gratuito (5 usuarios, 100 máquinas) | Metadatos en el proveedor; dependencia de su servicio |
| Tailscale (SaaS) | Producto maduro | Plano de control propietario, no autoalojable |
| Headscale | Ligero (cabría en `core-01`) | Proyecto comunitario; sin interfaz web oficial |

## Decisión

Se usa **NetBird**: todo su software es de código abierto, incluido el plano de control (AGPLv3;
clientes BSD-3), con interfaz web, gestión local de usuarios y API REST oficial.
El despliegue se hace en dos fases:

- **Fase 1 (ahora):** plano de control en **NetBird Cloud**. Las VMs y el equipo de administración
  ejecutan el cliente (versión fijada), instalado y registrado con el rol de Ansible `netbird`
  mediante una *setup key* cifrada con SOPS ([0004-gestion-secretos-sops](0004-gestion-secretos-sops.md)).
- **Fase 2 (cuando exista el entorno cloud):** plano de control autoalojado en una VM cloud.
  Los clientes no cambian: se registran contra la nueva URL de management.

Las políticas de acceso se gestionan como código con la **API REST oficial** de NetBird desde
Ansible (mismo patrón que Warpgate): grupos y políticas declarados en `group_vars` y un token de un
usuario de servicio cifrado con SOPS. Se descarta por ahora el proveedor de Terraform
`netbirdio/netbird` por inmaduro (versión 0.0.10).

## Consecuencias

- ✅ Ningún consumo de RAM on-prem salvo los clientes, y ningún puerto abierto en el router.
- ✅ El mismo software en las dos fases: la migración no cambia los clientes ni el diseño.
- ✅ IP estable del equipo de administración para restringir el SSH de las VMs.
- ⚠️ NetBird conoce los metadatos de la red (equipos, IPs públicas y horas de conexión), no el
  contenido del tráfico, que va cifrado de extremo a extremo con WireGuard.
- ⚠️ Dependencia de la disponibilidad del servicio y de los límites del plan gratuito.
- ⚠️ La *setup key* y el token de la API permiten modificar la red: se cifran con SOPS y se
  limitan (caducidad, uso y permisos mínimos).

## Relacionado

- ADR: [0004-gestion-secretos-sops](0004-gestion-secretos-sops.md)
- Runbooks: [acceso-warpgate](../runbooks/acceso-warpgate.md)
- Pendientes: [pendientes](../pendientes.md)
