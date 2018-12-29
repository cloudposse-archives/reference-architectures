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


locals {
  all_accounts = "${concat(list("root"), var.accounts_enabled)}"
}

data "null_data_source" "networks" {
  count = "${length(local.all_accounts)}"

  inputs = {
    cidr = "${cidrsubnet(var.org_network_cidr, 8, count.index)}"
  }
}

locals {
  networks = "${zipmap(local.all_accounts, data.null_data_source.networks.*.outputs.cidr)}"
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
  org_network_cidr             = "${var.org_network_cidr}"
  account_network_cidr         = "${length(var.account_network_cidr) > 0 ? var.account_network_cidr : local.networks[var.stage]}"
}

module "add_users" {
  source        = "../../modules/add-users/"
  users         = "${var.users}"
  templates_dir = "${var.templates_dir}"
  output_dir    = "${module.account.repo_dir}/conf/users"
}

locals {
  makefile_env = {
    ACCOUNTS_ENABLED = "${join(" ", var.accounts_enabled)}"
  }
}

# Write an env file that we can use from other Makefiles
module "export_makefile_env" {
  source      = "../../modules/export-env"
  env         = "${local.makefile_env}"
  output_file = "${var.artifacts_dir}/Makefile.env"
  format      = "%s = %s"
  type        = "raw"
}


# Write an tfvar file for this stage that we can use from terraform modules
#module "export_tfvars" {
#  source      = "../../modules/export-env"
#  env         = "${local.networks}"
#  output_file = "${var.artifacts_dir}/networks.tfvars"
#  template    = "networks = {\n%s\n}\n"
#  format      = "  %s = %s"
#}
