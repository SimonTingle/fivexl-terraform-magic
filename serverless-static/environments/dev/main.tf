terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "fivexl-tf-state-bucket"
    key            = "serverless/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "fivexl-task-tf-lock-table"
  }
}
provider "aws" {
  region  = "us-east-1"
  profile = "dev-account"
}
module "static_website" {
  source = "../../modules/s3-static-site"
  bucket_name_prefix = var.bucket_name_prefix
  tags               = var.tags
}
