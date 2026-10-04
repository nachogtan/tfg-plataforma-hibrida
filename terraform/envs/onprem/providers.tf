terraform {
  required_version = ">= 1.6.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.114.0"
    }
  }
}

# Las credenciales de la API se leen de .env:
# PROXMOX_VE_ENDPOINT, PROXMOX_VE_API_TOKEN y PROXMOX_VE_INSECURE
provider "proxmox" {
  # SSH solo se usa para subir snippets de cloud-init (la API no lo permite)
  ssh {
    agent    = true
    username = "root"

    node {
      name    = "ngtn-server"
      address = "192.168.1.90"
    }
  }
}
