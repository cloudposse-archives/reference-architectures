variable "aws_account_id" {}

variable "aws_region" {}

variable "namespace" {}

variable "stage" {
  default = "root"
}

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
  default = "/\\.(root)$/"
}

variable "repos_dir" {}
variable "templates_dir" {}
variable "docker_registry" {}

module "account" {
  source         = "../../modules/account/"
  dirs           = "${var.dirs}"
  aws_account_id = "${var.aws_account_id}"

  # For the "root" account these should always match
  aws_root_account_id = "${var.aws_account_id}"
  aws_region          = "${var.aws_region}"
  namespace           = "${var.namespace}"
  stage               = "${var.stage}"
  domain              = "${var.domain}"
  image_tag           = "${var.image_tag}"
  templates           = "${var.templates}"
  dirs                = "${var.dirs}"
  vars                = "${var.vars}"
  strip               = "${var.strip}"
  repos_dir           = "${var.repos_dir}"
  templates_dir       = "${var.templates_dir}"
  docker_registry     = "${var.docker_registry}"
}

output "docker_image" {
  value = "${module.account.docker_image}"
}
