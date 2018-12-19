variable "name" {
  default = "root"
}

variable "domain" {}

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
  default = "/\\.(root)$/"
}

variable "working_dir" {}

locals {
  image_name  = "${var.name}.${var.domain}"
  working_dir = "${var.working_dir}/${local.image_name}"

  vars = "${merge(map("image_name", local.image_name), var.vars)}"
}

module "dir-init" {
  source      = "../dir-init"
  working_dir = "${local.working_dir}"
  dirs        = "${var.dirs}"
}

module "render" {
  source      = "../render"
  working_dir = "${local.working_dir}"
  templates   = "${var.templates}"
  strip       = "${var.strip}"
  vars        = "${local.vars}"
}

#module "git_init" {
#  source      = "../git-init"
#  working_dir = "${local.working_dir}"
#}

module "docker_build" {
  source      = "../docker-build"
  working_dir = "${local.working_dir}"
  image_name  = "${local.image_name}"
}
