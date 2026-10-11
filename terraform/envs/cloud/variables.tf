variable "region" {
  description = "Región de AWS (España)"
  type        = string
  default     = "eu-south-2"
}

variable "vpc_cidr" {
  description = "Rango de la VPC (no solapa con la LAN, k3s ni NetBird)"
  type        = string
  default     = "10.20.0.0/16"
}

variable "subnet_cidr" {
  description = "Rango de la subred pública"
  type        = string
  default     = "10.20.1.0/24"
}

variable "ssh_public_key" {
  description = "Clave pública SSH autorizada para el usuario admin de las VMs cloud"
  type        = string
}

variable "netbird_setup_key" {
  description = "Setup key de NetBird para VMs cloud (grupo cloud). Se pasa por TF_VAR_ desde SOPS"
  type        = string
  sensitive   = true
}

# Mismos valores que ansible/roles/netbird/defaults/main.yml (mantener sincronizados)
variable "netbird_version" {
  description = "Versión fijada del cliente de NetBird"
  type        = string
  default     = "0.80.0"
}

variable "netbird_apt_key_sha256" {
  description = "SHA-256 de la clave de firma del repositorio APT de NetBird"
  type        = string
  default     = "6bd434c07e7c3a71211de79ca287e93b45deadedc4b74f1a2e83e11abe6e0bf5"
}

variable "netbird_management_url" {
  description = "Plano de control de NetBird (fase 1: NetBird Cloud, ADR-0005)"
  type        = string
  default     = "https://api.netbird.io:443"
}
