#!/usr/bin/env bash
# Arranque de GitOps: instala Argo CD (solo la primera vez), fija la contraseña de admin
# desde SOPS y aplica la aplicación raíz.
# Después, Argo CD se gestiona a sí mismo desde Git y despliega todo lo demás.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/tfg-onprem.yaml}"
SECRETS="$ROOT/secrets/argocd.sops.yaml"

# Se descifra al principio: si falta la clave age, el script falla antes de tocar el clúster
DESIRED_HASH="$(sops decrypt --extract '["argocd_admin_password_bcrypt"]' "$SECRETS")"

if kubectl -n argocd get deployment argocd-server >/dev/null 2>&1; then
  echo "==> Argo CD ya está instalado: lo gestiona él mismo desde Git (no se reinstala)"
else
  echo "==> Instalando Argo CD"
  kubectl apply --server-side -k "$ROOT/gitops/bootstrap/argocd"
fi

echo "==> Esperando a que Argo CD esté disponible"
kubectl -n argocd wait --for=condition=Available deployment --all --timeout=300s
kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=300s

echo "==> Contraseña de admin de Argo CD (secrets/argocd.sops.yaml)"
CURRENT_HASH="$(kubectl -n argocd get secret argocd-secret \
  -o jsonpath='{.data.admin\.password}' | base64 -d)"
if [ "$DESIRED_HASH" != "$CURRENT_HASH" ]; then
  # El parche entra por stdin para que el hash no aparezca en la lista de procesos
  jq -n --arg h "$DESIRED_HASH" --arg t "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{stringData: {"admin.password": $h, "admin.passwordMtime": $t}}' \
    | kubectl -n argocd patch secret argocd-secret --type merge --patch-file /dev/stdin
  echo "    Contraseña aplicada"
else
  echo "    Sin cambios"
fi
kubectl -n argocd delete secret argocd-initial-admin-secret --ignore-not-found

echo "==> Aplicando la aplicación raíz"
kubectl apply -f "$ROOT/gitops/bootstrap/root-app.yaml"

echo "==> Bootstrap completado. Estado de las aplicaciones:"
kubectl -n argocd get applications
