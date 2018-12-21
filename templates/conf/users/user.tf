module "${resource_name}" {
  source        = "git::https://github.com/cloudposse/terraform-aws-iam-user.git?ref=tags/0.1.1"
  name          = "${username}"
  pgp_key       = "keybase:${keybase_username}"
  groups        = "$${local.admin_groups}"
  force_destroy = "true"
}

output "${username}" {
  description = "Decrypt command"
  value       = "$${module.${resource_name}.keybase_password_decrypt_command}"
}
