# terraform-aws-compute

A reusable Terraform module for provisioning EC2 instances on AWS.
Published to the Terraform Cloud **Private Module Registry**.

## Usage

```hcl
module "compute" {
  source  = "app.terraform.io/YOUR_ORG_NAME/compute/aws"
  version = "1.0.0"

  ami_id          = "ami-0c55b159cbfafe1f0"
  instance_type   = "t2.micro"
  instance_name   = "my-server"
  subnet_id       = "subnet-xxxxxxxx"
  security_groups = ["sg-xxxxxxxx"]
  key_name        = "my-key-pair"

  tags = {
    Environment = "dev"
    Project     = "steghub-401"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| ami_id | AMI ID for the EC2 instance | string | — | yes |
| instance_type | EC2 instance type | string | t2.micro | no |
| instance_name | Name tag for the instance | string | — | yes |
| subnet_id | Subnet to launch the instance in | string | — | yes |
| security_groups | List of security group IDs | list(string) | [] | no |
| key_name | Key pair name for SSH | string | "" | no |
| associate_public_ip | Assign a public IP | bool | true | no |
| root_volume_size | Root EBS volume size (GB) | number | 20 | no |
| user_data | User data script | string | null | no |
| tags | Tags to apply to all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|---|---|
| instance_id | EC2 instance ID |
| public_ip | Public IP address |
| private_ip | Private IP address |
| instance_arn | Instance ARN |
