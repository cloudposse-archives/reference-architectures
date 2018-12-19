variable "working_dir" {}

variable "image_name" {}

variable "dockerfile" {
  default = "Dockerfile"
}

resource "null_resource" "docker_build" {
  provisioner "local-exec" {
    command     = "docker build -t ${var.image_name} -f ${var.dockerfile} ."
    working_dir = "${var.working_dir}"
  }
}
