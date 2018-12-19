locals {
  working_dir = "${pathexpand("${path.module}/../repos")}"
}

module "root_account" {
  source      = "root"
  domain      = "test.co"
  namespace   = "test"
  aws_account_id = ""
  aws_root_account_id = ""
  templates   = ["Dockerfile.root", ".gitignore", ".dockerignore", "Makefile", "conf/Makefile"]
  working_dir = "${local.working_dir}"
}

module "testing_account" {
  source      = "subaccount"
  domain      = "test.co"
  namespace   = "test"
  stage       = "testing"
  aws_account_id = ""
  aws_root_account_id = ""
  templates   = ["Dockerfile.subaccount", ".gitignore", ".dockerignore", "Makefile", "conf/Makefile"]
  working_dir = "${local.working_dir}"
}
