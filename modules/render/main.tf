data "template_file" "data" {
  count = "${length(var.templates)}"

  # this path is relative to repos/$image_name
  template = "${file("${var.templates_dir}/${element(var.templates, count.index)}")}"
  vars     = "${var.vars}"
}

resource "null_resource" "init_dirs" {
  triggers {
    deps = "${join(",",var.depends_on)}"
  }
}

resource "local_file" "data" {
  count      = "${length(var.templates)}"
  content    = "${element(data.template_file.data.*.rendered, count.index)}"
  filename   = "${var.output_dir}/${replace(element(var.templates, count.index), var.strip, "")}"
  depends_on = ["null_resource.init_dirs"]
}

# https://github.com/terraform-providers/terraform-provider-local/issues/19
resource "null_resource" "chmod" {
  triggers {
    files = "${join(" ", local_file.data.*.filename)}"
  }

  provisioner "local-exec" {
    command = "chmod 644 ${null_resource.chmod.triggers.files}"
  }
}

resource "null_resource" "completed" {
  depends_on = ["null_resource.chmod"]

  triggers {
    chmod = "${null_resource.chmod.id}"
  }
}
