# Estado de Terraform: local en el equipo de administración (decisión en docs/adr/0009-copias-pbs.md).
# Perderlo no pierde datos: se recrea con `make deploy` (los datos están en Proxmox Backup Server).
# En producción se usaría un backend remoto, por ejemplo:
#   backend "s3" { bucket = "<bucket-privado>" key = "<entorno>/terraform.tfstate" region = "eu-south-2" use_lockfile = true }
