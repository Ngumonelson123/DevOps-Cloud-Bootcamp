output "external_alb_dns"      { value = aws_lb.external.dns_name }
output "external_alb_zone_id"  { value = aws_lb.external.zone_id }
output "internal_alb_dns"      { value = aws_lb.internal.dns_name }
output "ext_tg_nginx_arn"      { value = aws_lb_target_group.nginx.arn }
output "int_tg_wordpress_arn"  { value = aws_lb_target_group.wordpress.arn }
output "int_tg_tooling_arn"    { value = aws_lb_target_group.tooling.arn }
