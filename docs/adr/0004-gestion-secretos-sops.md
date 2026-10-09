---
title: "ADR-0004: Gestión de secretos con SOPS"
estado: Aceptado
fecha: 2026-10-01
tags: [adr, seguridad, secretos, sops]
---

# ADR-0004: Gestión de secretos con SOPS

↑ [Mapa del repositorio](../README.md) · [arquitectura](../arquitectura.md)

**Estado:** Aceptado (2026-10-08) · **Fecha:** 2026-10-01

## Contexto

Las tres capas manejan información sensible: credenciales del proveedor en Terraform, contraseñas y tokens de servicios en Ansible (NetBird, Authentik, Warpgate) y `Secret` de Kubernetes en GitOps. Para seguir el enfoque GitOps hace falta versionarlos sin exponerlos.

## Decisión

- Se usa **SOPS** con claves **age** para cifrar los valores de ficheros YAML/JSON,
  conservando la estructura legible para revisar diferencias en Git.
- Las reglas de cifrado (rutas y destinatarios) se definen en [.sops.yaml](../../.sops.yaml)
  y los ficheros cifrados se guardan en [secrets/](../../secrets/).
- Las credenciales que no se versionan se mantienen fuera de Git mediante `.gitignore`:
  - API de Proxmox: variables de entorno en `.env` (ver [configuracion-inicial](../runbooks/configuracion-inicial.md)).
  - Proveedor cloud: `secrets.auto.tfvars`, con plantilla en
    [cloud/secrets.auto.tfvars.example](../../terraform/envs/cloud/secrets.auto.tfvars.example).

> [!NOTE]
> Pendiente de decidir:
> - Integración con Argo CD: plugin KSOPS u otra alternativa.
> - Hook de pre-commit que compruebe que los ficheros de `secrets/` están cifrados (gitleaks ya
>   detecta secretos conocidos en claro, ver [.pre-commit-config.yaml](../../.pre-commit-config.yaml)).

## Alternativas consideradas

- **Sealed Secrets:** solo cubre los `Secret` de Kubernetes; no sirve para los secretos
  de Ansible ni de Terraform.
- **Ansible Vault:** solo cubre Ansible y cifra el fichero completo, por lo que los
  cambios no se pueden revisar en Git.
- **HashiCorp Vault / OpenBao:** solución más completa, pero requiere desplegar y operar
  un servicio adicional antes de tener la plataforma. Se deja como trabajo futuro.
- **KMS de un proveedor cloud:** crea dependencia de una cuenta cloud para descifrar
  secretos de la parte on-prem.

## Consecuencias

- ✅ Los secretos quedan versionados y auditables junto al código.
- ⚠️ La clave privada pasa a ser crítica: si se pierde, no se puede descifrar nada. Su custodia forma parte de [restauracion](../runbooks/restauracion.md).
- ⚠️ La clave privada age se guarda fuera del repositorio, con una copia de seguridad
  en un lugar seguro (por ejemplo, un gestor de contraseñas).

## Actualización (2026-10-08)

Implementado para la capa de Ansible:

- Regla en [.sops.yaml](../../.sops.yaml): se cifra todo `secrets/*.sops.yaml` para la clave pública
  `age` del administrador; la privada está en `~/.config/sops/age/keys.txt`, fuera del repositorio.
- Primer secreto: contraseña de admin de Warpgate ([secrets/warpgate.sops.yaml](../../secrets/warpgate.sops.yaml)),
  generada al azar y cifrada sin pasar por texto plano.
- Ansible la descifra en el equipo de administración con el lookup `community.sops.sops` (colección
  `community.sops` 2.5.0). Se descartó `community.sops.load_vars` porque inyecta los secretos como
  *facts*, un mecanismo obsoleto que desaparece en ansible-core 2.24.
- La CI no tiene la clave `age`: valida la sintaxis sin descifrar nada.
- 2026-10-09: contraseña de admin de Argo CD ([secrets/argocd.sops.yaml](../../secrets/argocd.sops.yaml)).
  [bootstrap.sh](../../scripts/bootstrap.sh) aplica su hash bcrypt a `argocd-secret` solo si difiere
  del del clúster. Es un secreto de arranque: lo aplica el script, no Argo CD.
- Pendiente: el resto de secretos de Kubernetes (integración con Argo CD) y los de Terraform.

## Relacionado

- ADR: [0002-terraform-ansible-separacion](0002-terraform-ansible-separacion.md), [0003-gitops-argocd](0003-gitops-argocd.md)
- Runbooks: [puesta-en-marcha](../runbooks/puesta-en-marcha.md), [restauracion](../runbooks/restauracion.md)
- Diario: [2026-10-01](../diario/2026-10-01.md)
