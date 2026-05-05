# ============================================================
#  modules/ALB/main.tf
#  Creates: Application Load Balancer, Target Group,
#           HTTP listener (port 80)
# ============================================================

resource "aws_lb" "main" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  access_logs {
    bucket  = ""
    enabled = false
  }

  tags = merge(var.tags, { Name = "${var.environment}-alb" })
}

# Target Group — receives forwarded traffic from ALB
resource "aws_lb_target_group" "app" {
  name     = "${var.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200-399"
  }

  tags = merge(var.tags, { Name = "${var.environment}-tg" })
}

# HTTP Listener — forwards port 80 traffic to target group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
