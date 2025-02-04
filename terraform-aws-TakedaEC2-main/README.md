<!-- BEGIN_TF_DOCS -->


# Examples
```hcl
module "EC2" {
  source = "terraform-amer.takeda.com/DCEInternalDev/TakedaEC2/aws"

  os                  = "RHEL9"
  instance_type       = "t3a.small"
  number_of_instances = 2
  instance_tier       = "app"
  root_volume_size    = 50
  # ami_id = "ami-005ec5f8c2e4d298b"
  ami_version     = "4"
  user_data       = <<-EOT
    dnf -y install httpd policycoreutils-python-utils
    sed -i "s/^Listen 80$/Listen 8088/" /etc/httpd/conf/httpd.conf
    semanage port -a -t http_port_t -p tcp 8088
    echo "It works!" > /var/www/html/index.html
    chmod 644 /var/www/html/index.html
    systemctl start --now httpd
  EOT
  security_groups = ["sg-09e14d49115732772"]
  shared_tags = {
    "version"            = "2022-03-30"
    "apms-id"            = "APMS-12345"
    "application-owner"  = "first.last@takeda.com"
    "it-technical-owner" = "first.last@takeda.com"
    "environment-id"     = "dev"
    "asec-tier"          = "at"
    "application-name"   = "PoC"
    "is-multi-tenant"    = "false"
    "recovery-tier"      = "Tier 3"
    "service-ci-id"      = "CID1234567"
  }

  vault_aws_access_credentials = data.vault_aws_access_credentials.creds
  additional_ebs_config = [
    {
      additional_ebs_volume_size = 10
      additional_ebs_device_name = "/dev/sdb"
      additional_ebs_mount_point = "tmp"
      # additional_ebs_type = "gp2"
      # additional_ebs_iops = 1000
    }
  ]
}

variable "APPROLE_ID" {
  type        = string
  description = "The role id from Hashicorp Vault"
}

variable "SECRET_ID" {
  type        = string
  description = "The secret id from Hashicorp Vault of the associated role"
  sensitive   = true
}

variable "terraform_workspace" {
  description = "The Terraform workspace passed from the root module"
  type        = string
}

output "id" {
  value = module.EC2.id
}

output "private_ip" {
  value = module.EC2.private_ip
}

output "name_tag" {
  value = module.EC2.name_tag
}
output "ec2-details" {
  value = {
    for i in module.EC2.name_tag : i => {
      instance_id = module.EC2.id[index(module.EC2.name_tag, i)]
      private_ip  = module.EC2.private_ip[index(module.EC2.name_tag, i)]
    }
  }
  description = "EC2 details - instance_id and private_ip"
}

output "instance_type" {
  value = module.EC2.instance_type
}

output "aws_key_pair" {
  value       = module.EC2.aws_key_pair
  description = "ID of the ssh key pair"
}

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

```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.4 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.52 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.52 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ebs_volume.additional_ebs_volumes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_instance.ec2-instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_key_pair.ssh_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_volume_attachment.additional_ebs_volumes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [terraform_data.patch_instance_ebs_vol_delete_on_termination](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_instance.each](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/instance) | data source |
| [aws_instances.all_matching](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/instances) | data source |
| [aws_kms_alias.ebs_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_alias) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_security_groups.FM_securitygroup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_groups) | data source |
| [aws_ssm_parameter.ami_id](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_subnet.vpc_identifier](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnets.subnet_az_id](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_subnets.subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_additional_ebs_config"></a> [additional\_ebs\_config](#input\_additional\_ebs\_config) | Used when additional EBS volumes are required.<br>  Includes volume\_size, device\_name ,mount\_point which is added to EBS Name tag<br>  (e.g. USVGA12345DX001-TMP) iops and type" | <pre>list(object({<br>    additional_ebs_volume_size = number<br>    additional_ebs_device_name = string<br>    additional_ebs_mount_point = string<br>    additional_ebs_iops        = optional(number)<br>    additional_ebs_type        = optional(string, "gp3")<br>  }))</pre> | `[]` |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | Used when exact AMI-ID needs to be specified | `string` | `""` |
| <a name="input_ami_version"></a> [ami\_version](#input\_ami\_version) | Version of AMI in parameter store, if not set than latest version is used | `string` | `""` |
| <a name="input_asec_djo"></a> [asec\_djo](#input\_asec\_djo) | The Active Directory domain to join Windows Instances to (onetakeda.com by default).<br>  You can specify a different domain or leave this tag empty to not join a domain | `string` | `"onetakeda"` |
| <a name="input_create_ssh_key_pair"></a> [create\_ssh\_key\_pair](#input\_create\_ssh\_key\_pair) | "**Only for use with custom AMI or Appliances**.<br>    This flag instructs the building block to create an SSH key pair for injection into the<br>    EC2 instance i.e. when provisioning instances from AWS marketplace or vendor AMIs<br>    as opposed to the Takeda Golden AMIs.<br>    Must be used in conjunction with a user-supplied `public_key`" | `bool` | `false` |
| <a name="input_iam_instance_profile"></a> [iam\_instance\_profile](#input\_iam\_instance\_profile) | IAM role attached to the EC2 instance during provisioning.<br>  Change only if role with specific policies is required | `string` | `"TEC-EC2-SSM"` |
| <a name="input_instance_name"></a> [instance\_name](#input\_instance\_name) | The EC2 instance\_name and OS hostname to assign to the instances created by this building block.<br>  The default behaviour of this building block is to autogenerate the instance names to match the<br>  Takeda Naming Standards, this variable overrides that behaviour and allows the user to set the<br>  instances' names. When overriding this name, it is important to still try and observe the spirit<br>  of the Takeda Naming Standards to aid in operations as well as the hostname constraints as set<br>  out by NetBIOS protocols in the case of Windows and RFC1034 otherwise.<br>  Caution: Only useful when `count` is 1 otherwise all instances take on the same instance name. | `string` | `""` |
| <a name="input_instance_tier"></a> [instance\_tier](#input\_instance\_tier) | The network tier in which the instance will be deployed. One of: `app`, `dat`, `web` | `string` | `"app"` |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | The size for the EC2(s) | `string` | `"t3.small"` |
| <a name="input_number_of_instances"></a> [number\_of\_instances](#input\_number\_of\_instances) | How many EC2 instances should be created | `number` | `1` |
| <a name="input_os"></a> [os](#input\_os) | The OS for the EC2(s). One of: `RHEL9`, `RHEL8`, `RHEL7`, `Windows2019`, `Windows2016`, `AZL2` | `string` | `"RHEL8"` |
| <a name="input_public_key"></a> [public\_key](#input\_public\_key) | The contents of an SSH public key for use in key\_name for the EC2 instance<br>  e.g. public\_key = \"ssh-rsa AAAzaC1y... me@takeda.com\"<br><br>  A note on Security: Please consider the security and availability of the<br>  counterpart private key and store the private keys in a secrets management service<br>  (AWS Secrets, Github Secrets, Hashicorp Vault, etc) rather than in code.<br><br>  The public key on the other hand is not meant to be treated as a secret and can be<br>  stored in cleartext in code | `string` | `""` |
| <a name="input_root_volume_size"></a> [root\_volume\_size](#input\_root\_volume\_size) | Size for the root EBS volume | `number` | `50` |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | The Security Groups to be attached on the EC2(s) | `list(string)` | `[]` |
| <a name="input_shared_tags"></a> [shared\_tags](#input\_shared\_tags) | AWS Tags to be applied to all resources mananaged by this building block.<br>  See the [Tagging Standard](https://mytakeda.sharepoint.com/sites/ECS/SitePages/Tagging-Standards.aspx) for required tags.<br>  Note: Changes to tags for the volume are not changed after provisioning,<br>  these must be updated manually in the AWS console. | `map(string)` | `{}` |
| <a name="input_subnet_az_id"></a> [subnet\_az\_id](#input\_subnet\_az\_id) | To set to az1/az2/az3 in case of instance couldn't be deployed in randomly choosed region | `string` | `""` |
| <a name="input_subnet_name"></a> [subnet\_name](#input\_subnet\_name) | The variable serves as a reference to a subnet within an AWS account with non-standard subnet names.<br>  **Don't use it unless absolutely necessary. Additionally, setting the subnet\_name specifies a particular target Availability Zone (AZ) for EC2.** | `string` | `""` |
| <a name="input_terraform_workspace"></a> [terraform\_workspace](#input\_terraform\_workspace) | (Internal Use Only) The Terraform Enterprise Workspace for use in the contexts where<br>  `terraform.workspace` is not set or needs to be overridden (e.g. terratest, sandboxes, etc) | `string` | `""` |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | Custom code that replaces the default user\_data script | `string` | `""` |
| <a name="input_user_preferred_index"></a> [user\_preferred\_index](#input\_user\_preferred\_index) | A value to influence the ID suffixed of EC2 instances.<br>  This is needed to avoid name conflicts when calling this building block as a<br>  child module more than once per Terraform plan/apply run.<br>  NOTE: This actual ID set is dependant on the addition of this value and<br>  the next-highest available ID in the environment | `number` | `0` |
| <a name="input_vault_aws_access_credentials"></a> [vault\_aws\_access\_credentials](#input\_vault\_aws\_access\_credentials) | Vault AWS access credentials for use by AWS CLI in the internal EBS patching script.<br>  e.g. data.vault\_aws\_access\_credentials.creds | <pre>object({<br>    access_key : string,<br>    region : string,<br>    secret_key : string,<br>    security_token : string,<br>  })</pre> | `null` |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_key_pair"></a> [aws\_key\_pair](#output\_aws\_key\_pair) | Name of ssh key pair |
| <a name="output_ebs_attachments"></a> [ebs\_attachments](#output\_ebs\_attachments) | The IDs of the attachments of additional volumes attached to the instances |
| <a name="output_id"></a> [id](#output\_id) | The ID of the EC2 instance |
| <a name="output_instance_type"></a> [instance\_type](#output\_instance\_type) | Type of the instances provisioned |
| <a name="output_name_tag"></a> [name\_tag](#output\_name\_tag) | The Name Tag of the EC2 instance |
| <a name="output_private_ip"></a> [private\_ip](#output\_private\_ip) | The private IP of the EC2 instance |
| <a name="output_region"></a> [region](#output\_region) | Region the EC2 instance was provisioned into |
| <a name="output_volumes"></a> [volumes](#output\_volumes) | The IDs of additional volumes attached to the instances |

<!-- END_TF_DOCS -->