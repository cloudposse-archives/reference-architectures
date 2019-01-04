# This is a terraform configuration file

# The "apex" service discovery domain for *all* infrastructure
domain = "test.co"

# The global namespace that should be shared by all accounts
namespace = "test"

# The default region for this account
aws_region = "us-west-2"

# Network CIDR of Organization
org_network_cidr    = "10.0.0.0/8"
org_network_offset  = 100
org_network_newbits = 8    # /8 + /8 = /16

# Pod IP address space (must not overlap with org_network_cidr)
kops_non_masquerade_cidr = "172.16.0.0/12"


# The docker registry that will be used for the images built (nothing will get pushed)
docker_registry = "cloudposse"

# The templates to use for this account
templates = [
  "README.md",
  "Dockerfile.root",
  ".github/CODEOWNERS",
  ".github/ISSUE_TEMPLATE/feature-request.md",
  ".github/ISSUE_TEMPLATE/bug.md",
  ".github/PULL_REQUEST.md",
  ".editorconfig",
  ".gitignore",
  ".dockerignore",
  "Makefile",
  "conf/Makefile",
  "conf/accounts/terraform.tfvars",
  "conf/bootstrap/terraform.tfvars",
  "conf/iam/terraform.tfvars",
  "conf/root-dns/terraform.tfvars",
  "conf/users/terraform.tfvars"
]

# Account email address format (e.g. `ops+%s@example.co`). This is not easily changed later.
account_email = "ops+%s@test.co"

# List of accounts to enable
accounts_enabled = [
  "dev",
  "staging",
  "prod",
  "testing",
  "data",
  "corp",
  "audit",
]

# Administrator IAM usernames mapped to their keybase usernames for password encryption
users = {
#  "erik@cloudposse.com" = "osterman"
}

# Terraform Root Modules Image (don't change this unless you know what you're doing)
# Project: https://github.com/cloudposse/terraform-root-modules
terraform_root_modules_image = "cloudposse/terraform-root-modules:0.18.1"

# Geodesic Base Image (don't change this unless you know what you're doing)
# Project: https://github.com/cloudposse/geodesic
geodesic_base_image = "cloudposse/geodesic:0.57.0"

# List of terraform root modules to enable
terraform_root_modules = [
  "aws/tfstate-backend",
  "aws/accounts",
  "aws/account-settings",
  "aws/bootstrap",
  "aws/root-dns",
  "aws/root-iam",
  "aws/iam",
  "aws/users",
  "aws/cloudtrail",
]

# Message of the Day
motd_url = "https://geodesic.sh/motd"
