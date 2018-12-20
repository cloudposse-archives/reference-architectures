locals {
  context = {
    accounts_enabled = "${jsonencode(var.accounts_enabled)}"
  }

  vars = "${merge(var.vars, local.context)}"
}

module "account" {
  source = "../../modules/account/"
  dirs   = "${var.dirs}"

  # For the "root" account these should always match
  aws_account_id      = "${var.aws_root_account_id}"
  aws_root_account_id = "${var.aws_root_account_id}"

  aws_region                   = "${var.aws_region}"
  namespace                    = "${var.namespace}"
  stage                        = "${var.stage}"
  domain                       = "${var.domain}"
  image_tag                    = "${var.image_tag}"
  templates                    = "${var.templates}"
  dirs                         = "${var.dirs}"
  vars                         = "${local.vars}"
  strip                        = "${var.strip}"
  repos_dir                    = "${var.repos_dir}"
  templates_dir                = "${var.templates_dir}"
  docker_registry              = "${var.docker_registry}"
  geodesic_base_image          = "${var.geodesic_base_image}"
  terraform_root_modules_image = "${var.terraform_root_modules_image}"
  terraform_root_modules       = "${var.terraform_root_modules}"
}
