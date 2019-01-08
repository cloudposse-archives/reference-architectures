variable "aws_account_ids" {
  type = "map"
}

variable "aws_root_account_id" {}

variable "aws_region" {}

variable "namespace" {}

variable "stage" {}

variable "domain" {}

variable "motd_url" {}

variable "image_tag" {
  default = "latest"
}

variable "account_email" {}

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
  default = "/\\.(child|kops)$/"
}

variable "networks" {
  type    = "map"
  default = {}
}

variable "org_network_cidr" {}

variable "account_network_cidr" {
  default = ""
}

# Read more: <https://kubernetes.io/docs/tasks/administer-cluster/ip-masq-agent/#key-terms>
variable "kops_non_masquerade_cidr" {
  description = "The CIDR range for Pod IPs."
  default     = "100.64.0.0/10"
}

variable "artifacts_dir" {}

variable "repos_dir" {}

variable "templates_dir" {}

variable "docker_registry" {}

variable "geodesic_base_image" {}

variable "terraform_root_modules" {
  type = "list"
}

variable "helmfiles_image" {
  default = "cloudposse/helmfiles:latest"
}

variable "terraform_root_modules_image" {}
