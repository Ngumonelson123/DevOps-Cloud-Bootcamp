# ============================================================
#  MODULE: ALB
#  Creates:
#    - External (internet-facing) ALB  → Nginx
#    - Internal ALB                    → WordPress & Tooling
#    - Target groups + health checks
#    - HTTPS listeners with path/host routing
# ============================================================

# ── External ALB ─────────────────────────────────────────────
resource "aws_lb" "external" {
  name               = "${var.project_name}-ext-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  tags = { Name = "${var.project_name}-ext-alb" }
}

# Target group: Nginx (health check on /healthstatus)
resource "aws_lb_target_group" "nginx" {
  name     = "${var.project_name}-nginx-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/healthstatus"
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = { Name = "${var.project_name}-nginx-tg" }
}

# # External ALB Listener – HTTP redirect to HTTPS
# resource "aws_lb_listener" "ext_http" {
#   load_balancer_arn = aws_lb.external.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type = "redirect"
#     redirect {
#       port        = "443"
#       protocol    = "HTTPS"
#       status_code = "HTTP_301"
#     }
#   }
# }

# External ALB Listener – HTTPS → Nginx
resource "aws_lb_listener" "ext_https" {
  load_balancer_arn = aws_lb.external.arn
  port              = 80
  protocol          = "HTTP"
  #ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx.arn
  }
}

# ── Internal ALB ─────────────────────────────────────────────
resource "aws_lb" "internal" {
  name               = "${var.project_name}-int-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.nginx_sg_id]
  subnets            = var.private_web_subnet_ids

  tags = { Name = "${var.project_name}-int-alb" }
}

# Target group: WordPress
resource "aws_lb_target_group" "wordpress" {
  name     = "${var.project_name}-wordpress-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/healthstatus"
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = { Name = "${var.project_name}-wordpress-tg" }
}

# Target group: Tooling
resource "aws_lb_target_group" "tooling" {
  name     = "${var.project_name}-tooling-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/healthstatus"
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = { Name = "${var.project_name}-tooling-tg" }
}

# Internal ALB Listener – HTTPS
# Default → WordPress; tooling subdomain → Tooling
resource "aws_lb_listener" "int_https" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 80
  protocol          = "HTTP"
  #ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress.arn
  }
}

# Listener rule – route tooling.* subdomain to Tooling TG
resource "aws_lb_listener_rule" "tooling" {
  listener_arn = aws_lb_listener.int_https.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tooling.arn
  }

  condition {
    host_header {
      values = ["tooling.*"]
    }
  }
}
