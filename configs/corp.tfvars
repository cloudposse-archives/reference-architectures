# This is a terraform configuration file

stage = "corp"

# List of templates to install
templates = [
  "Dockerfile.child", 
  ".gitignore", 
  ".dockerignore", 
  "Makefile", 
  "conf/Makefile",
  "conf/account-dns/terraform.tfvars"
]

# List of terraform root modules to enable
terraform_root_modules = [
  "aws/tfstate-backend",
  "aws/account-dns",
  "aws/chamber",
  "aws/cloudtrail",
]
