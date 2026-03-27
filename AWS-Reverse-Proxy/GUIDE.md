# AWS Reverse Proxy Project – Zero to Hero Guide
## Two Company Websites (WordPress + Tooling) Using Nginx + Terraform

---

## PHASE 0 – Pre-flight Checklist (Do This First)

### 0.1 Install Required Tools on Your Laptop
```bash
# Terraform
wget https://releases.hashicorp.com/terraform/1.7.5/terraform_1.7.5_linux_amd64.zip
unzip terraform_1.7.5_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform --version   # should print 1.7.x

# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install
aws --version

# Git
sudo yum install -y git   # or apt install git
```

### 0.2 Configure AWS CLI
```bash
aws configure
# Enter:
#  AWS Access Key ID:     <your DevOps account access key>
#  AWS Secret Access Key: <your secret>
#  Default region:        us-east-1
#  Default output format: json
```

### 0.3 Create an S3 Bucket for Terraform State (One-time, manual)
```bash
aws s3api create-bucket \
  --bucket your-terraform-state-bucket-2025 \
  --region us-east-1

# Enable versioning on the bucket
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket-2025 \
  --versioning-configuration Status=Enabled
```
Then uncomment the `backend "s3"` block in `providers.tf` and replace the bucket name.

### 0.4 Create an EC2 Key Pair
```bash
aws ec2 create-key-pair \
  --key-name my-keypair \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/my-keypair.pem

chmod 400 ~/.ssh/my-keypair.pem
```

### 0.5 Register a Free Domain (Manual – 5 minutes)
1. Go to https://freenom.com
2. Search for a free domain (e.g. `mycompany.ga`, `.ml`, `.tk`)
3. Register it for free (12 months)
4. Keep the domain name – you will use it in `terraform.tfvars`

### 0.6 Create a Hosted Zone in Route 53 (Manual)
```bash
aws route53 create-hosted-zone \
  --steghubproject.net \
  --caller-reference $(date +%s)
```
1. Note the 4 NS records AWS gives you
2. Go to Freenom → Manage Domain → Management Tools → Nameservers
3. Paste all 4 AWS NS records into Freenom
4. Wait 5-10 minutes for propagation

### 0.7 Find Your Public IP
```bash
curl -s ifconfig.me
# Example output: 197.232.14.55
# Use this in terraform.tfvars as: my_ip = "197.232.14.55/32"
```

---

## PHASE 1 – Create Base AMIs (Manual – Do Once)

> **Why manual?** Terraform provisions infrastructure. You need actual
> working servers with the right software baked in BEFORE Terraform
> references them via AMI IDs.

### 1.1 Create the Nginx Base AMI

1. Launch a t2.micro CentOS EC2 instance in a public subnet (any subnet for now)
2. SSH into it:
```bash
ssh -i ~/.ssh/my-keypair.pem centos@<public-ip>
```
3. Install software:
```bash
sudo yum update -y
sudo yum install -y python3 ntp net-tools vim wget telnet epel-release htop
sudo yum install -y nginx
sudo systemctl enable nginx
```
4. Create the AMI:
   - AWS Console → EC2 → Instances → Select your instance
   - Actions → Image and Templates → Create Image
   - Name: `rproxy-nginx-base`
   - Click "Create Image"
   - Note the AMI ID (e.g. `ami-0abc123456789`)
5. **Terminate the instance immediately** (to avoid charges)

### 1.2 Create the Bastion Base AMI

```bash
# Launch new CentOS t2.micro, SSH in, then:
sudo yum update -y
sudo yum install -y python3 ntp net-tools vim wget telnet epel-release htop ansible git
```
- Create AMI named `rproxy-bastion-base`, note the ID
- Terminate instance

### 1.3 Create the Webserver Base AMI (for WordPress AND Tooling)

```bash
# Launch new CentOS t2.micro, SSH in, then:
sudo yum update -y
sudo yum install -y python3 ntp net-tools vim wget telnet epel-release htop php php-fpm \
                    php-mysqlnd php-json php-gd php-mbstring php-xml \
                    php-xmlrpc php-soap php-intl php-zip httpd mod_ssl
sudo systemctl enable httpd php-fpm
```
- Create AMI named `rproxy-webserver-base`, note the ID
- Terminate instance

### 1.4 Update terraform.tfvars with your AMI IDs
```hcl
nginx_ami     = "ami-0XXXXXXXXXXXXXXX"   # from step 1.1
bastion_ami   = "ami-0XXXXXXXXXXXXXXX"   # from step 1.2
wordpress_ami = "ami-0XXXXXXXXXXXXXXX"   # from step 1.3 (same as tooling)
tooling_ami   = "ami-0XXXXXXXXXXXXXXX"   # from step 1.3 (same as wordpress)
```

---

## PHASE 2 – Configure terraform.tfvars

Open `terraform.tfvars` and fill in ALL the values:
```hcl
region       = "us-east-1"
project_name = "rproxy"
environment  = "dev"

domain_name   = "mycompany.ga"       # your actual Freenom domain
key_pair_name = "my-keypair"
my_ip         = "197.232.14.55/32"   # your actual public IP

nginx_ami     = "ami-0XXXXXXXXXXXXXXX"
bastion_ami   = "ami-0XXXXXXXXXXXXXXX"
wordpress_ami = "ami-0XXXXXXXXXXXXXXX"
tooling_ami   = "ami-0XXXXXXXXXXXXXXX"

db_username = "admin"
db_password = "YourStr0ngP@ssword!"   # use a strong unique password
db_name     = "wordpressdb"
```

---

## PHASE 3 – Deploy with Terraform

### 3.1 Initialize Terraform
```bash
cd aws-reverse-proxy
terraform init
```
Expected output: `Terraform has been successfully initialized!`

### 3.2 Validate Configuration
```bash
terraform validate
```
Expected output: `Success! The configuration is valid.`

### 3.3 Preview What Will Be Created
```bash
terraform plan -out=tfplan
```
Review the plan carefully. You should see ~50-60 resources being created.

### 3.4 Deploy!
```bash
terraform apply tfplan
```
This will take approximately **15-20 minutes** because:
- RDS takes ~10 minutes to spin up
- ACM certificate validation takes ~2-5 minutes
- NAT Gateway takes ~2 minutes

Watch for the outputs at the end:
```
external_alb_dns = "rproxy-ext-alb-XXXXXXXX.us-east-1.elb.amazonaws.com"
wordpress_url    = "https://mycompany.ga"
tooling_url      = "https://tooling.mycompany.ga"
rds_endpoint     = "rproxy-mysql.XXXXXXXX.us-east-1.rds.amazonaws.com:3306"
bastion_eips     = ["52.X.X.X", "54.X.X.X"]
```

---

## PHASE 4 – Post-Deployment Steps

### 4.1 Test Bastion SSH Access
```bash
# SSH into Bastion
ssh -i ~/.ssh/my-keypair.pem ec2-user@<bastion-eip>

# From Bastion, SSH into a private Nginx server
ssh -i ~/.ssh/my-keypair.pem ec2-user@<nginx-private-ip>
```

### 4.2 Test Health Check Endpoints
```bash
# Test Nginx health check via ALB
curl -k https://mycompany.ga/healthstatus

# Should return: healthy
```

### 4.3 Set Up WordPress
1. Visit https://mycompany.ga in your browser
2. Complete the WordPress 5-minute setup wizard
3. Choose your site title, admin username, and password

### 4.4 Verify Tooling Website
1. Visit https://tooling.mycompany.ga
2. The Tooling app should load
3. Default login: `admin` / `admin` (change immediately!)

### 4.5 Verify DNS
```bash
# Check that DNS resolves correctly
nslookup mycompany.ga
nslookup tooling.mycompany.ga
```

---

## PHASE 5 – Verify Architecture Components

Run these checks to confirm everything is working:

```bash
# 1. Check VPC
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=rproxy"

# 2. Check all subnets
aws ec2 describe-subnets --filters "Name=tag:Project,Values=rproxy" \
  --query 'Subnets[*].{Name:Tags[?Key==`Name`].Value|[0],CIDR:CidrBlock,AZ:AvailabilityZone}'

# 3. Check ALBs
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[*].{Name:LoadBalancerName,DNS:DNSName,Scheme:Scheme}'

# 4. Check ASG instance counts
aws autoscaling describe-auto-scaling-groups \
  --query 'AutoScalingGroups[*].{Name:AutoScalingGroupName,Desired:DesiredCapacity,Min:MinSize,Max:MaxSize}'

# 5. Check RDS status
aws rds describe-db-instances \
  --query 'DBInstances[*].{ID:DBInstanceIdentifier,Status:DBInstanceStatus,Endpoint:Endpoint.Address}'

# 6. Check EFS mount targets
aws efs describe-mount-targets \
  --query 'MountTargets[*].{FSID:FileSystemId,AZ:AvailabilityZoneName,State:LifeCycleState}'

# 7. Check ACM certificate
aws acm list-certificates \
  --query 'CertificateSummaryList[*].{Domain:DomainName,Status:Status}'
```

---

## PHASE 6 – Cost Management (CRITICAL)

### ⚠️ Always destroy when you are done testing
```bash
terraform destroy
```
Type `yes` when prompted. This will remove ALL resources.

### Set Up a Budget Alert
```bash
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget '{
    "BudgetName": "MonthlyBudget",
    "BudgetLimit": {"Amount": "20", "Unit": "USD"},
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST"
  }' \
  --notifications-with-subscribers '[{
    "Notification": {
      "NotificationType": "ACTUAL",
      "ComparisonOperator": "GREATER_THAN",
      "Threshold": 80
    },
    "Subscribers": [{
      "SubscriptionType": "EMAIL",
      "Address": "your@email.com"
    }]
  }]'
```

### Monthly Cost Estimate (while running)
| Resource           | Cost/Month (approx) |
|--------------------|---------------------|
| 4x EC2 t2.micro    | ~$17                |
| 2x ALB             | ~$32                |
| 1x NAT Gateway     | ~$32 + data         |
| RDS db.t3.micro    | ~$13                |
| EFS (minimal use)  | ~$1                 |
| Route 53           | ~$0.50              |
| **TOTAL**          | **~$95/month**      |

> Run for a few hours for testing, then **terraform destroy**!

---

## Troubleshooting

### Instance fails health check
```bash
# SSH to Bastion, then SSH to the failing instance
# Check web server status
sudo systemctl status nginx    # for Nginx
sudo systemctl status httpd    # for webservers

# Check logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/httpd/error_log

# Check user-data script output
sudo cat /var/log/cloud-init-output.log
```

### EFS not mounting
```bash
# Check security group allows port 2049 from server's SG
# Manually test mount:
sudo mount -t efs -o tls fs-XXXXXXXX:/ /mnt/test
```

### RDS connection refused
```bash
# From a webserver, test connectivity
telnet <rds-endpoint> 3306

# Check security group allows port 3306 from webserver SG
mysql -h <rds-endpoint> -u admin -p wordpressdb
```

### Terraform state issues
```bash
# Refresh state if resources were changed outside Terraform
terraform refresh

# Import an existing resource
terraform import aws_vpc.main vpc-XXXXXXXX
```

---

## Project Directory Structure
```
aws-reverse-proxy/
├── providers.tf            # AWS provider + backend config
├── variables.tf            # All input variables
├── terraform.tfvars        # Your actual values (not in git!)
├── main.tf                 # Module wiring
├── outputs.tf              # Useful outputs
├── .gitignore
├── scripts/
│   ├── nginx-userdata.sh       # Nginx bootstrap script
│   ├── wordpress-userdata.sh   # WordPress bootstrap script
│   └── tooling-userdata.sh     # Tooling bootstrap script
└── modules/
    ├── vpc/                # VPC, subnets, IGW, NAT, route tables
    ├── security-groups/    # All 5 security groups
    ├── acm/                # TLS wildcard certificate
    ├── alb/                # External + internal ALBs
    ├── efs/                # EFS filesystem + mount targets
    ├── rds/                # KMS + RDS MySQL 8
    ├── compute/            # Launch templates + ASGs + CloudWatch
    └── route53/            # DNS alias records
```
