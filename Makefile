# Makefile de la plataforma híbrida: atajos para el despliegue y las pruebas.
# Uso: make <objetivo> [ENV=onprem|cloud]   (make help para ver la lista)

SHELL := /bin/bash
.RECIPEPREFIX = >
.DEFAULT_GOAL := help
.PHONY: help init plan apply destroy inventory ping configure deploy rebuild check status bootstrap

# Entorno: onprem (Proxmox, por defecto) o cloud (AWS). Ejemplo: make deploy ENV=cloud
ENV        ?= onprem
TF_DIR     := terraform/envs/$(ENV)
ANSIBLE    := cd ansible &&
INVENTORY  := -i inventories/$(ENV)

ifeq ($(ENV),cloud)
# AWS: credenciales SSO (aws sso login --profile tfg). La setup key de NetBird se descifra
# solo para cada comando de Terraform; no se carga .env (credenciales de Proxmox).
TF_ENV     := TF_VAR_netbird_setup_key="$$(sops -d --extract '["netbird_setup_key_cloud"]' secrets/netbird.sops.yaml)"
DEPLOY     := apply inventory ping configure
else
# Proxmox: credenciales en .env
TF_ENV     := source .env &&
DEPLOY     := apply inventory ping configure bootstrap
endif

TF         := $(TF_ENV) terraform -chdir=$(TF_DIR)

help: ## Muestra esta ayuda
> @grep -E '^[a-z]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  make %-10s %s\n", $$1, $$2}'

init: ## Inicializa Terraform
> $(TF) init

plan: ## Muestra los cambios que haría Terraform
> $(TF) plan

apply: ## Crea o actualiza la infraestructura (Terraform)
> $(TF) apply

destroy: ## Destruye la infraestructura (Terraform)
> $(TF) destroy

inventory: ## Genera el inventario de Ansible y limpia las huellas SSH antiguas
> scripts/tf-to-inventory.sh $(ENV)
> @for ip in $$($(TF) output -json inventory | jq -r '.[].ip'); do ssh-keygen -R $$ip >/dev/null 2>&1 || true; done
> @if [ "$(ENV)" = cloud ]; then resolvectl flush-caches; fi

ping: ## Espera (hasta 5 min) a que Ansible conecte con todas las VMs
> $(ANSIBLE) ansible all $(INVENTORY) -m ansible.builtin.wait_for_connection -a timeout=300

configure: ## Configura todas las VMs (playbook site.yml)
> $(ANSIBLE) ansible-playbook $(INVENTORY) playbooks/site.yml

deploy: $(DEPLOY) ## Despliegue completo (en onprem incluye GitOps)

rebuild: destroy deploy ## Destruye y vuelve a crear el entorno

check: ## Comprueba la idempotencia (Terraform y Ansible sin cambios)
> $(TF) plan -detailed-exitcode
> $(ANSIBLE) ansible-playbook $(INVENTORY) playbooks/site.yml | tail -n 3

status: ## Estado del clúster k3s (onprem)
> KUBECONFIG=$$HOME/.kube/tfg-onprem.yaml kubectl get nodes,pods -A

bootstrap: ## Arranque de GitOps: instala Argo CD y aplica la aplicación raíz
> scripts/bootstrap.sh
