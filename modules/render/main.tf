variable "vars" {
  type = "map"
}

variable "working_dir" {}

variable "templates" {
  type = "list"
}

variable "strip" {
  default = ""
}

data "template_file" "data" {
  count    = "${length(var.templates)}"
  template = "${file("../templates/${element(var.templates, count.index)}")}"
  vars     = "${var.vars}"
}

resource "local_file" "data" {
  count    = "${length(var.templates)}"
  content  = "${element(data.template_file.data.*.rendered, count.index)}"
  filename = "${var.working_dir}/${replace(element(var.templates, count.index), var.strip, "")}"
}
