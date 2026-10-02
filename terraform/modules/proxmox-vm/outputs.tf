output "vm_id" {
  description = "ID de la VM en Proxmox"
  value       = proxmox_virtual_environment_vm.this.vm_id
}

output "name" {
  description = "Nombre de la VM"
  value       = proxmox_virtual_environment_vm.this.name
}

output "ipv4" {
  description = "IP configurada (sin la máscara), usada para el inventario de Ansible"
  value       = split("/", var.ipv4_address)[0]
}
