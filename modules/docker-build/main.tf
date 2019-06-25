resource "null_resource" "docker_build" {
  # We have to acutally use the depends_on variable to make Terraform wait for the values to be finalized.
  # Because the "depends_on" feature does not work with modules, this is the only way we have been
  # able to get Terraform to wait for the file creation stage to finish before using the files.
  provisioner "local-exec" {
    command = "echo ${join(",",var.depends_on)} > /dev/null"
  }

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
