locals {
  context = {
    # Used by `accounts`
    accounts_enabled = "${jsonencode(var.accounts_enabled)}"
    account_email    = "${var.account_email}"

    # Used by `root-dns`
    root_domain_name = "${var.stage}.${var.domain}"
  }

  vars = "${merge(var.vars, local.context)}"
}

module "account" {
  source = "../../modules/account/"

  dirs = "${var.dirs}"

  # For the "root" account these should always match
  aws_account_id      = "${var.aws_root_account_id}"
  aws_root_account_id = "${var.aws_root_account_id}"

  aws_region                   = "${var.aws_region}"
  namespace                    = "${var.namespace}"
  stage                        = "${var.stage}"
  domain                       = "${var.domain}"
  motd_url                     = "${var.motd_url}"
  image_tag                    = "${var.image_tag}"
  templates                    = "${var.templates}"
  dirs                         = "${var.dirs}"
  vars                         = "${local.vars}"
  strip                        = "${var.strip}"
  artifacts_dir                = "${var.artifacts_dir}"
  repos_dir                    = "${var.repos_dir}"
  templates_dir                = "${var.templates_dir}"
  docker_registry              = "${var.docker_registry}"
  geodesic_base_image          = "${var.geodesic_base_image}"
  terraform_root_modules_image = "${var.terraform_root_modules_image}"
  terraform_root_modules       = "${var.terraform_root_modules}"
}

module "add_users" {
  source        = "../../modules/add-users/"
  users         = "${var.users}"
  templates_dir = "${var.templates_dir}"
  output_dir    = "${module.account.repo_dir}/conf/users"
}

# Write an env file that we can use from other Makefiles
resource "local_file" "makefile_env" {
  content  = "ACCOUNTS_ENABLED = ${join(" ", var.accounts_enabled)}\n"
  filename = "${var.artifacts_dir}/Makefile.env"
}
