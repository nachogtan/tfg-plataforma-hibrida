proxmox_node = "ngtn-server"
gateway      = "192.168.1.1"

ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJpK1sGWH1nmzmI54N8foTixq5O1nFlXMmyYy0u/roLt"

vms = {
  "k3s-01" = {
    role      = "k3s"
    cores     = 2
    memory    = 4096
    disk_size = 30
    ip        = "192.168.1.101/24"
  }
}
