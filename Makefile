# Makefile de la plataforma híbrida: atajos para el despliegue y las pruebas.
# Uso: make <objetivo>   (make help para ver la lista)

SHELL := /bin/bash
.RECIPEPREFIX = >
.DEFAULT_GOAL := help
.PHONY: help init plan apply destroy inventory ping configure deploy rebuild check status

ENV        ?= onprem
TF_DIR     := terraform/envs/$(ENV)
LOAD_ENV   := source .env &&
TF         := $(LOAD_ENV) terraform -chdir=$(TF_DIR)
ANSIBLE    := cd ansible &&

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

ping: ## Comprueba la conexión de Ansible con todas las VMs
> $(ANSIBLE) ansible all -m ping

configure: ## Configura todas las VMs (playbook site.yml)
> $(ANSIBLE) ansible-playbook playbooks/site.yml

deploy: apply inventory ping configure ## Despliegue completo: Terraform + inventario + Ansible

rebuild: destroy deploy ## Destruye y vuelve a crear toda la plataforma

check: ## Comprueba la idempotencia (Terraform y Ansible sin cambios)
> $(TF) plan -detailed-exitcode
> $(ANSIBLE) ansible-playbook playbooks/site.yml | tail -n 3

status: ## Estado del clúster k3s
> KUBECONFIG=$$HOME/.kube/tfg-onprem.yaml kubectl get nodes,pods -A
