# Inventario de VMs para Ansible: nombre => { ip, rol }
output "inventory" {
  description = "VMs on-prem con su IP y rol, usado por scripts/tf-to-inventory.sh"
  value = {
    for name, vm in module.vms : name => {
      ip   = vm.ipv4
      role = var.vms[name].role
    }
  }
}
