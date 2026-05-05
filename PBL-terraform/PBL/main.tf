# ============================================================
#  main.tf — Root module: wires all child modules together
# ============================================================

# ── Network ─────────────────────────────────────────────────
module "network" {
  source = "./modules/network"

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  environment          = var.environment
  tags                 = local.common_tags
}

# ── Security Groups ──────────────────────────────────────────
module "security" {
  source = "./modules/security"

  vpc_id      = module.network.vpc_id
  environment = var.environment
  admin_cidr  = var.admin_cidr
  tags        = local.common_tags
}

# ── Application Load Balancer ────────────────────────────────
module "alb" {
  source = "./modules/ALB"

  environment       = var.environment
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id
  tags              = local.common_tags
}

# ── EFS (Elastic File System) ────────────────────────────────
module "efs" {
  source = "./modules/EFS"

  environment        = var.environment
  private_subnet_ids = module.network.private_subnet_ids
  efs_sg_id          = module.security.efs_sg_id
  tags               = local.common_tags
}

# ── RDS (Relational Database) ────────────────────────────────
module "rds" {
  source = "./modules/RDS"

  environment        = var.environment
  private_subnet_ids = module.network.private_subnet_ids
  rds_sg_id          = module.security.rds_sg_id
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  db_instance_class  = var.db_instance_class
  multi_az           = var.multi_az
  tags               = local.common_tags
}

# ── Compute (Launch Template) ────────────────────────────────
module "compute" {
  source = "./modules/compute"

  environment   = var.environment
  ami_id        = local.resolved_ami
  instance_type = var.instance_type
  key_name      = var.key_name
  app_sg_id     = module.security.app_sg_id
  efs_dns_name  = module.efs.efs_dns_name
  tags          = local.common_tags
}

# ── Auto Scaling Group ───────────────────────────────────────
module "autoscaling" {
  source = "./modules/autoscaling"

  environment             = var.environment
  min_size                = var.min_size
  max_size                = var.max_size
  desired_capacity        = var.desired_capacity
  private_subnet_ids      = module.network.private_subnet_ids
  target_group_arn        = module.alb.target_group_arn
  launch_template_id      = module.compute.launch_template_id
  launch_template_version = module.compute.launch_template_version
  tags                    = local.common_tags
}
