output "efs_id" {
  description = "EFS File System ID"
  value       = aws_efs_file_system.main.id
}

output "efs_dns_name" {
  description = "EFS DNS name (used for mounting inside EC2)"
  value       = aws_efs_file_system.main.dns_name
}

output "efs_access_point_id" {
  description = "EFS Access Point ID"
  value       = aws_efs_access_point.app.id
}
