output "alb_sg_id"       { value = aws_security_group.alb.id }
output "nginx_sg_id"     { value = aws_security_group.nginx.id }
output "bastion_sg_id"   { value = aws_security_group.bastion.id }
output "webserver_sg_id" { value = aws_security_group.webserver.id }
output "data_sg_id"      { value = aws_security_group.data.id }
