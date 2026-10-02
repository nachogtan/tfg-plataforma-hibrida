variable "proxmox_node" {
  description = "Nombre del nodo Proxmox de destino"
  type        = string
}

variable "gateway" {
  description = "Puerta de enlace de la red on-prem"
  type        = string
}

variable "ssh_public_key" {
  description = "Clave SSH pública que cloud-init instala en las VMs"
  type        = string
}

variable "vms" {
  description = "VMs a crear: nombre => características"
  type = map(object({
    role      = string
    cores     = number
    memory    = number
    disk_size = number
    ip        = string
  }))
}
