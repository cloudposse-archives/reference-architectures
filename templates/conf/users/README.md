
## Adding a New User

To add new users, add them to this directory.

Add new users by adding a `.tf` file in this directory for their configuration.

For a user with an email of `user@example.co`, their configuratino would look like this:

```
module "user_example_co" {
  source        = "git::https://github.com/cloudposse/terraform-aws-iam-user.git?ref=tags/0.1.1"
  name          = "user@example.co"
  pgp_key       = "keybase:exampleuser"
  groups        = ["${namespace}-${stage}-admins"]
  force_destroy = "true"
}

output "user@example.co" {
  description = "Decrypt command"
  value       = "$${module.user_example_co.keybase_password_decrypt_command}"
}
```

After adding the user, rebuild the container. 

1. Run the container and `cd /conf/users`. 
2. Run `assume-role` to login to AWS
3. Run `make apply` to provision the user.

## Temporary Login Credentials

After provisioning the user, their base64 keybase encrypted password will be output by the module. 

To retrieve a user's base64 encrypted password decrypt command, run the following command:

```
terraform output user@example.co
```

**IMPORTANT** This assumes you've started the shell and run `assume-role` to login. Run `make init` to setup the remote state.

## User Account Setup

The user will need to then setup their AWS account. They will do this by going to the [login URL](../README.md) for the "root" account.

In order to login, they will need to enter their email address followed by their temporary password which was obtained by running the decrypt command from the terraform output. 

After setting up their password, the user will need to [attach an MFA device](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_mfa_enable_virtual.html) to their account or ask for from from their friendly sysadmin. Then they will need to log out and log back in again using their MFA device. Using this new login session, then navigate to the [IAM menu and obtain the AWS credentials](https://aws.amazon.com/blogs/security/wheres-my-secret-access-key/) (*AWS Access Key ID* and *AWS Secret Access Key*) for their account. These will be needed when setting up their shell with `aws-vault`.
