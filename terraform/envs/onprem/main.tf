# Imagen base de Debian 13 para todas las VMs on-prem
module "debian_image" {
  source = "../../modules/proxmox-image"

  node_name = var.proxmox_node
  url       = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
  file_name = "debian-13-genericcloud-amd64.qcow2"
}
