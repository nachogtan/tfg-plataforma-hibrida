terraform {
  required_version = ">= 1.6.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.114.0"
    }
  }
}

# Las credenciales se leen de las variables de entorno definidas en .env:
# PROXMOX_VE_ENDPOINT, PROXMOX_VE_API_TOKEN y PROXMOX_VE_INSECURE
provider "proxmox" {}
