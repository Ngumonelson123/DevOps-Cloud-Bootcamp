output "bastion_eips"          { value = aws_eip.bastion[*].public_ip }
output "nginx_asg_name"        { value = aws_autoscaling_group.nginx.name }
output "wordpress_asg_name"    { value = aws_autoscaling_group.wordpress.name }
output "tooling_asg_name"      { value = aws_autoscaling_group.tooling.name }
output "sns_topic_arn"         { value = aws_sns_topic.scaling.arn }
