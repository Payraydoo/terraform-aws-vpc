# AWS VPC Terraform Module

A Terraform module to create a fully-featured AWS VPC with both public and private subnets across multiple availability zones. This module creates the following resources:

- VPC with DNS support and DNS hostnames enabled
- Public and private subnets across multiple availability zones
- Internet Gateway for public subnets
- NAT Gateway for private subnets
- Bastion host for secure access to private resources
- Appropriate route tables for each subnet type
- Network ACLs and security groups
- Proper tagging of all resources

## SSH Key Setup for Bastion Host

Before deploying the module with a bastion host, you need to create an SSH key pair in AWS:

```bash
# Create a new key pair in AWS and save the private key as securekey.pem
aws ec2 create-key-pair --key-name bastion-securekey --query 'KeyMaterial' --output text > securekey.pem

# Set the appropriate permissions to secure the key file
chmod 400 securekey.pem

# Store this key file securely - you'll need it to SSH into the bastion host
```

Then reference this key in the module configuration:

```hcl
module "vpc" {
  # Other configuration...
  
  create_bastion   = true
  bastion_key_name = "bastion-securekey"  # Name of the key you created in AWS
}
```

After the bastion host is deployed, you can connect to it using:

```bash
# Connect to the bastion host
ssh -i /path/to/securekey.pem ec2-user@$(terraform output -module=vpc bastion_public_ip)

# Or set up an SSH tunnel to access resources in private subnets
ssh -i /path/to/securekey.pem -L local_port:private_resource_ip:remote_port ec2-user@$(terraform output -module=vpc bastion_public_ip)
```

## Usage

```hcl
module "vpc" {
  source = "Payraydoo/vpc/aws"

  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  environment          = "dev"
  tag_org              = "myorg"
  
  # Optional: Enable and configure bastion host
  create_bastion             = true
  bastion_allowed_cidr_blocks = ["192.168.0.0/16"]  # Only allow connections from specific IPs
  bastion_key_name           = "bastion-securekey"
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
| tag_org | Organization name for resource tagging | `string` | `"org"` | no |
| enable_nat_gateway | Whether to enable NAT Gateway for private subnets | `bool` | `true` | no |
| single_nat_gateway | Whether to use a single NAT Gateway for all private subnets | `bool` | `true` | no |
| enable_vpn_gateway | Whether to create a VPN Gateway | `bool` | `false` | no |
| tags | Additional tags for resources | `map(string)` | `{}` | no |
| create_bastion | Whether to create a bastion host | `bool` | `false` | no |
| bastion_allowed_cidr_blocks | CIDR blocks allowed to connect to the bastion host | `list(string)` | `["0.0.0.0/0"]` | no |
| bastion_instance_type | Instance type for the bastion host | `string` | `"t3.micro"` | no |
| bastion_key_name | SSH key name for the bastion host | `string` | `""` | no |
| bastion_ami | AMI ID for the bastion host (empty uses latest Amazon Linux 2) | `string` | `""` | no |
| bastion_volume_size | Root volume size for bastion host in GB | `number` | `8` | no |

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
| bastion_public_ip | Public IP address of the bastion host |
| bastion_security_group_id | Security group ID of the bastion host |
| bastion_instance_id | Instance ID of the bastion host |

## Examples

* [Basic VPC](./examples/basic/README.md)
* [Multi-AZ VPC](./examples/multi-az/README.md)
* [VPC with VPN Gateway](./examples/vpn-gateway/README.md)

## License

MIT