# Red mínima del entorno cloud (ADR-0006): VPC, una subred pública y salida a Internet.
# Sin puertos de entrada: a cloud-01 solo se llega por la VPN de NetBird (ADR-0005).

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "tfg-vpc" }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "tfg-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.subnet_cidr
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true
  tags                    = { Name = "tfg-subnet-publica" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = { Name = "tfg-rt-publica" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Grupo de seguridad: ninguna regla de entrada; salida permitida (actualizaciones y NetBird)
resource "aws_security_group" "cloud_vm" {
  name        = "tfg-cloud-vm"
  description = "Sin entrada: acceso solo por NetBird"
  vpc_id      = aws_vpc.this.id
  tags        = { Name = "tfg-cloud-vm" }
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.cloud_vm.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Salida a Internet"
}

# AMI oficial de Debian 13 arm64, fijada por nombre exacto (no "la más reciente")
# para que una imagen nueva no fuerce reemplazar la VM. Propietario: cuenta oficial de Debian.
data "aws_ami" "debian" {
  owners = ["136693071363"]

  filter {
    name   = "name"
    values = ["debian-13-arm64-20261001-2618"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

module "cloud_01" {
  source = "../../modules/cloud-vm"

  name               = "cloud-01"
  ami_id             = data.aws_ami.debian.id
  instance_type      = "t4g.micro"
  subnet_id          = aws_subnet.public.id
  security_group_ids = [aws_security_group.cloud_vm.id]

  user_data = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    hostname               = "cloud-01"
    ssh_public_key         = var.ssh_public_key
    netbird_setup_key      = var.netbird_setup_key
    netbird_version        = var.netbird_version
    netbird_apt_key_sha256 = var.netbird_apt_key_sha256
    netbird_management_url = var.netbird_management_url
  })
}
