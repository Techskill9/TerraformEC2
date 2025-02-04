provider "aws" {
  region     = var.region
  access_key = data.vault_aws_access_credentials.creds.access_key
  secret_key = data.vault_aws_access_credentials.creds.secret_key
  token      = data.vault_aws_access_credentials.creds.security_token
}

provider "vault" {
  address = "https://vault.ent.aws.takeda.io/"

  auth_login {
    path   = "auth/approle/login"
    method = "approle"

    parameters = {
      role_id   = var.APPROLE_ID
      secret_id = var.SECRET_ID
    }
  }
}

data "vault_aws_access_credentials" "creds" {
  backend = "aws"
  role    = "tec-dce-inn-dev-TerraformIaC"
  type    = "sts"
}

