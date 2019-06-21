# This is a terraform configuration file

stage = "dev"

# List of templates to install
templates = [
  "README.md",
  "Dockerfile.child",
  ".github/CODEOWNERS",
  ".github/ISSUE_TEMPLATE/feature-request.md",
  ".github/ISSUE_TEMPLATE/bug.md",
  ".github/PULL_REQUEST.md",
  ".editorconfig",
  ".gitignore",
  ".dockerignore",
  "Makefile",
  "conf/tfstate-backend/.envrc",
  "conf/tfstate-backend/Makefile.tasks",
  "conf/tfstate-backend/terraform.envrc",
  "conf/tfstate-backend/terraform.tfvars",
  "conf/account-dns/.envrc",
  "conf/account-dns/Makefile.tasks",
  "conf/account-dns/terraform.envrc",
  "conf/account-dns/terraform.tfvars",
  "conf/chamber/.envrc",
  "conf/chamber/Makefile.tasks",
  "conf/chamber/terraform.envrc",
  "conf/chamber/terraform.tfvars",
  "conf/cloudtrail/.envrc",
  "conf/cloudtrail/Makefile.tasks",
  "conf/cloudtrail/terraform.envrc",
]

# Map of terraform root modules to enable
terraform_root_modules = [
  "aws/tfstate-backend",
  "aws/account-dns",
  "aws/chamber",
  "aws/cloudtrail",
]
