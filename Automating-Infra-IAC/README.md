# Terraform 201 - Automate Infrastructure With IaC

## Architecture
Multi-tier AWS infrastructure hosting WordPress and Tooling websites:

- **VPC**: 1 VPC, 2 public subnets, 4 private subnets across 2 AZs
- **Networking**: IGW, NAT Gateway, EIP, route tables
- **Security**: 6 security groups with least-privilege rules
- **Certificate**: ACM wildcard cert with Route53 DNS validation
- **Load Balancers**: External ALB (Nginx) → Internal ALB (WordPress/Tooling)
- **Compute**: 4 Auto Scaling Groups (Bastion, Nginx, WordPress, Tooling)
- **Storage**: Encrypted EFS with access points per app
- **Database**: Multi-AZ MySQL RDS
- **IAM**: EC2 instance role + policy + instance profile
- **Notifications**: SNS topic for all ASG events

## Prerequisites
1. AWS CLI configured with valid credentials
2. Terraform >= 1.0 installed
3. A registered domain in Route53
4. An existing EC2 key pair in `us-east-1`

## Customise Before Deploying
| File | What to update |
|------|---------------|
| `terraform.tfvars` | Your AMI ID, keypair, account_no, domain, DB creds |
| `cert.tf` | Replace `oyindamola.gq` with your domain |
| `efs.tf` | KMS principal ARN (replace with your IAM user/role) |
| `main.tf` | Uncomment S3 backend block and set your bucket name |

## Deploy
```bash
terraform init
terraform validate
terraform plan
terraform apply --auto-approve
```

## Destroy
```bash
terraform destroy --auto-approve
```

## File Structure
```
terraform-201/
├── main.tf                    # Provider, VPC, subnets
├── variables.tf               # All variable declarations
├── terraform.tfvars           # Variable values
├── internet_gateway.tf        # IGW
├── natgateway.tf              # NAT + EIP
├── route_tables.tf            # Route tables + associations
├── roles.tf                   # IAM role, policy, instance profile
├── security.tf                # All security groups + rules
├── cert.tf                    # ACM certificate + Route53 records
├── alb.tf                     # External ALB, Internal ALB, target groups, listeners
├── asg-bastion-nginx.tf       # SNS, Bastion ASG, Nginx ASG
├── asg-wordpress-tooling.tf   # WordPress ASG, Tooling ASG
├── efs.tf                     # KMS key, EFS, mount targets, access points
├── rds.tf                     # RDS subnet group + MySQL instance
├── bastion.sh                 # Bastion userdata
├── nginx.sh                   # Nginx userdata
├── wordpress.sh               # WordPress userdata
└── tooling.sh                 # Tooling userdata
```
