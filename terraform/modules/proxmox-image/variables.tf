variable "node_name" {
  description = "Nombre del nodo Proxmox donde se descarga la imagen"
  type        = string
}

variable "datastore_id" {
  description = "Almacenamiento de destino (debe admitir contenido 'import')"
  type        = string
  default     = "local"
}

variable "url" {
  description = "URL oficial de la imagen cloud"
  type        = string
}

variable "file_name" {
  description = "Nombre con el que se guarda la imagen en Proxmox (extensión .qcow2)"
  type        = string
}
