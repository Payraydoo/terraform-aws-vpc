/**
 * # AWS VPC Terraform Module
 *
 * This module creates a complete AWS VPC with public and private subnets,
 * NAT Gateway, Internet Gateway, and all necessary route tables.
 */

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name         = "${var.tag_org_short_name}-${var.environment}-vpc"
    Environment  = var.environment
    Organization = var.tag_org_short_name
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
    Name         = "${var.tag_org_short_name}-${var.environment}-public-subnet-${count.index + 1}"
    Environment  = var.environment
    Organization = var.tag_org_short_name
  }
}

resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name         = "${var.tag_org_short_name}-${var.environment}-private-subnet-${count.index + 1}"
    Environment  = var.environment
    Organization = var.tag_org_short_name
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name         = "${var.tag_org_short_name}-${var.environment}-igw"
    Environment  = var.environment
    Organization = var.tag_org_short_name
  }
}

# NAT Gateway with Elastic IP
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name         = "${var.tag_org_short_name}-${var.environment}-nat-eip"
    Environment  = var.environment
    Organization = var.tag_org_short_name
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name         = "${var.tag_org_short_name}-${var.environment}-nat-gateway"
    Environment  = var.environment
    Organization = var.tag_org_short_name
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
    Name         = "${var.tag_org_short_name}-${var.environment}-public-route-table"
    Environment  = var.environment
    Organization = var.tag_org_short_name
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name         = "${var.tag_org_short_name}-${var.environment}-private-route-table"
    Environment  = var.environment
    Organization = var.tag_org_short_name
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