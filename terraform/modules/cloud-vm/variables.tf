variable "name" {
  description = "Nombre de la VM"
  type        = string
}

variable "ami_id" {
  description = "Imagen (AMI) de la VM"
  type        = string
}

variable "instance_type" {
  description = "Tipo de instancia (la política TFG-Terraform solo permite tipos pequeños)"
  type        = string
}

variable "subnet_id" {
  description = "Subred donde se crea"
  type        = string
}

variable "security_group_ids" {
  description = "Grupos de seguridad"
  type        = list(string)
}

variable "disk_size" {
  description = "Tamaño del disco en GB"
  type        = number
  default     = 8
}

variable "user_data" {
  description = "Configuración de cloud-init para el primer arranque"
  type        = string
  sensitive   = true
}
