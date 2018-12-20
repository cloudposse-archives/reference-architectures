variable "aws_account_id" {}

variable "aws_root_account_id" {}

variable "aws_region" {}

variable "namespace" {}

variable "stage" {}

variable "domain" {}

variable "image_tag" {
  default = "latest"
}

variable "templates" {
  type = "list"
}

variable "dirs" {
  type    = "list"
  default = ["", "conf", "rootfs"]
}

variable "vars" {
  type    = "map"
  default = {}
}

variable "strip" {
  default = ""
}

variable "repos_dir" {}
variable "templates_dir" {}
variable "docker_registry" {}

locals {
  image_name = "${var.stage}.${var.domain}"
  repo_dir   = "${var.repos_dir}/${local.image_name}"

  context = {
    aws_account_id      = "${var.aws_account_id}"
    aws_root_account_id = "${var.aws_root_account_id}"
    aws_region          = "${var.aws_region}"
    docker_registry     = "${var.docker_registry}"
    image_name          = "${local.image_name}"
    image_tag           = "${var.image_tag}"
    namespace           = "${var.namespace}"
    stage               = "${var.stage}"
  }

  vars = "${merge(local.context, var.vars)}"
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
}

#module "init_git" {
#  source      = "../../modules/init-git"
#  working_dir = "${local.repo_dir}"
#}

module "docker_build" {
  source          = "../../modules/docker-build"
  working_dir     = "${local.repo_dir}"
  image_name      = "${local.image_name}"
  image_tag       = "${var.image_tag}"
  docker_registry = "${var.docker_registry}"
}
