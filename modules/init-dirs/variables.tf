variable "working_dir" {}

variable "dirs" {
  type    = "list"
  default = ["", "conf", "rootfs"]
}

variable "depends_on" {
  type    = "list"
  default = []
}
