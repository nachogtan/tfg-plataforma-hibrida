#!/usr/bin/env bash
# Arranque de GitOps: instala Argo CD (solo la primera vez) y aplica la aplicación raíz.
# Después, Argo CD se gestiona a sí mismo desde Git y despliega todo lo demás.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/tfg-onprem.yaml}"

if kubectl -n argocd get deployment argocd-server >/dev/null 2>&1; then
  echo "==> Argo CD ya está instalado: lo gestiona él mismo desde Git (no se reinstala)"
else
  echo "==> Instalando Argo CD"
  kubectl apply --server-side -k "$ROOT/gitops/bootstrap/argocd"
fi

echo "==> Esperando a que Argo CD esté disponible"
kubectl -n argocd wait --for=condition=Available deployment --all --timeout=300s
kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=300s

echo "==> Aplicando la aplicación raíz"
kubectl apply -f "$ROOT/gitops/bootstrap/root-app.yaml"

echo "==> Bootstrap completado. Estado de las aplicaciones:"
kubectl -n argocd get applications
