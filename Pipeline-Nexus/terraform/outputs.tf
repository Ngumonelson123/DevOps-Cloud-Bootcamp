output "jenkins_ip"     { value = aws_instance.jenkins.public_ip }
output "sonarqube_ip"   { value = aws_instance.sonarqube.public_ip }
output "artifactory_ip" { value = aws_instance.artifactory.public_ip }
output "nginx_ci_ip"    { value = aws_instance.nginx_ci.public_ip }
output "tooling_ip"     { value = aws_instance.tooling.public_ip }
output "todo_ip"        { value = aws_instance.todo.public_ip }
output "nginx_dev_ip"   { value = aws_instance.nginx_dev.public_ip }
output "db_ip"          { value = aws_instance.db.public_ip }