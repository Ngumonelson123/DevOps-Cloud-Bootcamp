variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
}

variable "admin_cidr" {
  description = "CIDR block allowed SSH access (restrict to your IP in production)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
