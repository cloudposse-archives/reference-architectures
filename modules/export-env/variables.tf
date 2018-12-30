variable "env" {
  type = "map"
}

variable "output_file" {}

variable "template" {
  default = "%s\n"
}

variable "format" {
  default = "export %s=%s"
}

variable "type" {
  default = "encoded"
}
