variable "vars" {
  type = "map"
}

variable "output_dir" {}
variable "templates_dir" {}

variable "templates" {
  type = "list"
}

variable "strip" {
  default = ""
}

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
