module "account" {
  source                       = "../../modules/account"
  dirs                         = "${var.dirs}"
  aws_account_id               = "${var.aws_account_ids[var.stage]}"
  aws_root_account_id          = "${var.aws_root_account_id}"
  aws_region                   = "${var.aws_region}"
  namespace                    = "${var.namespace}"
  stage                        = "${var.stage}"
  domain                       = "${var.domain}"
  motd_url                     = "${var.motd_url}"
  image_tag                    = "${var.image_tag}"
  templates                    = "${var.templates}"
  dirs                         = "${var.dirs}"
  vars                         = "${var.vars}"
  strip                        = "${var.strip}"
  artifacts_dir                = "${var.artifacts_dir}"
  repos_dir                    = "${var.repos_dir}"
  templates_dir                = "${var.templates_dir}"
  docker_registry              = "${var.docker_registry}"
  geodesic_base_image          = "${var.geodesic_base_image}"
  terraform_root_modules_image = "${var.terraform_root_modules_image}"
  terraform_root_modules       = "${var.terraform_root_modules}"
}
