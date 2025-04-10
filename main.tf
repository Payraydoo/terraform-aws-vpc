\*
 * # AWS VPC Terraform Module
 *
 * This module creates a complete AWS VPC with public and private subnets,
 * NAT Gateway, Internet Gateway, bastion host, and all necessary route tables.
*\

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name         = "${var.tag_org}-${var.environment}-vpc"
    Environment  = var.environment
    Organization = var.tag_org
  }
}

# Create public and private subnets
resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name         = "${var.tag_org}-${var.environment}-public-subnet-${count.index + 1}"
    Environment  = var.environment
    Organization = var.tag_org
  }
}

resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name         = "${var.tag_org}-${var.environment}-private-subnet-${count.index + 1}"
    Environment  = var.environment
    Organization = var.tag_org
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name         = "${var.tag_org}-${var.environment}-igw"
    Environment  = var.environment
    Organization = var.tag_org
  }
}

# NAT Gateway with Elastic IP
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name         = "${var.tag_org}-${var.environment}-nat-eip"
    Environment  = var.environment
    Organization = var.tag_org
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name         = "${var.tag_org}-${var.environment}-nat-gateway"
    Environment  = var.environment
    Organization = var.tag_org
  }

  depends_on = [aws_internet_gateway.main]
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name         = "${var.tag_org}-${var.environment}-public-route-table"
    Environment  = var.environment
    Organization = var.tag_org
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name         = "${var.tag_org}-${var.environment}-private-route-table"
    Environment  = var.environment
    Organization = var.tag_org
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Bastion Host Security Group
resource "aws_security_group" "bastion" {
  count       = var.create_bastion ? 1 : 0
  name        = "${var.tag_org}-${var.environment}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.bastion_allowed_cidr_blocks
    description = "Allow SSH access from specified CIDR blocks"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name         = "${var.tag_org}-${var.environment}-bastion-sg"
    Environment  = var.environment
    Organization = var.tag_org
  }
}

# Bastion Host Instance
resource "aws_instance" "bastion" {
  count                  = var.create_bastion ? 1 : 0
  ami                    = var.bastion_ami != "" ? var.bastion_ami : data.aws_ami.amazon_linux[0].id
  instance_type          = var.bastion_instance_type
  key_name               = var.bastion_key_name
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.bastion[0].id]
  
  root_block_device {
    volume_size = var.bastion_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  associate_public_ip_address = true

  tags = {
    Name         = "${var.tag_org}-${var.environment}-bastion"
    Environment  = var.environment
    Organization = var.tag_org
  }
}

# Latest Amazon Linux AMI
data "aws_ami" "amazon_linux" {
  count       = var.create_bastion ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
