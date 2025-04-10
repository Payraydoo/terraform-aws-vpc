# AWS VPC Terraform Module

A Terraform module to create a fully-featured AWS VPC with both public and private subnets across multiple availability zones. This module creates the following resources:

- VPC with DNS support and DNS hostnames enabled
- Public and private subnets across multiple availability zones
- Internet Gateway for public subnets
- NAT Gateway for private subnets
- Appropriate route tables for each subnet type
- Network ACLs and security groups
- Proper tagging of all resources

## Usage

```hcl
module "vpc" {
  source = "Payraydoo/vpc/aws"

  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  environment          = "dev"
  tag_org_short_name   = "myorg"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| vpc_cidr | The CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| public_subnet_cidrs | List of CIDR blocks for the public subnets | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]` | no |
| private_subnet_cidrs | List of CIDR blocks for the private subnets | `list(string)` | `["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]` | no |
| availability_zones | List of availability zones in which to create subnets | `list(string)` | `["us-east-1a", "us-east-1b", "us-east-1c"]` | no |
| environment | Environment name (e.g., dev, staging, production) | `string` | `"dev"` | no |
| tag_org_short_name | Organization short name for resource tagging | `string` | `"org"` | no |
| enable_nat_gateway | Whether to enable NAT Gateway for private subnets | `bool` | `true` | no |
| single_nat_gateway | Whether to use a single NAT Gateway for all private subnets | `bool` | `true` | no |
| enable_vpn_gateway | Whether to create a VPN Gateway | `bool` | `false` | no |
| tags | Additional tags for resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC |
| vpc_cidr_block | The CIDR block of the VPC |
| public_subnet_ids | List of IDs of public subnets |
| private_subnet_ids | List of IDs of private subnets |
| public_subnet_cidrs | List of CIDR blocks of public subnets |
| private_subnet_cidrs | List of CIDR blocks of private subnets |
| nat_gateway_id | ID of the NAT Gateway |
| internet_gateway_id | ID of the Internet Gateway |
| public_route_table_id | ID of the public route table |
| private_route_table_id | ID of the private route table |
| nat_public_ip | Public IP address of the NAT Gateway |

## Examples

* [Basic VPC](./examples/basic/README.md)
* [Multi-AZ VPC](./examples/multi-az/README.md)
* [VPC with VPN Gateway](./examples/vpn-gateway/README.md)

## License

MIT License

Copyright (c) 2025 Payraydoo

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "../../"

  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]
  environment          = "example"
  tag_org_short_name   = "demo"

  tags = {
    Owner       = "Terraform"
    Environment = "Example"
    CreatedBy   = "Terraform"
  }
}