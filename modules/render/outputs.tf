output "completed" {
  depends_on = ["null_resource.completed"]
  value      = "${null_resource.completed.id}"
}
