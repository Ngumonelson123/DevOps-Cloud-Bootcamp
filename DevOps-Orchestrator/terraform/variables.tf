variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  default     = "10.0.1.0/24"
}

variable "ami_id" {
  description = "Ubuntu 20.04 LTS AMI (us-east-1)"
  default     = "ami-0c7217cdde317cfec"
}

variable "project_name" {
  description = "Prefix tag applied to all resources"
  default     = "project14"
}
