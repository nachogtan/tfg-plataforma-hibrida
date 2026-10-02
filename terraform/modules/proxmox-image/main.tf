# Descarga una imagen cloud en un almacenamiento de Proxmox.
# La descarga la hace el propio nodo Proxmox, no el equipo que ejecuta Terraform.
terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
  }
}

resource "proxmox_download_file" "this" {
  node_name    = var.node_name
  datastore_id = var.datastore_id
  content_type = "import"
  url          = var.url
  file_name    = var.file_name
  overwrite    = false
}
