# Crea una VM en AWS (EC2) a partir de una imagen cloud, inicializada con cloud-init.
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  user_data              = var.user_data

  # Servicio de metadatos solo con IMDSv2 (exige token de sesión)
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = var.disk_size
    encrypted   = true
  }

  tags = { Name = var.name }
}
