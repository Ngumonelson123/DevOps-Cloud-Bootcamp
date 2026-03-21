# -------------------------------------------------------
# CI ENVIRONMENT OUTPUTS
# -------------------------------------------------------
output "jenkins_ip" {
  description = "Jenkins server public IP"
  value       = aws_instance.jenkins.public_ip
}

output "sonarqube_ip" {
  description = "SonarQube server public IP"
  value       = aws_instance.sonarqube.public_ip
}

output "nginx_ci_ip" {
  description = "Nginx CI reverse proxy public IP"
  value       = aws_instance.nginx_ci.public_ip
}

# -------------------------------------------------------
# DEV ENVIRONMENT OUTPUTS
# -------------------------------------------------------
output "tooling_ip" {
  description = "Tooling web app server public IP"
  value       = aws_instance.tooling.public_ip
}

output "todo_ip" {
  description = "TODO web app server public IP"
  value       = aws_instance.todo.public_ip
}

output "nginx_dev_ip" {
  description = "Nginx Dev reverse proxy public IP"
  value       = aws_instance.nginx_dev.public_ip
}

output "db_ip" {
  description = "Database server public IP"
  value       = aws_instance.db.public_ip
}

# -------------------------------------------------------
# KEY PAIR
# -------------------------------------------------------
output "private_key_path" {
  description = "Path to the saved private key"
  value       = local_file.private_key.filename
}

output "key_pair_name" {
  description = "AWS key pair name"
  value       = aws_key_pair.project14.key_name
}

# -------------------------------------------------------
# ANSIBLE INVENTORY HELPER
# -------------------------------------------------------
output "ansible_inventory_ci" {
  description = "CI inventory block"
  value = <<-EOT

    [jenkins]
    ${aws_instance.jenkins.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=../project14-key.pem

    [sonarqube]
    ${aws_instance.sonarqube.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=../project14-key.pem

    [nginx]
    ${aws_instance.nginx_ci.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=../project14-key.pem

  EOT
}

output "ansible_inventory_dev" {
  description = "Dev inventory block"
  value = <<-EOT

    [tooling]
    ${aws_instance.tooling.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=../project14-key.pem

    [todo]
    ${aws_instance.todo.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=../project14-key.pem

    [nginx]
    ${aws_instance.nginx_dev.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=../project14-key.pem

    [db:vars]
    ansible_user=ubuntu
    ansible_ssh_private_key_file=../project14-key.pem

    [db]
    ${aws_instance.db.public_ip}

  EOT
}
