data "null_data_source" "terraform_root_modules" {
  count = "${length(var.terraform_root_modules)}"

  inputs = {
    module_name = "${basename(element(var.terraform_root_modules, count.index))}"
    copy_from   = "COPY --from=terraform-root-modules /${element(var.terraform_root_modules, count.index)}/ /conf/${basename(element(var.terraform_root_modules, count.index))}/"
  }
}

locals {
  domain_name = "${var.stage}.${var.domain}"
  image_name  = "${local.domain_name}"
  repo_dir    = "${var.repos_dir}/${local.image_name}"

  context = {
    aws_account_id         = "${var.aws_account_id}"
    aws_root_account_id    = "${var.aws_root_account_id}"
    aws_region             = "${var.aws_region}"
    docker_registry        = "${var.docker_registry}"
    domain_name            = "${local.domain_name}"
    image_name             = "${local.image_name}"
    image_tag              = "${var.image_tag}"
    motd_url               = "${var.motd_url}"
    namespace              = "${var.namespace}"
    stage                  = "${var.stage}"
    parent_domain_name     = "${var.domain}"
    geodesic_base_image    = "${var.geodesic_base_image}"
    terraform_root_modules = "${join("\n", data.null_data_source.terraform_root_modules.*.outputs.copy_from)}"
    org_network_cidr       = "${var.org_network_cidr}"
    account_network_cidr   = "${var.account_network_cidr}"
  }

  vars = "${merge(var.vars, local.context)}"

  env = {
    TERRAFORM_ROOT_MODULES = "${join(" ", data.null_data_source.terraform_root_modules.*.outputs.module_name)}"
  }
}

# Write an env file for this stage that we can use from shell scripts
module "export_env" {
  source      = "../../modules/export-env"
  env         = "${local.env}"
  output_file = "${var.artifacts_dir}/${var.stage}.env"
  format      = "export %s=%s"
}

module "init_dirs" {
  source      = "../../modules/init-dirs"
  working_dir = "${local.repo_dir}"
  dirs        = "${var.dirs}"
}

module "render" {
  source        = "../../modules/render"
  output_dir    = "${local.repo_dir}"
  templates_dir = "${var.templates_dir}"
  templates     = "${var.templates}"
  strip         = "${var.strip}"
  vars          = "${local.vars}"
  depends_on    = ["${module.init_dirs.completed}"]
}

module "docker_build" {
  source          = "../../modules/docker-build"
  working_dir     = "${local.repo_dir}"
  short_name      = "${var.stage}"
  image_name      = "${local.image_name}"
  image_tag       = "${var.image_tag}"
  docker_registry = "${var.docker_registry}"
  depends_on      = ["${module.render.completed}", "${module.init_dirs.completed}"]
}
