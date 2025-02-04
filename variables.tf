locals {
  terraform_workspace = var.terraform_workspace == "" ? terraform.workspace : var.terraform_workspace

  tfc_wksp_name_parts = split("-", local.terraform_workspace)
  env_id_short        = local.tfc_wksp_name_parts[3]
  env_id_char         = upper(substr(local.env_id_short, 0, 1)) // 'D', 'T', 'P', etc
  apms_id             = local.tfc_wksp_name_parts[4]
  apms_id_short       = trim(upper(local.apms_id), "APMS-")
  tec_account         = join("-", slice(local.tfc_wksp_name_parts, 0, 3))

  ami_location = (
    var.ami_version != "" ?
    format("%s:%s", local.os_lookup[var.os], var.ami_version) :
    local.os_lookup[var.os]
  )

  is_windows = can(regex("^Windows[0-9]+$", var.os))
  is_linux   = !local.is_windows

  # Windows systems are automatically added to onetakeda domain.Refer to asec-djo variable for more information.
  shared_tags_asec_djo = (
    local.is_windows && var.asec_djo != "" ?
    merge(
      var.shared_tags,
      { "asec-djo" = var.asec_djo }
    ) :
    var.shared_tags
  )

  shared_tags = merge(
    local.shared_tags_asec_djo,
    { "terraform-workspace" = local.terraform_workspace }
  )

  os_lookup = {
    RHEL9 = "/tec/golden-ami/RHEL9/ami-id"
    RHEL8 = "/tec/golden-ami/RHEL8/ami-id"
    RHEL7 = "/tec/golden-ami/RHEL7/ami-id"
    AZL2  = "/tec/golden-ami/AMZN2/ami-id"
    Windows2019 = (
      var.asec_djo != "" ?
      "/tec/golden-ami/Windows2019/DomainJoined/ami-id" :
      "/tec/golden-ami/Windows2019/NonDomainJoined/ami-id"
    )
    Windows2016 = (
      var.asec_djo != "" ?
      "/tec/golden-ami/Windows2016/DomainJoined/ami-id" :
      "/tec/golden-ami/Windows2016/NonDomainJoined/ami-id"
    )
  }

  os_prefix = {
    RHEL9       = "X"
    RHEL8       = "X"
    RHEL7       = "X"
    AZL2        = "X"
    Windows2019 = "W"
    Windows2016 = "W"
  }

  current_account = data.aws_caller_identity.current.account_id
  current_region  = data.aws_region.current.name
  valid_regions = {
    us-east-1      = "us-east-1"
    us-west-2      = "us-west-2"
    ap-northeast-1 = "ap-northeast-1"
    ap-southeast-1 = "ap-southeast-1"
    eu-central-1   = "eu-central-1"
    eu-west-1      = "eu-west-1"
  }

  # Naive validation that the current region is a TEC-supported region
  # This is to fail terraform if a user attempts to use this building-block
  # in an unsupported region
  region = local.valid_regions[local.current_region]
  region_code = {
    us-east-1      = "USVGA"
    ap-northeast-1 = "JPTYO"
    eu-central-1   = "DEFRA"
    ap-southeast-1 = "SGSIN"
    eu-west-1      = "IEDUB"
    us-west-2      = "USORE"
  }
  FMManagedSecurityGroup = {
    us-east-1      = "FMManagedSecurityGroup53ece283-cd5a-4722-9488-3d31c9433600-sg-0dd335a5b5df3b16e"
    ap-northeast-1 = "FMManagedSecurityGroupf2e6e4cc-5ca8-45ab-9323-f1c7a12e612c-sg-0b3ec2930e9ab7fee"
    eu-central-1   = "FMManagedSecurityGroup979f34c0-7a2a-4b32-a5dc-075ecbb61f6d-sg-0fa43a0bb7fc6c733"
    ap-southeast-1 = "FMManagedSecurityGroup2a55ea0f-6134-4c33-a59a-8caed81167c2-sg-0ce5a5a1005ae2183"
    eu-west-1      = "FMManagedSecurityGroup19a3a71f-b1ee-41d1-b42e-1043b265c8f3-sg-00d59a95603af84cf"
    us-west-2      = "FMManagedSecurityGroupd8d3ae00-2c07-4e4d-a59f-c2dfae95e4ad-sg-0276873ff140afab4"
  }

  cpe_shs_subnet_identifier = {
    "012096835438" = (
      var.instance_tier == "dmz" ?
      "tec-cpe-shs-dmz-prd-vpc-${local.region}-pri" :
      "tec-cpe-shs-gen-prd-vpc-${local.region}-pri"
    )
    "875633494741" = "tec-cpe-shs-dev-vpc-${local.region}-app"
    "271554166616" = "tec-cpe-shs-tst-vpc-${local.region}-app"
  }

  // test cases - Consult with AVM team for various subnet types
  // tec-net-nam-prd-man-mls-vpc-us-east-1-app-az1 - man-mss - dedicated
  // tec-net-nam-prd-dat-adx-vpc-us-east-1-dat-az1 - dat-adx - dedicated?
  // tec-net-nam-prd-man-shr-vpc-us-east-1-app-az1 - man-mes - shared
  // tec-net-nam-prd-rnd-shr-vpc-us-east-1-app-az3 - rnd-sci - shared
  // tec-com-ddt-inn-vpc-us-east-1-dat-az3 - com-ddt - innovation / not-supported
  // tec-ent-gdt-inn-vpc-us-east-1-app-az2 - ent-gdt - innocation / not-supported
  subnet_identifier = lookup(
    local.cpe_shs_subnet_identifier,
    local.current_account,
    // TODO, support subnets in the innovation accounts
    "*-${local.env_id_short}-*-*-vpc-${local.region}-${var.instance_tier}"
  )

  environment = local.valid_environment[local.shared_tags.environment-id]
  valid_environment = {
    dev  = "dev"
    inn  = "inn"
    prd  = "prd"
    prod = "prd"
    test = "tst"
    tst  = "tst"
  }
}

variable "number_of_instances" {
  type        = number
  description = "How many EC2 instances should be created"
  default     = 1
}

variable "shared_tags" {
  type        = map(string)
  default     = {}
  description = <<EOF
  AWS Tags to be applied to all resources mananaged by this building block.
  See the [Tagging Standard](https://mytakeda.sharepoint.com/sites/ECS/SitePages/Tagging-Standards.aspx) for required tags.
  Note: Changes to tags for the volume are not changed after provisioning,
  these must be updated manually in the AWS console.
  EOF
}

variable "os" {
  type = string
  validation {
    condition     = contains(["RHEL9", "RHEL8", "RHEL7", "Windows2019", "Windows2016", "AZL2"], var.os)
    error_message = "Not a valid operating system!"
  }
  default     = "RHEL8"
  description = "The OS for the EC2(s). One of: `RHEL9`, `RHEL8`, `RHEL7`, `Windows2019`, `Windows2016`, `AZL2`"
}

variable "instance_type" {
  type        = string
  default     = "t3.small"
  description = "The size for the EC2(s)"
}

variable "instance_tier" {
  type = string
  validation {
    condition     = contains(["web", "app", "dat"], var.instance_tier)
    error_message = "Not a valid instance tier!"
  }
  description = "The network tier in which the instance will be deployed. One of: `app`, `dat`, `web`"
  default     = "app"
}

variable "security_groups" {
  type        = list(string)
  default     = []
  description = "The Security Groups to be attached on the EC2(s)"
}

variable "user_data" {
  type        = string
  default     = ""
  description = "Custom code that replaces the default user_data script"
}

variable "root_volume_size" {
  type        = number
  default     = 50
  description = "Size for the root EBS volume"
}

variable "subnet_az_id" {
  type = string
  validation {
    condition     = contains(["az1", "az2", "az3", ""], var.subnet_az_id)
    error_message = "Not a valid instance tier!"
  }
  default     = ""
  description = "To set to az1/az2/az3 in case of instance couldn't be deployed in randomly choosed region"
}

variable "terraform_workspace" {
  description = <<EOF
  (Internal Use Only) The Terraform Enterprise Workspace for use in the contexts where
  `terraform.workspace` is not set or needs to be overridden (e.g. terratest, sandboxes, etc)
  EOF
  type        = string
  default     = ""
}

variable "vault_aws_access_credentials" {
  type = object({
    access_key : string,
    region : string,
    secret_key : string,
    security_token : string,
  })
  default     = null
  description = <<EOF
  Vault AWS access credentials for use by AWS CLI in the internal EBS patching script.
  e.g. data.vault_aws_access_credentials.creds
  EOF
}

variable "additional_ebs_config" {
  type = list(object({
    additional_ebs_volume_size = number
    additional_ebs_device_name = string
    additional_ebs_mount_point = string
    additional_ebs_iops        = optional(number)
    additional_ebs_type        = optional(string, "gp3")
  }))
  description = <<EOF
  Used when additional EBS volumes are required.
  Includes volume_size, device_name ,mount_point which is added to EBS Name tag
  (e.g. USVGA12345DX001-TMP) iops and type"
  EOF
  default     = []
}

variable "ami_id" {
  type        = string
  default     = ""
  description = "Used when exact AMI-ID needs to be specified"
}

variable "ami_version" {
  type        = string
  default     = ""
  description = "Version of AMI in parameter store, if not set than latest version is used"
}

variable "asec_djo" {
  type        = string
  default     = "onetakeda"
  description = <<EOF
  The Active Directory domain to join Windows Instances to (onetakeda.com by default).
  You can specify a different domain or leave this tag empty to not join a domain
  EOF
}

variable "iam_instance_profile" {
  type        = string
  default     = "TEC-EC2-SSM"
  description = <<EOF
  IAM role attached to the EC2 instance during provisioning.
  Change only if role with specific policies is required
  EOF
}

variable "user_preferred_index" {
  type        = number
  default     = 0
  description = <<EOF
  A value to influence the ID suffixed of EC2 instances.
  This is needed to avoid name conflicts when calling this building block as a
  child module more than once per Terraform plan/apply run.
  NOTE: This actual ID set is dependant on the addition of this value and
  the next-highest available ID in the environment
  EOF
}

variable "create_ssh_key_pair" {
  type        = bool
  default     = false
  description = <<EOF
    "**Only for use with custom AMI or Appliances**.
    This flag instructs the building block to create an SSH key pair for injection into the
    EC2 instance i.e. when provisioning instances from AWS marketplace or vendor AMIs
    as opposed to the Takeda Golden AMIs.
    Must be used in conjunction with a user-supplied `public_key`"
  EOF
}

variable "public_key" {
  type        = string
  default     = ""
  description = <<EOF
  The contents of an SSH public key for use in key_name for the EC2 instance
  e.g. public_key = \"ssh-rsa AAAzaC1y... me@takeda.com\"

  A note on Security: Please consider the security and availability of the
  counterpart private key and store the private keys in a secrets management service
  (AWS Secrets, Github Secrets, Hashicorp Vault, etc) rather than in code.

  The public key on the other hand is not meant to be treated as a secret and can be
  stored in cleartext in code
  EOF
}

variable "instance_name" {
  type        = string
  default     = ""
  description = <<EOF
  The EC2 instance_name and OS hostname to assign to the instances created by this building block.
  The default behaviour of this building block is to autogenerate the instance names to match the
  Takeda Naming Standards, this variable overrides that behaviour and allows the user to set the
  instances' names. When overriding this name, it is important to still try and observe the spirit
  of the Takeda Naming Standards to aid in operations as well as the hostname constraints as set
  out by NetBIOS protocols in the case of Windows and RFC1034 otherwise.
  Caution: Only useful when `count` is 1 otherwise all instances take on the same instance name.
  EOF
}

variable "subnet_name" {
  type        = string
  default     = ""
  description = <<EOF
  The variable serves as a reference to a subnet within an AWS account with non-standard subnet names.
  **Don't use it unless absolutely necessary. Additionally, setting the subnet_name specifies a particular target Availability Zone (AZ) for EC2.**
  EOF
}
