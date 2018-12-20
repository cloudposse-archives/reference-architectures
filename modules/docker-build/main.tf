variable "working_dir" {}

variable "image_name" {}

variable "image_tag" {}

variable "docker_registry" {}

variable "dockerfile" {
  default = "Dockerfile"
}

resource "null_resource" "docker_build" {
  provisioner "local-exec" {
    command     = "docker build -t ${var.image_name} -f ${var.dockerfile} ."
    working_dir = "${var.working_dir}"
  }
}

resource "null_resource" "docker_tag" {
  provisioner "local-exec" {
    command     = "docker tag ${var.image_name} ${var.docker_registry}/${var.image_name}:${var.image_tag}"
    working_dir = "${var.working_dir}"
  }
}
