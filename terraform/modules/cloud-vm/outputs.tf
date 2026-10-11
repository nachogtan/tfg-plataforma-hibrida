output "id" {
  description = "Identificador de la instancia"
  value       = aws_instance.this.id
}

output "private_ip" {
  description = "IP privada dentro de la VPC"
  value       = aws_instance.this.private_ip
}
