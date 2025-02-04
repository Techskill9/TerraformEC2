variable "APPROLE_ID" {
  type        = string
  description = "The role id from Hashicorp Vault"
}

variable "SECRET_ID" {
  type        = string
  description = "The secret id from Hashicorp Vault of the associated role"
  sensitive   = true
}
