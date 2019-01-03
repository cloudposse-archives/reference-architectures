variable "working_dir" {}

variable "image_name" {}

variable "short_name" {}

variable "image_tag" {}

variable "docker_registry" {}

variable "dockerfile" {
  default = "Dockerfile"
}

# NOTE: this variable won't actually be used for anything and the actual `depends_on` keyword 
# in terraform does not support interpolation.
variable "depends_on" {
  type        = "list"
  description = "Define a list of variables that this module depends on in order to force serialized execution."
  default     = []
}
