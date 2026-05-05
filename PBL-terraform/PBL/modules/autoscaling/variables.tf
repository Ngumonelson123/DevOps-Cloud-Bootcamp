variable "environment" {
  description = "Environment name for tagging"
  type        = string
}

variable "min_size" {
  description = "Minimum number of EC2 instances in the ASG"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of EC2 instances in the ASG"
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "Desired number of EC2 instances in the ASG"
  type        = number
  default     = 2
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ASG instance placement"
  type        = list(string)
}

variable "target_group_arn" {
  description = "ARN of the ALB Target Group to register instances with"
  type        = string
}

variable "launch_template_id" {
  description = "ID of the EC2 Launch Template"
  type        = string
}

variable "launch_template_version" {
  description = "Version of the EC2 Launch Template to use"
  type        = string
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
