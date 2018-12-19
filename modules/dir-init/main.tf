variable "working_dir" {}

variable "dirs" {
  type    = "list"
  default = ["", "conf", "rootfs"]
}

resource "null_resource" "mkdir" {
  triggers {
    dirs = "${join(" ", formatlist("${var.working_dir}/%s", sort(compact(var.dirs))))}"
  }

  provisioner "local-exec" {
    command = "mkdir -p ${null_resource.mkdir.triggers.dirs}"
  }
}

# Touch `.gitignore` in each directory to ensure directories persist with git
resource "null_resource" "touch" {
  triggers {
    files = "${join(" ", formatlist("${var.working_dir}/%s/.gitignore", sort(compact(var.dirs))))}"
  }

  provisioner "local-exec" {
    command = "touch ${null_resource.touch.triggers.files}"
  }
}
