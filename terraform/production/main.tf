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

module "decilo_core" {
  source = "../modules/decilo-core"
}
