# ============================================================
#  MODULE: ROUTE 53
#  Looks up the hosted zone you created manually (or creates it)
#  and adds alias records pointing to the external ALB
# ============================================================

# Look up the hosted zone you created in the AWS console
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# Root domain (e.g. myproject.ga) → External ALB
resource "aws_route53_record" "root" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.ext_alb_dns_name
    zone_id                = var.ext_alb_zone_id
    evaluate_target_health = true
  }
}

# www subdomain → External ALB
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.ext_alb_dns_name
    zone_id                = var.ext_alb_zone_id
    evaluate_target_health = true
  }
}

# tooling subdomain → External ALB
resource "aws_route53_record" "tooling" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "tooling.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.ext_alb_dns_name
    zone_id                = var.ext_alb_zone_id
    evaluate_target_health = true
  }
}
