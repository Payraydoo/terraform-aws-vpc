##############################################
# main.tf

# Create VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    {
      Name        = "${var.tag_org}-${var.env}-vpc"
      Environment = var.env
      Organization = var.tag_org
    },
    var.tags
  )
}

# Create Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      Name        = "${var.tag_org}-${var.env}-igw"
      Environment = var.env
      Organization = var.tag_org
    },
    var.tags
  )
}

# Create public subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name        = "${var.tag_org}-${var.env}-public-subnet-${count.index + 1}"
      Environment = var.env
      Organization = var.tag_org
    },
    var.tags
  )
}

# Create private subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(
    {
      Name        = "${var.tag_org}-${var.env}-private-subnet-${count.index + 1}"
      Environment = var.env
      Organization = var.tag_org
    },
    var.tags
  )
}

# Create NAT Gateway
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnets)) : 0

  domain = "vpc"

  tags = merge(
    {
      Name        = "${var.tag_org}-${var.env}-nat-eip-${count.index + 1}"
      Environment = var.env
      Organization = var.tag_org
    },
    var.tags
  )
}

resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnets)) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    {
      Name        = "${var.tag_org}-${var.env}-nat-gw-${count.index + 1}"
      Environment = var.env
      Organization = var.tag_org
    },
    var.tags
  )

  depends_on = [aws_internet_gateway.this]
}

# Create route tables for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      Name        = "${var.tag_org}-${var.env}-public-rt"
      Environment = var.env
      Organization = var.tag_org
    },
    var.tags
  )
}

# Create route to Internet Gateway for public route table
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Create route tables for private subnets - ALWAYS create these regardless of NAT gateway
resource "aws_route_table" "private" {
  # Changed to always create private route tables, one per subnet
  count = length(var.private_subnets)

  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      Name        = "${var.tag_org}-${var.env}-private-rt-${count.index + 1}"
      Environment = var.env
      Organization = var.tag_org
    },
    var.tags
  )
}

# Create route to NAT Gateway for private route tables - only if NAT gateway enabled
resource "aws_route" "private_nat_gateway" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? length(var.private_subnets) : length(var.private_subnets)) : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[var.single_nat_gateway ? 0 : count.index].id
}

# Associate private subnets with private route tables
resource "aws_route_table_association" "private" {
  count = length(var.private_subnets)

  subnet_id      = aws_subnet.private[count.index].id
  # Now we can always reference a route table since they're created for each subnet
  route_table_id = aws_route_table.private[count.index].id
}

# Create VPC default security group
resource "aws_security_group" "default" {
  name        = "${var.tag_org}-${var.env}-default-sg"
  description = "Default security group for VPC"
  vpc_id      = aws_vpc.this.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.tag_org}-${var.env}-default-sg"
      Environment = var.env
      Organization = var.tag_org
    },
    var.tags
  )
}