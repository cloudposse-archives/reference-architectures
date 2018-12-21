data "template_file" "data" {
  count = "${length(var.templates)}"

  # this path is relative to repos/$image_name
  template = "${file("${var.templates_dir}/${element(var.templates, count.index)}")}"
  vars     = "${var.vars}"
}

resource "local_file" "data" {
  count    = "${length(var.templates)}"
  content  = "${element(data.template_file.data.*.rendered, count.index)}"
  filename = "${var.output_dir}/${replace(element(var.templates, count.index), var.strip, "")}"
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
