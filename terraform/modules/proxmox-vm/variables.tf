variable "name" {
  description = "Nombre de la VM"
  type        = string
}

variable "node_name" {
  description = "Nodo Proxmox donde se crea la VM"
  type        = string
}

variable "tags" {
  description = "Etiquetas de la VM en Proxmox"
  type        = list(string)
  default     = ["terraform"]
}

variable "cores" {
  description = "Número de núcleos de CPU"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Memoria RAM en MB"
  type        = number
  default     = 2048
}

variable "datastore_id" {
  description = "Almacenamiento para el disco y el disco de cloud-init"
  type        = string
  default     = "local-lvm"
}

variable "image_id" {
  description = "ID de la imagen cloud (salida del módulo proxmox-image)"
  type        = string
}

variable "disk_size" {
  description = "Tamaño del disco en GB"
  type        = number
  default     = 20
}

variable "bridge" {
  description = "Bridge de red de Proxmox"
  type        = string
  default     = "vmbr0"
}

variable "ipv4_address" {
  description = "IP en formato CIDR (p. ej. 192.168.1.50/24) o \"dhcp\""
  type        = string
  default     = "dhcp"
}

variable "ipv4_gateway" {
  description = "Puerta de enlace (no se usa con DHCP)"
  type        = string
  default     = null
}

variable "username" {
  description = "Usuario creado por cloud-init"
  type        = string
  default     = "admin"
}

variable "ssh_public_key" {
  description = "Clave SSH pública autorizada para el usuario"
  type        = string
}
