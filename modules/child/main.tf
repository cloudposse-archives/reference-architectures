locals {
  account_network_cidr = "${length(var.account_network_cidr) > 0 ? var.account_network_cidr : var.networks[var.stage]}"

  context = {
    # Used by `README.md`
    account_email_address = "${format(var.account_email, var.stage)}"

    # Divide the account network CIDR in half (first half for kops, second half for backing_services) 
    kops_cidr                = "${cidrsubnet(local.account_network_cidr, 1, 0)}"
    kops_non_masquerade_cidr = "${var.kops_non_masquerade_cidr}"
    backing_services_cidr    = "${cidrsubnet(local.account_network_cidr, 1, 1)}"
  }

  vars = "${merge(var.vars, local.context)}"
}

module "account" {
  source                 = "git::https://github.com/RyanJarv/reference-architectures.git//modules/account?ref=master"
  dirs                   = "${var.dirs}"
  aws_account_id         = "${var.aws_account_ids[var.stage]}"
  aws_root_account_id    = "${var.aws_root_account_id}"
  aws_region             = "${var.aws_region}"
  namespace              = "${var.namespace}"
  stage                  = "${var.stage}"
  domain                 = "${var.domain}"
  motd_url               = "${var.motd_url}"
  image_tag              = "${var.image_tag}"
  templates              = "${var.templates}"
  vars                   = "${local.vars}"
  strip                  = "${var.strip}"
  artifacts_dir          = "${var.artifacts_dir}"
  repos_dir              = "${var.repos_dir}"
  templates_dir          = "${var.templates_dir}"
  docker_registry        = "${var.docker_registry}"
  geodesic_base_image    = "${var.geodesic_base_image}"
  terraform_root_modules = "${var.terraform_root_modules}"
  org_network_cidr       = "${var.org_network_cidr}"
  account_network_cidr   = "${local.account_network_cidr}"
}
