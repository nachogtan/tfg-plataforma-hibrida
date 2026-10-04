# Imagen base de Debian 13 para todas las VMs on-prem
module "debian_image" {
  source = "../../modules/proxmox-image"

  node_name = var.proxmox_node
  url       = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
  file_name = "debian-13-genericcloud-amd64.qcow2"
}

# Configuración común de cloud-init (vendor-data) para todas las VMs:
# instala y arranca el agente QEMU en el primer arranque
resource "proxmox_virtual_environment_file" "vendor_data" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node

  source_raw {
    file_name = "vendor-data-base.yaml"
    data      = <<-EOF
      #cloud-config
      package_update: true
      packages:
        - qemu-guest-agent
      runcmd:
        - systemctl start qemu-guest-agent
    EOF
  }
}

# VMs on-prem: una por cada entrada del mapa var.vms (terraform.tfvars)
module "vms" {
  source   = "../../modules/proxmox-vm"
  for_each = var.vms

  name                = each.key
  node_name           = var.proxmox_node
  image_id            = module.debian_image.id
  cores               = each.value.cores
  memory              = each.value.memory
  disk_size           = each.value.disk_size
  ipv4_address        = each.value.ip
  ipv4_gateway        = var.gateway
  tags                = ["terraform", each.value.role]
  ssh_public_key      = var.ssh_public_key
  vendor_data_file_id = proxmox_virtual_environment_file.vendor_data.id
}
