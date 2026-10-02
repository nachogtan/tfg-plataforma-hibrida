# Prueba de conexión: lee la lista de nodos del clúster (no crea nada)
data "proxmox_virtual_environment_nodes" "all" {}

output "nodos_proxmox" {
  value = data.proxmox_virtual_environment_nodes.all.names
}
