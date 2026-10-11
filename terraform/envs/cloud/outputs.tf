# Inventario para scripts/tf-to-inventory.sh (mismo formato que onprem: nombre → {role, ip}).
# En cloud, "ip" es el nombre en la malla NetBird: Ansible entra por la VPN, nunca por la IP pública.
output "inventory" {
  description = "VMs cloud para el inventario de Ansible"
  value = {
    "cloud-01" = {
      role        = "cloud"
      ip          = "cloud-01.netbird.cloud"
      instance_id = module.cloud_01.id
      private_ip  = module.cloud_01.private_ip
    }
  }
}
