provider "aws" {
  region = "eu-central-1"
}

terraform {
  backend "s3" {
    bucket = "decilo-tf-state"
    key    = "network/terraform.tfstate"
    region = "eu-central-1"
  }
}

module "vpc" {
  source = "../modules/vpc"
  region                        = "eu-central-1"
  vpc_cidr_block                = "10.0.0.0/16"
  public_subnet_cidr_blocks     = ["10.0.0.0/24", "10.0.2.0/24"]
  availability_zones            = ["eu-central-1a", "eu-central-1b"]
}

module "rds" {
  source = "../modules/rds"
  vpc_id = module.vpc.id
  subnet_ids = module.vpc.public_subnet_ids
}

module "decilo_core_api" {
  source = "../modules/decilo-core-api"
}
