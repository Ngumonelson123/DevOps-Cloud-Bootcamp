output "efs_id"                    { value = aws_efs_file_system.main.id }
output "efs_dns_name"              { value = aws_efs_file_system.main.dns_name }
output "efs_wordpress_ap_id"       { value = aws_efs_access_point.wordpress.id }
output "efs_tooling_ap_id"         { value = aws_efs_access_point.tooling.id }
