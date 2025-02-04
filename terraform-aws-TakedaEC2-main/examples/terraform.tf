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
