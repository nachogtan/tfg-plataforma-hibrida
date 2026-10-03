#!/usr/bin/env bash
# Genera el inventario de Ansible a partir de los outputs de Terraform.
# Uso: scripts/tf-to-inventory.sh [entorno]   (por defecto: onprem)
set -euo pipefail

ENV="${1:-onprem}"
ROOT="$(git rev-parse --show-toplevel)"
TF_DIR="$ROOT/terraform/envs/$ENV"
OUT="$ROOT/ansible/inventories/$ENV/hosts.yml"

INVENTORY_JSON="$(terraform -chdir="$TF_DIR" output -json inventory)"

{
  echo "# Generado por scripts/tf-to-inventory.sh. No editar a mano."
  echo "all:"
  echo "  vars:"
  echo "    ansible_user: admin"
  echo "  children:"
  for role in $(echo "$INVENTORY_JSON" | jq -r '[.[].role] | unique | .[]'); do
    echo "    $role:"
    echo "      hosts:"
    echo "$INVENTORY_JSON" | jq -r --arg r "$role" \
      'to_entries[] | select(.value.role == $r) | "        \(.key):\n          ansible_host: \(.value.ip)"'
  done
} > "$OUT"

echo "Inventario generado: $OUT"
