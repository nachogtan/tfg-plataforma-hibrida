terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.68.0"
    }
  }
}

# Credenciales temporales de IAM Identity Center (SSO): perfil "tfg", rol TFG-Terraform
# con permisos mínimos. Antes de usar Terraform: aws sso login --profile tfg
provider "aws" {
  region  = var.region
  profile = "tfg"

  # Etiquetas que se añaden a todos los recursos creados
  default_tags {
    tags = {
      proyecto   = "tfg-plataforma-hibrida"
      gestionado = "terraform"
    }
  }
}
