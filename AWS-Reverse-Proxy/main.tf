# ============================================================
#  MAIN  –  Orchestrates all modules
# ============================================================

# ── 1. VPC & Networking ──────────────────────────────────────
module "vpc" {
  source               = "./modules/vpc"
  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnets       = var.public_subnets
  private_web_subnets  = var.private_web_subnets
  private_data_subnets = var.private_data_subnets
}

# ── 2. Security Groups ───────────────────────────────────────
module "security_groups" {
  source       = "./modules/security-groups"
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  my_ip        = var.my_ip
}

# ── 3. ACM Certificate ───────────────────────────────────────
module "acm" {
  source         = "./modules/acm"
  project_name   = var.project_name
  domain_name    = var.domain_name
  hosted_zone_id = module.route53.hosted_zone_id
}

# ── 4. Application Load Balancers ────────────────────────────
module "alb" {
  source                 = "./modules/alb"
  project_name           = var.project_name
  vpc_id                 = module.vpc.vpc_id
  public_subnet_ids      = module.vpc.public_subnet_ids
  private_web_subnet_ids = module.vpc.private_web_subnet_ids
  alb_sg_id              = module.security_groups.alb_sg_id
  nginx_sg_id            = module.security_groups.nginx_sg_id
  webserver_sg_id        = module.security_groups.webserver_sg_id
  acm_cert_arn           = module.acm.certificate_arn
}

# ── 5. EFS ───────────────────────────────────────────────────
module "efs" {
  source                  = "./modules/efs"
  project_name            = var.project_name
  private_data_subnet_ids = module.vpc.private_data_subnet_ids
  data_sg_id              = module.security_groups.data_sg_id
}

# ── 6. RDS ───────────────────────────────────────────────────
module "rds" {
  source                  = "./modules/rds"
  project_name            = var.project_name
  private_data_subnet_ids = module.vpc.private_data_subnet_ids
  data_sg_id              = module.security_groups.data_sg_id
  db_username             = var.db_username
  db_password             = var.db_password
  db_name                 = var.db_name
}

# ── 7. Compute (EC2 + Launch Templates + ASGs) ───────────────
module "compute" {
  source                   = "./modules/compute"
  project_name             = var.project_name
  vpc_id                   = module.vpc.vpc_id
  public_subnet_ids        = module.vpc.public_subnet_ids
  private_web_subnet_ids   = module.vpc.private_web_subnet_ids
  nginx_sg_id              = module.security_groups.nginx_sg_id
  bastion_sg_id            = module.security_groups.bastion_sg_id
  webserver_sg_id          = module.security_groups.webserver_sg_id
  nginx_ami                = var.nginx_ami
  bastion_ami              = var.bastion_ami
  wordpress_ami            = var.wordpress_ami
  tooling_ami              = var.tooling_ami
  instance_type            = var.instance_type
  key_pair_name            = var.key_pair_name
  ext_alb_tg_nginx_arn     = module.alb.ext_tg_nginx_arn
  int_alb_tg_wordpress_arn = module.alb.int_tg_wordpress_arn
  int_alb_tg_tooling_arn   = module.alb.int_tg_tooling_arn
  efs_id                   = module.efs.efs_id
  rds_endpoint             = module.rds.rds_endpoint
  internal_alb_dns         = module.alb.internal_alb_dns
}

# ── 8. Route 53 ──────────────────────────────────────────────
module "route53" {
  source           = "./modules/route53"
  domain_name      = var.domain_name
  ext_alb_dns_name = module.alb.external_alb_dns
  ext_alb_zone_id  = module.alb.external_alb_zone_id
}
