variable "environment" {
  description = "Environment name for tagging"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
}

variable "app_sg_id" {
  description = "Security Group ID for EC2 app instances"
  type        = string
}

variable "efs_dns_name" {
  description = "EFS DNS name to mount inside EC2 user_data"
  type        = string
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
