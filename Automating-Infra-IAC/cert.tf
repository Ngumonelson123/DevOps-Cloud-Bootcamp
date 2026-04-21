# Wildcard certificate
resource "aws_acm_certificate" "usenlease" {
  domain_name       = "*.usenlease.com"
  validation_method = "DNS"
}

# Hosted zone
resource "aws_route53_zone" "usenlease" {
  name = "usenlease.com"

  tags = var.tags
}

# DNS validation records
resource "aws_route53_record" "usenlease" {
  for_each = {
    for dvo in aws_acm_certificate.usenlease.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.usenlease.zone_id
}

# Certificate validation
resource "aws_acm_certificate_validation" "usenlease" {
  certificate_arn         = aws_acm_certificate.usenlease.arn
  validation_record_fqdns = [for record in aws_route53_record.usenlease : record.fqdn]
}

# Route53 A record for tooling
resource "aws_route53_record" "tooling" {
  zone_id = aws_route53_zone.usenlease.zone_id
  name    = "tooling.usenlease.com"
  type    = "A"

  alias {
    name                   = aws_lb.ext-alb.dns_name
    zone_id                = aws_lb.ext-alb.zone_id
    evaluate_target_health = true
  }
}

# Route53 A record for wordpress
resource "aws_route53_record" "wordpress" {
  zone_id = aws_route53_zone.usenlease.zone_id
  name    = "wordpress.usenlease.com"
  type    = "A"

  alias {
    name                   = aws_lb.ext-alb.dns_name
    zone_id                = aws_lb.ext-alb.zone_id
    evaluate_target_health = true
  }
}
