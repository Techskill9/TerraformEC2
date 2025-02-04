output "id" {
  value       = aws_instance.ec2-instance[*].id
  description = "The ID of the EC2 instance"
}

output "private_ip" {
  value       = aws_instance.ec2-instance[*].private_ip
  description = "The private IP of the EC2 instance"
}

output "name_tag" {
  value       = aws_instance.ec2-instance[*].tags_all.Name
  description = "The Name Tag of the EC2 instance"
}

output "volumes" {
  value       = aws_ebs_volume.additional_ebs_volumes[*].id
  description = "The IDs of additional volumes attached to the instances"
}

output "ebs_attachments" {
  value       = aws_volume_attachment.additional_ebs_volumes[*].volume_id
  description = "The IDs of the attachments of additional volumes attached to the instances"
}

output "instance_type" {
  value       = aws_instance.ec2-instance[*].instance_type
  description = "Type of the instances provisioned"
}

output "region" {
  value       = data.aws_region.current.name
  description = "Region the EC2 instance was provisioned into"
}

output "aws_key_pair" {
  value       = one(aws_key_pair.ssh_key[*].id)
  description = "Name of ssh key pair"
}
