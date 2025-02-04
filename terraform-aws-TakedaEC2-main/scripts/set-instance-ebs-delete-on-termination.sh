#!/bin/sh

# Due to a terraform design (in)decision (see
# https://github.com/hashicorp/terraform-provider-aws/issues/2416#issuecomment-352486334 )
# we are required to use something other than terraform to set the
# DeleteOnTermination attribute on additional EBS volumes attached to an instance

# We've chosen not to use python/boto3 here as
# - A full python runtime does not seem to be supported in the TFE local-exec "runner"
# - We could bootstrap python + pip + boto3 but at increased turn-around time
#   for every terraform run

set -eu

: "${AWS_REGION=us-east-1}"
INSTANCE_ID="${1?Instance(s) not specified as arguments}"

# These vars are expected to be set in the environment
: "${AWS_ACCESS_KEY_ID?Error: variable empty or unset}"
: "${AWS_SECRET_ACCESS_KEY?Error: variable empty or unset}"
: "${AWS_SESSION_TOKEN?Error: variable empty or unset}"

PATH="$HOME/.local/bin:$PATH"

aws() {
  (
    set -x
    command aws "$@"
  )
  echo "exit_status: $?" >&2
}

install_aws() {
  set -xv
  echo "PATH: $PATH"
  mkdir -p ~/.local
  tmpdir=$(mktemp -d)
  # This is to ensure multiple instances of the BB in the same TFE run
  # do not clobber over each other's install. And since this script is run
  # within the context of a ephemeral container - we can use a temporary
  # directory to hold the installation.
  install_dir="$(mktemp -d)"
  (
    cd "$tmpdir"
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    ./aws/install --bin-dir ~/.local/bin --install-dir "$install_dir" --update
  )
  rm -fr "$tmpdir"
  hash -r
  command aws --version
}

(which aws || install_aws) >&2

aws configure set region "${AWS_REGION}"
echo "AWS_REGION: ${AWS_REGION}"

echo "Caller: "
aws sts get-caller-identity --output json | cat -

patch_volume() {
  instance="$1"
  volume="$2"
  device="$3"
  echo "  Tagging volume: $volume $instance $device"
  aws ec2 modify-instance-attribute \
    --instance-id "$instance" \
    --block-device-mappings \
    '[ { "DeviceName": "'"$device"'",
        "Ebs": { "DeleteOnTermination": true }
      } ]'
}

patch_instance() {
  instance="$1"
  echo "Patching instance: $instance"
  aws ec2 describe-instances \
    --instance-ids "$instance" \
    --query '
      Reservations[*].Instances[*].[
        BlockDeviceMappings[*].[DeviceName, Ebs.VolumeId]
      ]
      ' --output text |
    while read -r device volume; do
      patch_volume "$instance" "$volume" "$device"
    done
}

for instance in "$@"; do
  patch_instance "$instance"
done
