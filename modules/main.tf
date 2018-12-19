locals {
  working_dir = "${pathexpand("${path.module}/../repos")}"
}

module "root_account" {
  source    = "root"
  domain    = "test.co"
  templates = ["Dockerfile.root", ".gitignore", ".dockerignore", "Makefile", "conf/Makefile"]
  working_dir = "${local.working_dir}"
}

module "testing_account" {
  source    = "subaccount"
  name      = "testing"
  domain    = "test.co"
  templates = ["Dockerfile.subaccount", ".gitignore", ".dockerignore", "Makefile", "conf/Makefile"]
  working_dir = "${local.working_dir}"
}
