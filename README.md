# Terraform AWS VPC Module

This module creates a VPC with 3 public and 3 private subnets, along with the necessary route tables, internet gateway, and NAT gateways.

## Features

- Creates a VPC with customizable CIDR block (default: 10.0.0.0/16)
- Creates 3 public subnets across different availability zones
- Creates 3 private subnets across different availability zones
- Sets up Internet Gateway for public subnets
- Sets up NAT Gateways for private subnets
- Configures route tables and associations
- Standardized tagging system

## Usage

```hcl
module "vpc" {
  source  = "your-org/aws-vpc/terraform"
  version = "0.1.0"

  tag_org = "company"
  env     = "dev"
  
  vpc_cidr_block    = "10.0.0.0/16"
  azs               = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets   = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  
  tags = {
    Project     = "my-project"
    ManagedBy   = "terraform"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 4.0 |
| cloudflare | >= 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| tag_org | Organization tag | `string` | n/a | yes |
| env | Environment (dev, staging, prod) | `string` | n/a | yes |
| vpc_cidr_block | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| azs | Availability zones to use | `list(string)` | n/a | yes |
| public_subnets | CIDR blocks for public subnets | `list(string)` | n/a | yes |
| private_subnets | CIDR blocks for private subnets | `list(string)` | n/a | yes |
| enable_nat_gateway | Whether to create NAT gateways | `bool` | `true` | no |
| single_nat_gateway | Whether to use a single NAT gateway for all private subnets | `bool` | `false` | no |
| tags | Additional tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | VPC ID |
| vpc_cidr_block | The CIDR block of the VPC |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |
| vpc_default_sg_id | The default security group ID of the VPC |
| nat_gateway_ids | List of NAT Gateway IDs |
| igw_id | Internet Gateway ID |

## Cloudflare Integration

This module doesn't directly handle DNS records. To manage DNS records with Cloudflare, use the Cloudflare provider in your root module:

```hcl
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "cloudflare_record" "example" {
  zone_id = var.cloudflare_zone_id
  name    = "example"
  value   = module.alb.dns_name
  type    = "CNAME"
  ttl     = 1
  proxied = true
}
```