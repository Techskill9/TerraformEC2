// ebs-volume-patch.tf
// Set the delete-on-termination attribute to enabled for all additional EBS
// volumes on EC2 instances managed by this BB. This is due to a shortcoming in
// the hashicorp AWS provider not willing to set this. See
// https://github.com/hashicorp/terraform-provider-aws/issues/2416#issuecomment-352486334
// for their rationale.

locals {
  // EBS delete-on-termination patch script
  ebs_dot_script = "scripts/set-instance-ebs-delete-on-termination.sh"
}

resource "terraform_data" "patch_instance_ebs_vol_delete_on_termination" {
  // As Takeda's policy is to ensure that the lifecycle of EBS volumes must be
  // tied to that of the "parent" EC2 instance (delete-on-termination=enabled
  // is therefore an ORC requirement), we ensure that if there are additional
  // ebs volumes created - we will patch those unconditionally.
  count = length(aws_ebs_volume.additional_ebs_volumes) >= 1 ? 1 : 0

  provisioner "local-exec" {
    command = format("sh -x -c 'pwd; %s %s'",
      local.ebs_dot_script,
      join(
        " ",
        aws_instance.ec2-instance[*].id // all instances managed by this BB module
      )
    )
    working_dir = path.module
    environment = {
      AWS_REGION = data.aws_region.current.name
      // As we cannot inherit the vault provider's configuration from the root
      // module i.e. to derive the vault workspace role and so retrieve the
      // AWS access credentials. We require the caller to set these up and
      // pass them to us via var.vault_aws_access_credentials in the root
      // module
      // e.g. vault_aws_access_credentials = data.vault_aws_access_credentials.creds
      AWS_ACCESS_KEY_ID     = var.vault_aws_access_credentials.access_key
      AWS_SECRET_ACCESS_KEY = var.vault_aws_access_credentials.secret_key
      AWS_SESSION_TOKEN     = var.vault_aws_access_credentials.security_token
    }
  }

  triggers_replace = {
    // always = timestamp()
    // If the script has changed
    script_change = filesha1(format("%s/%s", path.module, local.ebs_dot_script))
    // If the instances are (re)provisioned
    instance_ids = join(" ", sort((concat(aws_instance.ec2-instance[*].id))))
    // or we have new volume attachments
    volume_ids     = join(" ", sort((concat(aws_ebs_volume.additional_ebs_volumes[*].id))))
    attachment_ids = join(" ", sort((concat(aws_volume_attachment.additional_ebs_volumes[*].id))))
  }
}
