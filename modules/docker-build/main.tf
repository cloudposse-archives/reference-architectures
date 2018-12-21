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

  depends_on = ["null_resource.docker_build"]
}

resource "null_resource" "docker_tag_short_name" {
  count = "${signum(length(var.short_name))}"

  provisioner "local-exec" {
    command     = "docker tag ${var.image_name} ${var.short_name}"
    working_dir = "${var.working_dir}"
  }

  depends_on = ["null_resource.docker_build"]
}
