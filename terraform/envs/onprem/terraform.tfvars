proxmox_node = "ngtn-server"
gateway      = "192.168.1.1"

ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJpK1sGWH1nmzmI54N8foTixq5O1nFlXMmyYy0u/roLt"

# Plan de IPs (bloque 192.168.1.100–119):
#   .100       reservada (futura VIP / API del clúster)
#   .101–.109  nodos k3s
#   .110–.114  servicios core (bastión, VPN…)
#   .115–.119  reserva
vms = {
  "k3s-01" = {
    role      = "k3s"
    cores     = 2
    memory    = 4096
    disk_size = 30
    ip        = "192.168.1.101/24"
  }
  "core-01" = {
    role      = "core"
    cores     = 1
    memory    = 512
    disk_size = 10
    ip        = "192.168.1.110/24"
  }
}
