output "launch_template_id" {
  description = "ID of the EC2 Launch Template"
  value       = aws_launch_template.app.id
}

output "launch_template_version" {
  description = "Latest version of the EC2 Launch Template"
  value       = aws_launch_template.app.latest_version
}

output "ec2_iam_role_arn" {
  description = "ARN of the IAM role attached to EC2 instances"
  value       = aws_iam_role.ec2.arn
}
