output "completed" {
  value = "${null_resource.completed.id == "" ? "false" : "true"}"
}
