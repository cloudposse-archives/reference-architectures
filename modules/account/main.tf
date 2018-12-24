data "null_data_source" "terraform_root_modules" {
  count = "${length(var.terraform_root_modules)}"

  inputs = {
    module_name = "${basename(element(var.terraform_root_modules, count.index))}"
    copy_from = "COPY --from=terraform-root-modules /${element(var.terraform_root_modules, count.index)}/ /conf/${basename(element(var.terraform_root_modules, count.index))}/"
  }
}

locals {
  image_name = "${var.stage}.${var.domain}"
  repo_dir   = "${var.repos_dir}/${local.image_name}"

  context = {
    aws_account_id               = "${var.aws_account_id}"
    aws_root_account_id          = "${var.aws_root_account_id}"
    aws_region                   = "${var.aws_region}"
    docker_registry              = "${var.docker_registry}"
    image_name                   = "${local.image_name}"
    image_tag                    = "${var.image_tag}"
    motd_url                     = "${var.motd_url}"
    namespace                    = "${var.namespace}"
    stage                        = "${var.stage}"
    parent_domain_name           = "${var.domain}"
    geodesic_base_image          = "${var.geodesic_base_image}"
    terraform_root_modules_image = "${var.terraform_root_modules_image}"
    terraform_root_modules       = "${join("\n", data.null_data_source.terraform_root_modules.*.outputs.copy_from)}"
  }

  vars = "${merge(var.vars, local.context)}"
}

# Write an env file for this stage that we can use from shell scripts
resource "local_file" "artifacts" {
  content  = "export TERRAFORM_ROOT_MODULES=\"${join(" ", data.null_data_source.terraform_root_modules.*.outputs.module_name)}\"\n"
  filename = "${var.artifacts_dir}/${var.stage}.env"
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

#module "init_git" {
#  source      = "../../modules/init-git"
#  working_dir = "${local.repo_dir}"
#}

module "docker_build" {
  source          = "../../modules/docker-build"
  working_dir     = "${local.repo_dir}"
  short_name      = "${var.stage}"
  image_name      = "${local.image_name}"
  image_tag       = "${var.image_tag}"
  docker_registry = "${var.docker_registry}"
  depends_on      = ["${module.render.completed}", "${module.init_dirs.completed}"]
}
