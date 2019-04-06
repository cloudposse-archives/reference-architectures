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

  depends_on = ["null_resource.mkdir"]
}

resource "null_resource" "completed" {
  triggers {
    # We do not care about the values, and in fact we do not want "depends_on" to change,
    # but we do want and need to wait for the values to be availble.
    depends_on = "${coalesce(null_resource.mkdir.id,null_resource.touch.id) == "" ? "false" : "true"}"
  }
}
