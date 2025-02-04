terraform {

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.8"
    }
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  region = "eu-central-1"
  alias  = "europe"
}
