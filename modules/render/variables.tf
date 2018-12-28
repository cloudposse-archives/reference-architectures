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

# NOTE: this variable won't actually be used for anything and the actual `depends_on` keyword 
# in terraform does not support interpolation.
variable "depends_on" {
  type    = "list"
  description = "Define a list of variables that this module depends on in order to force serialized execution."
  default = []
}
