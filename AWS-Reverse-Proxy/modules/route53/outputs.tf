output "hosted_zone_id"   { value = data.aws_route53_zone.main.zone_id }
output "root_record_fqdn" { value = "pending-domain" }
output "tooling_fqdn"     { value = "pending-domain" }