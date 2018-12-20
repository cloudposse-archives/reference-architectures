output "docker_image" {
  value = "${var.docker_registry}/${local.image_name}:${var.image_tag}"
}
