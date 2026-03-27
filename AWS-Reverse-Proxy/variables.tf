
#  ROOT VARIABLES

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project – used as a prefix for all resource names"
  type        = string
  default     = "rproxy"
}

variable "environment" {
  description = "Deployment environment (dev / staging / prod)"
  type        = string
  default     = "dev"
}

# ── Networking
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "List of availability zones (must have at least 2)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets (Nginx + Bastion)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_web_subnets" {
  description = "CIDR blocks for private subnets (WordPress + Tooling webservers)"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "private_data_subnets" {
  description = "CIDR blocks for private subnets (RDS + EFS – data layer)"
  type        = list(string)
  default     = ["10.0.5.0/24", "10.0.6.0/24"]
}

# ── DNS ──────────────────────────────────────────────────────
variable "domain_name" {
  description = "Root domain name registered in Freenom and hosted in Route 53 (e.g. myproject.ga)"
  type        = string
}

# ── AMIs (fill these in AFTER you create AMIs manually) ──────
variable "nginx_ami" {
  description = "AMI ID for Nginx reverse-proxy servers"
  type        = string
  default     = "ami-038895944af658afc" # placeholder – replace with your CentOS AMI
}

variable "bastion_ami" {
  description = "AMI ID for Bastion host"
  type        = string
  default     = "ami-0a3dd77a51ac63363"
}

variable "wordpress_ami" {
  description = "AMI ID for WordPress webservers"
  type        = string
  default     = "ami-0c55185bcf1f53f2e"
}

variable "tooling_ami" {
  description = "AMI ID for Tooling webservers"
  type        = string
  default     = "ami-06ebc62d40eecb0fe"
}

variable "instance_type" {
  description = "EC2 instance type for all servers"
  type        = string
  default     = "t2.micro"
}

variable "key_pair_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
}

variable "my_ip" {
  description = "Your workstation public IP with /32 suffix – used for Bastion SSH access"
  type        = string
}

# ── Database ─────────────────────────────────────────────────
variable "db_username" {
  description = "Master username for the RDS MySQL instance"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Master password for the RDS MySQL instance"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "wordpressdb"
}
