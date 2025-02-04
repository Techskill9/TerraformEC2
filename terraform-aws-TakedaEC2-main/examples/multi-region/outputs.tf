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
