variable "region" {
  default = "us-east-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  default = "10.0.2.0/24"
}

variable "key_name" {
  description = "Your AWS EC2 key pair name"
  type        = string
}

variable "ami_id" {
  description = "Ubuntu 20.04 LTS AMI"
  default     = "ami-0c7217cdde317cfec"  # us-east-1 Ubuntu 20.04
}