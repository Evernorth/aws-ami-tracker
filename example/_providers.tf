terraform {
  required_version = "~> 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region  = var.region
  profile = var.profile
  default_tags {
    tags = {
      AppName = var.app_name
    }
  }
}
