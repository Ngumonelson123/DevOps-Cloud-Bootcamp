# ============================================================
#  MODULE: COMPUTE
#  Creates:
#    Nginx   – Launch Template + Target Group + ASG + CloudWatch
#    Bastion – Launch Template + EIPs + ASG
#    WordPress – Launch Template + ASG
#    Tooling   – Launch Template + ASG
# ============================================================

# ── SNS Topic for scaling notifications ──────────────────────
resource "aws_sns_topic" "scaling" {
  name = "${var.project_name}-asg-scaling-alerts"
  tags = { Name = "${var.project_name}-scaling-sns" }
}

# ─────────────────────────────────────────────────────────────
#  NGINX
# ─────────────────────────────────────────────────────────────

resource "aws_launch_template" "nginx" {
  name_prefix            = "${var.project_name}-nginx-lt-"
  image_id               = var.nginx_ami
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [var.nginx_sg_id]

  user_data = base64encode(templatefile("${path.module}/../../scripts/nginx-userdata.sh", {
    efs_id          = var.efs_id
    internal_alb_dns = var.internal_alb_dns
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.project_name}-nginx" }
  }

  lifecycle { create_before_destroy = true }
}

resource "aws_autoscaling_group" "nginx" {
  name                      = "${var.project_name}-nginx-asg"
  vpc_zone_identifier       = var.public_subnet_ids
  target_group_arns         = [var.ext_alb_tg_nginx_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300
  desired_capacity          = 2
  min_size                  = 2
  max_size                  = 4

  launch_template {
    id      = aws_launch_template.nginx.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-nginx"
    propagate_at_launch = true
  }
}

# Scale-out policy – CPU > 90%
resource "aws_autoscaling_policy" "nginx_scale_out" {
  name                   = "${var.project_name}-nginx-scale-out"
  autoscaling_group_name = aws_autoscaling_group.nginx.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
}

resource "aws_cloudwatch_metric_alarm" "nginx_high_cpu" {
  alarm_name          = "${var.project_name}-nginx-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 90
  alarm_actions       = [aws_autoscaling_policy.nginx_scale_out.arn, aws_sns_topic.scaling.arn]

  dimensions = { AutoScalingGroupName = aws_autoscaling_group.nginx.name }
}

# Scale-in policy – CPU < 30%
resource "aws_autoscaling_policy" "nginx_scale_in" {
  name                   = "${var.project_name}-nginx-scale-in"
  autoscaling_group_name = aws_autoscaling_group.nginx.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
}

resource "aws_cloudwatch_metric_alarm" "nginx_low_cpu" {
  alarm_name          = "${var.project_name}-nginx-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 30
  alarm_actions       = [aws_autoscaling_policy.nginx_scale_in.arn]

  dimensions = { AutoScalingGroupName = aws_autoscaling_group.nginx.name }
}

# ─────────────────────────────────────────────────────────────
#  BASTION
# ─────────────────────────────────────────────────────────────

resource "aws_launch_template" "bastion" {
  name_prefix            = "${var.project_name}-bastion-lt-"
  image_id               = var.bastion_ami
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [var.bastion_sg_id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y ansible git python3
    systemctl enable --now chronyd
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.project_name}-bastion" }
  }

  lifecycle { create_before_destroy = true }
}

# Elastic IPs for Bastion hosts
resource "aws_eip" "bastion" {
  count  = 2
  domain = "vpc"
  tags   = { Name = "${var.project_name}-bastion-eip-${count.index + 1}" }
}

resource "aws_autoscaling_group" "bastion" {
  name                      = "${var.project_name}-bastion-asg"
  vpc_zone_identifier       = var.public_subnet_ids
  health_check_type         = "EC2"
  health_check_grace_period = 300
  desired_capacity          = 2
  min_size                  = 2
  max_size                  = 4

  launch_template {
    id      = aws_launch_template.bastion.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-bastion"
    propagate_at_launch = true
  }
}

# Bastion scaling notification
resource "aws_autoscaling_notification" "bastion" {
  group_names   = [aws_autoscaling_group.bastion.name]
  topic_arn     = aws_sns_topic.scaling.arn
  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
  ]
}

# ─────────────────────────────────────────────────────────────
#  WORDPRESS WEBSERVER
# ─────────────────────────────────────────────────────────────

resource "aws_launch_template" "wordpress" {
  name_prefix            = "${var.project_name}-wordpress-lt-"
  image_id               = var.wordpress_ami
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [var.webserver_sg_id]

  user_data = base64encode(templatefile("${path.module}/../../scripts/wordpress-userdata.sh", {
    efs_id       = var.efs_id
    rds_endpoint = var.rds_endpoint
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.project_name}-wordpress" }
  }

  lifecycle { create_before_destroy = true }
}

resource "aws_autoscaling_group" "wordpress" {
  name                      = "${var.project_name}-wordpress-asg"
  vpc_zone_identifier       = var.private_web_subnet_ids
  target_group_arns         = [var.int_alb_tg_wordpress_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300
  desired_capacity          = 2
  min_size                  = 2
  max_size                  = 4

  launch_template {
    id      = aws_launch_template.wordpress.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-wordpress"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "wordpress_scale_out" {
  name                   = "${var.project_name}-wordpress-scale-out"
  autoscaling_group_name = aws_autoscaling_group.wordpress.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
}

resource "aws_cloudwatch_metric_alarm" "wordpress_high_cpu" {
  alarm_name          = "${var.project_name}-wordpress-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 90
  alarm_actions       = [aws_autoscaling_policy.wordpress_scale_out.arn, aws_sns_topic.scaling.arn]

  dimensions = { AutoScalingGroupName = aws_autoscaling_group.wordpress.name }
}

# ─────────────────────────────────────────────────────────────
#  TOOLING WEBSERVER
# ─────────────────────────────────────────────────────────────

resource "aws_launch_template" "tooling" {
  name_prefix            = "${var.project_name}-tooling-lt-"
  image_id               = var.tooling_ami
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [var.webserver_sg_id]

  user_data = base64encode(templatefile("${path.module}/../../scripts/tooling-userdata.sh", {
    efs_id       = var.efs_id
    rds_endpoint = var.rds_endpoint
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.project_name}-tooling" }
  }

  lifecycle { create_before_destroy = true }
}

resource "aws_autoscaling_group" "tooling" {
  name                      = "${var.project_name}-tooling-asg"
  vpc_zone_identifier       = var.private_web_subnet_ids
  target_group_arns         = [var.int_alb_tg_tooling_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300
  desired_capacity          = 2
  min_size                  = 2
  max_size                  = 4

  launch_template {
    id      = aws_launch_template.tooling.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-tooling"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "tooling_scale_out" {
  name                   = "${var.project_name}-tooling-scale-out"
  autoscaling_group_name = aws_autoscaling_group.tooling.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
}

resource "aws_cloudwatch_metric_alarm" "tooling_high_cpu" {
  alarm_name          = "${var.project_name}-tooling-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 90
  alarm_actions       = [aws_autoscaling_policy.tooling_scale_out.arn, aws_sns_topic.scaling.arn]

  dimensions = { AutoScalingGroupName = aws_autoscaling_group.tooling.name }
}
