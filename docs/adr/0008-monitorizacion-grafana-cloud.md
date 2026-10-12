---
title: "ADR-0008: Monitorización con Grafana Cloud y un único agente en el clúster"
estado: Aceptado
fecha: 2026-10-12
tags: [adr, monitorizacion, observabilidad, grafana, prometheus, seguridad]
---

# ADR-0008: Monitorización con Grafana Cloud y un único agente en el clúster

↑ [Mapa del repositorio](../README.md) · [arquitectura](../arquitectura.md)

**Estado:** Aceptado · **Fecha:** 2026-10-12

## Contexto

La plataforma necesita métricas de las VMs y del clúster, paneles y alertas. La RAM es el límite
(medido el 2026-10-12): el nodo Proxmox tiene 1,2 GiB disponibles (no cabe otra VM), `k3s-01`
1,4 GiB y `core-01` 316 MiB. `k3s-01` no tiene swap.

## Opciones consideradas

| Opción | Ventajas | Inconvenientes |
|---|---|---|
| **Grafana Cloud + un agente (Alloy) en el clúster + `node_exporter` en las VMs** | Poca RAM local; paneles y alertas fuera del laboratorio (avisa si cae todo) | Servicio de terceros; límites del plan gratuito |
| Grafana Cloud + agente en cada VM | Sin dependencia del clúster | El agente pesa demasiado para `core-01` |
| VictoriaMetrics + Grafana en el clúster | Todo propio, sin límites externos | Unos 400–500 MB; si cae `k3s-01`, no hay monitorización |
| kube-prometheus-stack | Estándar de la industria | 1–1,5 GB: no cabe |

## Decisión

- **Grafana Cloud**, plan gratuito, stack en Suiza (`prod-eu-central-0`, AWS `eu-central-2`).
- **`node_exporter`** en todas las VMs, instalado con Ansible (versión fijada y verificada); su
  puerto solo es accesible desde el clúster.
- **Un único Grafana Alloy** en `k3s-01`, desplegado con Argo CD: recoge las métricas de los
  `node_exporter` y del clúster y las envía con *remote write* a Grafana Cloud. Solo se envían las
  métricas que se usan, para no superar los límites del plan.
- **Credencial de mínimo privilegio:** *access policy* `tfg-alloy-metrics-write` con el único permiso
  `metrics:write` y un token con caducidad de 90 días, cifrado con SOPS en
  `secrets/grafana-cloud.sops.yaml`. El Secret de Kubernetes lo crea `scripts/bootstrap.sh`, igual
  que la contraseña de Argo CD ([ADR-0004](0004-gestion-secretos-sops.md)).
- **Alerta externa** en Grafana Cloud cuando dejan de llegar datos: hace de *heartbeat* de todo el
  laboratorio.

## Consecuencias

- ✅ Consumo local mínimo: unos 20 MB por VM (`node_exporter`) y un solo agente en el clúster.
- ✅ Si cae el laboratorio entero, la alerta llega igualmente porque se evalúa fuera.
- ⚠ Dependencia de un servicio externo; las métricas salen de casa (Suiza tiene decisión de
  adecuación de la UE en protección de datos). Las métricas no incluyen datos personales.
- ⚠ Plan gratuito: retención de 14 días y series activas limitadas.
- ⚠ El token caduca a los 90 días: hay que rotarlo.
- ⚠ La política tiene alcance de organización (no se pudo limitar al stack); hoy solo hay un stack.
- ⚠ El Secret no lo gestiona Argo CD: si se borra, vuelve con el siguiente `make bootstrap`
  (mejora futura: descifrado en el clúster con KSOPS o Sealed Secrets).
- ⚠ Las VMs cloud no se monitorizan todavía: haría falta una política de NetBird del clúster al grupo `cloud`.

## Relacionado

- ADR: [0003-gitops-argocd](0003-gitops-argocd.md), [0004-gestion-secretos-sops](0004-gestion-secretos-sops.md),
  [0007-vm-cloud-sin-puertos-entrada](0007-vm-cloud-sin-puertos-entrada.md)
