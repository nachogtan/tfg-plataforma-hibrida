---
title: "Runbook: monitorización (Grafana Cloud, Alloy y node_exporter)"
tags: [runbook, monitorizacion, grafana, alloy, node_exporter, alertas]
---

# Runbook: monitorización (Grafana Cloud, Alloy y node_exporter)

↑ [Mapa del repositorio](../README.md) · Decisión: [ADR-0008](../adr/0008-monitorizacion-grafana-cloud.md)

Las VMs publican sus métricas con `node_exporter`; un único Grafana Alloy en el clúster las recoge y
las envía a Grafana Cloud, donde están el panel y la alerta.

```text
VM (node_exporter :9100) ──► Alloy (k3s-01, namespace monitoring) ──► Grafana Cloud ──► Telegram
```

## Qué gestiona el repositorio

| Pieza | Dónde | Se aplica con |
|---|---|---|
| `node_exporter` (paquete de Debian) y regla de UFW (9100 solo desde los nodos k3s) | `ansible/roles/node_exporter` | `make configure` (playbook `base.yml`) |
| Token de envío de métricas (cifrado) | `secrets/grafana-cloud.sops.yaml` | `make bootstrap` crea el Secret `monitoring/grafana-cloud` |
| Alloy (chart oficial, versión fijada) y su configuración | `gitops/platform/monitoring/application.yaml` | Argo CD, al fusionar en `main` |

`make deploy` lo aplica todo en orden.

## Qué se configura a mano en Grafana Cloud

Stack `boldalder2379` (`https://boldalder2379.grafana.net`). Pendiente: gestionarlo como código.

1. **Panel:** *Dashboards → New → Import*, ID `1860` (*Node Exporter Full*), data source
   `grafanacloud-boldalder2379-prom`.
2. **Punto de contacto:** *Alerting → Contact points → Add*: integración **Telegram**, bot
   `tfg_ngtn_alertas_bot` (token en el gestor de contraseñas, nunca en el repositorio) y el chat ID.
3. **Política:** *Notification policies → Default policy* → el punto de contacto de Telegram.
4. **Regla** `TFG - VM sin métricas` (carpeta `TFG`, grupo `tfg-heartbeat`, cada `1m`):
   - Consulta `up{job="node"}`; condición **IS BELOW 1**.
   - *Pending period* `5m`.
   - *Alert state if no data*: **Alerting** (si dejan de llegar datos, también avisa).

## Comprobaciones

```bash
export KUBECONFIG=$HOME/.kube/tfg-onprem.yaml
kubectl -n argocd get application alloy              # Synced / Healthy
kubectl -n monitoring get pods                       # alloy-... 2/2 Running
kubectl -n monitoring logs deploy/alloy -c alloy --since=5m | grep -iE 'level=(error|warn)'   # nada
ssh admin@192.168.1.101 'curl -s -m 5 -o /dev/null -w "%{http_code}\n" http://192.168.1.110:9100/metrics'   # 200
curl -s -m 5 -o /dev/null -w '%{http_code}\n' http://192.168.1.110:9100/metrics                              # 000 (bloqueado)
```

En Grafana (*Explore*), `up{job="node"}` debe dar `1` para cada VM.

## Probar la alerta

```bash
cd ~ && ssh admin@192.168.1.110 'sudo systemctl stop prometheus-node-exporter'
```

En unos 6 minutos llega a Telegram un aviso **FIRING** para `core-01`. Para restaurarlo:

```bash
cd ~ && ssh admin@192.168.1.110 'sudo systemctl start prometheus-node-exporter'
```

En 1–2 minutos llega el aviso **RESOLVED**.

## Rotar el token de Grafana Cloud (caduca a los 90 días)

1. En Grafana Cloud, *Access Policies* → `tfg-alloy-metrics-write` → **Add token** (90 días).
2. Cifrarlo sin que toque el disco en claro (pegar el token en el prompt oculto):

```bash
   read -rsp 'Token de Grafana Cloud: ' GC_TOKEN && echo && printf 'grafana_cloud_metrics_token: %s\n' "$GC_TOKEN" \
     | sops -e --filename-override secrets/grafana-cloud.sops.yaml --input-type yaml --output-type yaml /dev/stdin \
     > secrets/grafana-cloud.sops.yaml; unset GC_TOKEN
```

3. Commit y PR; después `make bootstrap` y reiniciar Alloy para que lea el Secret nuevo:

```bash
   KUBECONFIG=$HOME/.kube/tfg-onprem.yaml kubectl -n monitoring rollout restart deploy/alloy
```

4. Comprobar que siguen llegando métricas y borrar el token antiguo en Grafana Cloud.

## Problemas frecuentes

| Síntoma | Causa | Solución |
|---|---|---|
| Pod de Alloy en `CreateContainerConfigError` | Falta el Secret `grafana-cloud` | `make bootstrap` |
| `401` en los logs de Alloy | Token caducado o revocado | Rotar el token |
| `up` = 0 para una VM | `node_exporter` parado o el 9100 bloqueado | `systemctl status prometheus-node-exporter` y `ufw status` en la VM; `make configure` |
| La aplicación `alloy` no aparece en Argo CD | Argo CD aún no ha leído `main` (cada 3 min) | Esperar y repetir |

> [!NOTE]
> Las VMs cloud no se monitorizan todavía: haría falta una política de NetBird del clúster al
> grupo `cloud` y añadirlas a la configuración de Alloy.
