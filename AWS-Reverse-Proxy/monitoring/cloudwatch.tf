# ============================================================
#  monitoring/cloudwatch.tf
#  Add this to your project root or as a new module
#  Paste into main.tf or add as: module "monitoring" { source = "./monitoring" }
# ============================================================

# ── SNS Topic for ALL alerts ─────────────────────────────────
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
  tags = { Name = "${var.project_name}-alerts" }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email   # add this variable to variables.tf
}

# ── CloudWatch Dashboard ─────────────────────────────────────
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        x = 0; y = 0; width = 12; height = 6
        properties = {
          title  = "ALB Request Count"
          period = 300
          stat   = "Sum"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount",
             "LoadBalancer", "${var.project_name}-ext-alb"]
          ]
        }
      },
      {
        type = "metric"
        x = 12; y = 0; width = 12; height = 6
        properties = {
          title  = "ALB 5XX Error Rate"
          period = 300
          stat   = "Sum"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count",
             "LoadBalancer", "${var.project_name}-ext-alb"]
          ]
        }
      },
      {
        type = "metric"
        x = 0; y = 6; width = 8; height = 6
        properties = {
          title  = "Nginx ASG CPU"
          period = 300
          stat   = "Average"
          metrics = [
            ["AWS/EC2", "CPUUtilization",
             "AutoScalingGroupName", "${var.project_name}-nginx-asg"]
          ]
        }
      },
      {
        type = "metric"
        x = 8; y = 6; width = 8; height = 6
        properties = {
          title  = "WordPress ASG CPU"
          period = 300
          stat   = "Average"
          metrics = [
            ["AWS/EC2", "CPUUtilization",
             "AutoScalingGroupName", "${var.project_name}-wordpress-asg"]
          ]
        }
      },
      {
        type = "metric"
        x = 16; y = 6; width = 8; height = 6
        properties = {
          title  = "Tooling ASG CPU"
          period = 300
          stat   = "Average"
          metrics = [
            ["AWS/EC2", "CPUUtilization",
             "AutoScalingGroupName", "${var.project_name}-tooling-asg"]
          ]
        }
      },
      {
        type = "metric"
        x = 0; y = 12; width = 12; height = 6
        properties = {
          title  = "RDS CPU Utilization"
          period = 300
          stat   = "Average"
          metrics = [
            ["AWS/RDS", "CPUUtilization",
             "DBInstanceIdentifier", "${var.project_name}-mysql"]
          ]
        }
      },
      {
        type = "metric"
        x = 12; y = 12; width = 12; height = 6
        properties = {
          title  = "RDS Free Storage (bytes)"
          period = 300
          stat   = "Average"
          metrics = [
            ["AWS/RDS", "FreeStorageSpace",
             "DBInstanceIdentifier", "${var.project_name}-mysql"]
          ]
        }
      }
    ]
  })
}

# ── ALB 5XX alarm ─────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project_name}-alb-5xx-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "ALB is returning too many 5XX errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = "${var.project_name}-ext-alb"
  }
}

# ── ALB Unhealthy Host Count alarm ────────────────────────────
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "${var.project_name}-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "One or more target hosts are unhealthy"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = "${var.project_name}-ext-alb"
    TargetGroup  = "${var.project_name}-nginx-tg"
  }
}

# ── RDS High CPU alarm ────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_name}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU is above 80%"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = "${var.project_name}-mysql"
  }
}

# ── RDS Low Storage alarm ─────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${var.project_name}-rds-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2000000000   # 2 GB in bytes
  alarm_description   = "RDS free storage is below 2 GB"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = "${var.project_name}-mysql"
  }
}

# ── Log Metric Filter: Nginx 5XX errors ───────────────────────
resource "aws_cloudwatch_log_group" "nginx" {
  name              = "/aws/ec2/${var.project_name}/nginx"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_metric_filter" "nginx_5xx" {
  name           = "${var.project_name}-nginx-5xx"
  pattern        = "[ip, id, user, timestamp, request, status_code=5*, size]"
  log_group_name = aws_cloudwatch_log_group.nginx.name

  metric_transformation {
    name      = "Nginx5xxCount"
    namespace = "${var.project_name}/Nginx"
    value     = "1"
  }
}
