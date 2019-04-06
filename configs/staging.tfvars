# This is a terraform configuration file

stage = "staging"

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
  "conf/kops/.envrc",
  "conf/kops/Makefile.tasks",
  "conf/kops/kops.envrc",
  "conf/kops/terraform.envrc",
  "conf/kops/terraform.tfvars",
  "docs/kops.md",
  "conf/kops-aws-platform/.envrc",
  "conf/kops-aws-platform/Makefile.tasks",
  "conf/kops-aws-platform/terraform.envrc",
  "conf/kops-aws-platform/terraform.tfvars",
]

# List of terraform root modules to enable
terraform_root_modules = [
  "aws/tfstate-backend",
  "aws/account-dns",
  "aws/chamber",
  "aws/kops",
  "aws/kops-aws-platform",
  "aws/cloudtrail",
]
