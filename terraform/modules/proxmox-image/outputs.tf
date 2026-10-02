output "id" {
  description = "Identificador de la imagen en Proxmox, usado al crear las VMs"
  value       = proxmox_download_file.this.id
}
