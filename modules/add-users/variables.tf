variable "output_dir" {}

variable "templates_dir" {}

variable "users" {
  type        = "map"
  description = "A map of AWS IAM usernames to create mapped to their keybase username (e.g. { 'user@example.com' => 'keybase_user_name' })"
  default     = {}
}
