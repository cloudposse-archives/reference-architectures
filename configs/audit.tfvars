# This is a terraform configuration file

stage = "audit"

# List of templates to install
templates = [
  "README.md",
  "Dockerfile.child", 
  ".gitignore", 
  ".dockerignore", 
  "Makefile", 
  "conf/Makefile"
  ]

# List of terraform root modules to enable
terraform_root_modules = [
  "aws/tfstate-backend",
  "aws/account-dns",
  "aws/chamber",
  "aws/audit-cloudtrail"
]
