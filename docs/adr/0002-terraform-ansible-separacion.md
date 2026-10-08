---
title: "ADR-0002: Separación Terraform / Ansible"
estado: Aceptado
fecha: 2026-10-01
tags: [adr, terraform, ansible, iac]
---

# ADR-0002: Terraform provisiona, Ansible configura

↑ [Mapa del repositorio](../README.md) · [arquitectura](../arquitectura.md)

**Estado:** Aceptado · **Fecha:** 2026-10-01

## Contexto

La plataforma abarca dos entornos (on-prem en Proxmox y cloud) y necesita tanto **crear** infraestructura (VMs, redes, discos) como **configurarla** (paquetes, hardening, servicios, k3s). Mezclar ambas responsabilidades en una sola herramienta complica el mantenimiento y la idempotencia.

## Decisión

1. **Terraform** se limita a la provisión, con un directorio por entorno y módulos reutilizables:
   - Entornos: [envs/onprem](../../terraform/envs/onprem/main.tf), [envs/cloud](../../terraform/envs/cloud/main.tf), cada uno con su propio estado ([backend.tf](../../terraform/envs/onprem/backend.tf)).
   - Módulos: [proxmox-image](../../terraform/modules/proxmox-image/main.tf), [proxmox-vm](../../terraform/modules/proxmox-vm/main.tf), [cloud-vm](../../terraform/modules/cloud-vm/main.tf).
2. **Ansible** se encarga de toda la configuración del sistema operativo y de los servicios, con inventarios separados por entorno ([onprem](../../ansible/inventories/onprem/hosts.yml), [cloud](../../ansible/inventories/cloud/hosts.yml)).
3. **Contrato entre capas:** los `outputs.tf` de Terraform son la única fuente de verdad de los hosts. [tf-to-inventory.sh](../../scripts/tf-to-inventory.sh) los convierte en `hosts.yml`, así que no se editan IPs a mano.
4. Las VMs se crean a partir de una imagen cloud oficial descargada por Terraform (módulo [proxmox-image](../../terraform/modules/proxmox-image/main.tf)) y se inicializan con cloud-init (usuario y clave SSH), de modo que Ansible puede conectarse sin pasos manuales.

## Alternativas consideradas

- **Solo Terraform (con `remote-exec` o cloud-init para toda la configuración):** descartada.
  Los provisioners de Terraform son un último recurso según la propia documentación,
  no son idempotentes y cualquier cambio de configuración puede obligar a recrear la VM.
- **Solo Ansible (módulos `community.general.proxmox_kvm` y del proveedor cloud):** descartada.
  Ansible no mantiene un estado de la infraestructura, por lo que no detecta derivas
  ni elimina recursos que ya no están declarados.
- **Pulumi u OpenTofu:** OpenTofu es compatible con el código de Terraform y se mantiene
  como alternativa libre; Pulumi se descarta por requerir un lenguaje de programación
  general y tener menor adopción en perfiles de sistemas.

## Consecuencias

- ✅ Cada herramienta se usa para lo que está diseñada; los cambios de configuración no recrean VMs.
- ✅ Los inventarios siempre reflejan la infraestructura real.
- ⚠️ El script puente pasa a ser una dependencia crítica y debe validarse en CI.
- ⚠️ Hay que ejecutar las fases en orden (ver [puesta-en-marcha](../runbooks/puesta-en-marcha.md)).

## Relacionado

- ADR: [0001-eleccion-k3s](0001-eleccion-k3s.md), [0004-gestion-secretos-sops](0004-gestion-secretos-sops.md)
- Runbooks: [puesta-en-marcha](../runbooks/puesta-en-marcha.md), [añadir-nodo](../runbooks/añadir-nodo.md)
- Diario: [2026-10-01](../diario/2026-10-01.md)
