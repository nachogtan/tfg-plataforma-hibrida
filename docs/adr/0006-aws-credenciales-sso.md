---
title: "ADR-0006: Entorno cloud en AWS con credenciales temporales (SSO)"
estado: Aceptado
fecha: 2026-10-11
tags: [adr, aws, cloud, seguridad, iam]
---

# ADR-0006: Entorno cloud en AWS con credenciales temporales (SSO)

↑ [Mapa del repositorio](../README.md) · [arquitectura](../arquitectura.md)

**Estado:** Aceptado · **Fecha:** 2026-10-11

## Contexto

El entorno cloud de la plataforma se despliega en **AWS**. Terraform necesita credenciales para su
API. La cuenta usaba claves de acceso permanentes de un usuario IAM administrador, guardadas en
texto plano en `~/.aws/credentials`: si se filtran, dan control total de la cuenta hasta que alguien
las revoca.

## Opciones consideradas

| Opción | Ventajas | Inconvenientes |
|---|---|---|
| **IAM Identity Center (SSO)** | Credenciales temporales; sin claves permanentes; MFA; permisos por conjunto | Configuración inicial en la consola |
| Rol con permisos mínimos asumido desde el usuario IAM | Credenciales temporales para Terraform | Siguen haciendo falta claves permanentes para asumirlo |
| Usuario IAM propio para Terraform | Sencillo | Clave permanente |

## Decisión

- **IAM Identity Center** (instancia de una sola región en `eu-south-2`, sin coste) con un usuario
  personal con MFA y dos conjuntos de permisos (sesiones de 2 horas):
  - `AdministratorAccess`: administración general (perfil de la CLI `admin`).
  - `TFG-Terraform`: mínimo privilegio para Terraform (perfil `tfg`), definido en
    [tfg-terraform-policy.json](../aws/tfg-terraform-policy.json): EC2/VPC solo en `eu-south-2`,
    solo instancias pequeñas y solo presupuestos `tfg-*`.
- Terraform usa el perfil `tfg` (`aws sso login --profile tfg` antes de ejecutarlo) y el proveedor
  `hashicorp/aws` con versión fijada; todos los recursos llevan las etiquetas `proyecto` y `gestionado`.
- **Región `eu-south-2` (España):** menor latencia con el entorno on-prem a través de la VPN y datos
  dentro de la UE.

## Consecuencias

- ✅ No hay claves permanentes de AWS en el equipo de administración para el proyecto.
- ✅ Una credencial filtrada caduca sola en 2 horas y solo sirve para EC2 en España.
- ✅ Verificado: el perfil `tfg` lista VPC en `eu-south-2` y recibe `UnauthorizedOperation` en
  `us-east-1` y `AccessDenied` en IAM.
- ⚠️ El conjunto de permisos se creó en la consola; su política está versionada en el repositorio,
  pero no se aplica automáticamente (pendiente: gestionar Identity Center con Terraform).
- ⚠️ Pendiente desactivar las claves de acceso del usuario IAM administrador anterior.

## Relacionado

- ADR: [0004-gestion-secretos-sops](0004-gestion-secretos-sops.md), [0005-vpn-netbird](0005-vpn-netbird.md)
