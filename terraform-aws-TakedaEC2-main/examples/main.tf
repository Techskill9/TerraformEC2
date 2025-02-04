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
