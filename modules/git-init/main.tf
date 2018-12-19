variable "working_dir" {}

resource "null_resource" "git_init" {
  provisioner "local-exec" {
    command     = "git init"
    working_dir = "${var.working_dir}"
  }
}

resource "null_resource" "git_checkout_master" {
  provisioner "local-exec" {
    command     = "git -C ${var.working_dir} checkout -b master"
    working_dir = "${var.working_dir}"
  }
}

resource "null_resource" "git_checkout_init" {
  provisioner "local-exec" {
    command     = "echo git checkout -b init"
    working_dir = "${var.working_dir}"
  }
}

resource "null_resource" "git_add" {
  provisioner "local-exec" {
    command     = "echo git add *"
    working_dir = "${var.working_dir}"
  }
}
