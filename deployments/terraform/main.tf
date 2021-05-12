terraform {
  backend "remote" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.39"
    }

    random = {
      source = "hashicorp/random"
      version = "3.1.0"
    }
  }

  required_version = ">= 0.15.3"
}

provider "aws" {
  profile = var.aws_profile_name
  region  = var.aws_region
}