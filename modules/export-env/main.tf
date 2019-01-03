locals {
  keys   = "${keys(var.env)}"
  values = "${values(var.env)}"
}

data "null_data_source" "envs" {
  count = "${length(local.keys)}"

  inputs = {
    encoded = "${format(var.format, element(local.keys, count.index), jsonencode(element(local.values, count.index)))}"
    raw     = "${format(var.format, element(local.keys, count.index), element(local.values, count.index))}"
  }
}

locals {
  export = {
    encoded = "${format(var.template, join("\n", data.null_data_source.envs.*.outputs.encoded))}"
    raw     = "${format(var.template, join("\n", data.null_data_source.envs.*.outputs.raw))}"
  }
}

# Write an env file that we can use from shell scripts
resource "local_file" "env_file" {
  content  = "${local.export[var.type]}"
  filename = "${var.output_file}"
}
