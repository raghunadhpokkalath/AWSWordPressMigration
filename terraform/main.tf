module "networking" {
  source                 = "./modules/networking"
  your_home_network_cidr = var.your_home_network_cidr
  vpc_cidr               = var.vpc_cidr
}

module "ecs" {
  source       = "./modules/ecs"
  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
  ##Using publicsubet as some issue with private subnets
  subnet_private_ids = module.networking.subnet_public_ids
  file_system_id     = module.efs.file_system_id
  rds = {
    endpoint = module.rds.this_rds_cluster_endpoint
    username = module.rds.this_rds_cluster_master_username
    password = module.rds.this_rds_cluster_master_password
    dbname   = module.rds.this_rds_cluster_database_name
  }
}

module "rds" {
  source                  = "./modules/rds-serverless"
  vpc_id                  = module.networking.vpc_id
  subnet_private_ids      = module.networking.subnet_private_ids
  allowed_security_groups = [module.bastion.security_group_id]
  sg_ecs                  = module.ecs.sg_ecs_id
}

module "bastion" {
  source            = "./modules/bastion"
  vpc_id            = module.networking.vpc_id
  subnet_id         = module.networking.subnet_public_ids[0]
  ssh_allowed_cidrs = [var.your_home_network_cidr]
}

module "efs" {
  source     = "./modules/efs"
  vpc_id     = module.networking.vpc_id
  sg_ecs     = module.ecs.sg_ecs_id
  subnet_id1 = module.networking.subnet_private_ids[0]
  subnet_id2 = module.networking.subnet_private_ids[1]
}
