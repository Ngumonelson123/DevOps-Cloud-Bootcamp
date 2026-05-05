# PBL — Terraform AWS Infrastructure (3-Tier Architecture)

A production-grade, fully modular Terraform project deploying a 3-tier architecture on AWS.

---

## Architecture Overview

```
Internet
   │
   ▼
[ALB] ── public subnets (3 AZs)
   │
   ▼
[Auto Scaling Group] ── private subnets (3 AZs)
   │         │
   │         └── [EFS] (shared storage, mounted at /mnt/efs)
   │
   └──────── [RDS MySQL] (private subnets, no public access)

State: S3 + DynamoDB locking
```

## Resources Created

| Module       | Resources                                         |
|--------------|---------------------------------------------------|
| network      | VPC, IGW, public/private subnets, NAT GWs, routes |
| security     | SGs for ALB, EC2, RDS, EFS                        |
| ALB          | Application Load Balancer, Target Group, Listener |
| EFS          | File System, Mount Targets, Access Point          |
| RDS          | MySQL 8.0 instance, DB Subnet Group               |
| compute      | IAM Role, Launch Template, user_data              |
| autoscaling  | ASG, scale-out/in policies, CloudWatch alarms     |

---

## Prerequisites

### 1. Install Terraform

```bash
# Linux
wget https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip
unzip terraform_1.7.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform version
```

### 2. Install & Configure AWS CLI

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install
aws configure   # enter Access Key, Secret, region, output format
```

### 3. Run Bootstrap Script (creates backend resources + key pair)

```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

This creates:
- S3 bucket for Terraform state
- DynamoDB table for state locking
- EC2 Key Pair saved to `devops-key.pem`

---

## Deployment Steps

```bash
# 1. Edit backends.tf — update bucket name to match bootstrap.sh output
# 2. Edit terraform.tfvars — set your values (db_password, admin_cidr, etc.)

# 3. Initialize (downloads providers, configures backend)
terraform init

# 4. Validate syntax
terraform validate

# 5. Format code
terraform fmt -recursive

# 6. Preview changes
terraform plan

# 7. Deploy
terraform apply

# 8. Get the ALB URL
terraform output alb_dns_name
```

---

## Sensitive Variables

Never commit `terraform.tfvars` with real passwords to git.

Use environment variables instead:

```bash
export TF_VAR_db_password="YourSecurePassword!"
terraform apply
```

Or use AWS Secrets Manager and reference it in `data.tf`.

---

## Teardown

```bash
terraform destroy
```

> ⚠️ This deletes ALL resources including the RDS database. Back up data first.

---

## Folder Structure

```
PBL/
├── modules/
│   ├── ALB/          → ALB, Target Group, Listener
│   ├── EFS/          → EFS File System, Mount Targets, Access Point
│   ├── RDS/          → RDS MySQL, DB Subnet Group
│   ├── autoscaling/  → ASG, scaling policies, CloudWatch alarms
│   ├── compute/      → IAM Role, Launch Template
│   ├── network/      → VPC, Subnets, IGW, NAT, Route Tables
│   └── security/     → Security Groups
├── main.tf           → Wires all modules together
├── backends.tf       → S3 + DynamoDB backend config
├── providers.tf      → AWS provider
├── data.tf           → AMI lookup, account info, locals
├── outputs.tf        → Key outputs (ALB DNS, RDS endpoint, etc.)
├── variables.tf      → All input variable declarations
├── terraform.tfvars  → Your values (do not commit secrets!)
├── bootstrap.sh      → One-time AWS backend setup script
└── README.md
```

---

## Next Steps (Project 19+)

As mentioned in the SteghHub lesson:
- Use **Packer** to bake custom AMIs with app code pre-installed
- Use **Ansible** to configure instances post-launch
- Add **HTTPS** listener with ACM certificate to the ALB
- Move `db_password` to **AWS Secrets Manager**
- Add **Route 53** DNS record pointing to the ALB
