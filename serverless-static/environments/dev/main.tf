# Example for serverless-static/environments/dev/main.tf
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
