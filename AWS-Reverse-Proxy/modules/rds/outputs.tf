output "rds_endpoint"  { value = aws_db_instance.main.endpoint }
output "rds_port"      { value = aws_db_instance.main.port }
output "rds_db_name"   { value = aws_db_instance.main.db_name }
output "kms_key_arn"   { value = aws_kms_key.rds.arn }
