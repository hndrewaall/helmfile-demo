terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.37.0"
    }
  }
}

provider "aws" {
  default_tags {
    tags = {
      Environment = "Dev"
      Terraform   = "True"
    }
  }
}
