# Crea una máquina virtual en Proxmox a partir de una imagen cloud,
# inicializada con cloud-init (usuario, clave SSH y red).
terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
  }
}

resource "proxmox_virtual_environment_vm" "this" {
  name      = var.name
  node_name = var.node_name
  tags      = var.tags

  # La imagen genericcloud no incluye el agente QEMU: lo instala cloud-init (vendor-data, envs/onprem/main.tf)
  agent {
    enabled = true
  }

  cpu {
    cores = var.cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.memory
  }

  disk {
    datastore_id = var.datastore_id
    import_from  = var.image_id
    interface    = "scsi0"
    size         = var.disk_size
  }

  network_device {
    bridge = var.bridge
  }

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id        = var.datastore_id
    vendor_data_file_id = var.vendor_data_file_id

    ip_config {
      ipv4 {
        address = var.ipv4_address
        gateway = var.ipv4_gateway
      }
    }

    user_account {
      username = var.username
      keys     = [var.ssh_public_key]
    }
  }
}
