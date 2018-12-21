locals {
  unsafe_characters = "/[^A-Za-z0-9]+/"
}

data "template_file" "data" {
  count = "${length(keys(var.users))}"

  # this path is relative to repos/$image_name
  template = "${file("${var.templates_dir}/conf/users/user.tf")}"

  vars = {
    resource_name    = "${replace(element(keys(var.users), count.index), local.unsafe_characters, "_")}"
    username         = "${element(keys(var.users), count.index)}"
    keybase_username = "${element(values(var.users), count.index)}"
  }
}

resource "local_file" "data" {
  count    = "${length(keys(var.users))}"
  content  = "${element(data.template_file.data.*.rendered, count.index)}"
  filename = "${var.output_dir}/${replace(element(keys(var.users), count.index), local.unsafe_characters, "_")}.tf"
}

# https://github.com/terraform-providers/terraform-provider-local/issues/19
resource "null_resource" "chmod" {
  count = "${signum(length(keys(var.users)))}"
  triggers {
    files = "${join(" ", local_file.data.*.filename)}"
  }

  provisioner "local-exec" {
    command = "chmod 644 ${null_resource.chmod.triggers.files}"
  }
}
