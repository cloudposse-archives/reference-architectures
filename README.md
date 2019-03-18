# reference-architectures

Get up and running quickly with one of our reference architectures using our fully automated cold-start process.

**NOTE:** This project is under active development and subject to change. Please [file issues](https://github.com/cloudposse/reference-architectures/issues/new) for all bugs encountered.

## Table of Contents

- [reference-architectures](#reference-architectures)
  - [Table of Contents](#table-of-contents)
  - [Known Limitations](#known-limitations)
  - [High Level Overview](#high-level-overview)
    - [Architecture](#architecture)
    - [Assumptions](#assumptions)
    - [Checklist](#checklist)
  - [Get Started](#get-started)
    - [1. Provision Root Account](#1-provision-root-account)
    - [2. Provision Subaccounts](#2-provision-subaccounts)
    - [3. Delegate DNS](#3-delegate-dns)
  - [Next Steps](#next-steps)
  - [Getting Help](#getting-help)

## Known Limitations

- **AWS does not support programmatic deletion of accounts.** This means that if you use this project to create the account structure, terraform is not able to completely destroy it.
- **AWS by default only permits one subaccount.** This limit can be easily increased for your organization, but can take up to several days.
- **AWS will rate limit account creation.** This might mean you'll need to restart the provisioning (just re-run `make root`).

## High Level Overview

You can provision the basic reference architecture in 3 "easy" steps. =)

All accounts will leverage our [`terraform-root-modules`](https://github.com/cloudposse/terraform-root-modules/) service catalog to get you started. Later, we recommend you fork this and start your own service catalog suitable for your organization.

This process involves using `terraform` to generate the code (`Dockerfile`, `Makefile`, `terraform.tfvar`, etc) that you will use to manage your infrastructure.

This is a "bootstrap" process that gets you running from a cold-start. You do it once and then you literally throw _this_ (e.g. `reference-architectures/`) repo away. This project generates all the pre-configured boilerplate scaffolding you need in the `repos/` directory.

When you're done, in the `repos/` directory you'll have one Git repo for each AWS account. These repos are what you'll want to push up to GitHub. Each repo contains everything necessary to administer that account. We practice a strict "share nothing" approach, which is why each account gets it's own repo, terraform state backend, and DNS zone. This maximally reduces the blast radius of any human errors in one account affecting any other account. Also, because each account has it's own repo, it's _ideally_ suited for larger enterprise or corporate environments where various stakeholders will be responsible for running services in their account.

See the [Next Steps](#next-steps) section for where to go after this process completes.

### Architecture

Our "reference architecture" is an opinionated approach to architecting accounts for AWS.

This process provisions (7) accounts which have different designations.

Here is what it includes. Enable the accounts you want.

| Account  | Description                                                                               |
| -------- | ----------------------------------------------------------------------------------------- |
| root     | The "root" (parent, billing) account creates all child accounts and is where users login. |
| prod     | The "production" is account where you run your most mission critical applications         |
| staging  | The "staging" account is where you run all of your QA/UAT/Testing                         |
| dev      | The "dev" sandbox account is where you let your developers have fun and break things      |
| audit    | The "audit" account is where all logs end up                                              |
| corp     | The "corp" account is where you run the shared platform services for the company          |
| data     | The "data" account is where the quants live =)                                            |
| testing  | The "testing" account is where to run automated tests of untrusted infrastructure code    |
| security | The "security" account is where to run automated security scanning software               |
| identity | The "identity" account is where to add users and delegate access to the other accounts    |

Each account has its own [terraform state backend](https://github.com/cloudposse/terraform-aws-tfstate-backend), along with a [dedicated DNS zone](https://www.terraform.io/docs/providers/aws/r/route53_zone.html) for service discovery.

The root account owns the top-level DNS zone and then delegates NS authority to each child account.

### Assumptions

1. We are starting with a clean AWS environment and a new "root" (top-level) AWS account. This means you need the "root" credentials, since a fresh AWS account doesn't even have any AWS roles that can be assumed.
2. You have administrator access to this account.
3. You have [docker](https://docs.cloudposse.com/tools/docker/) installed on your workstation.
4. You have [terraform](https://www.terraform.io/downloads.html) installed on your workstation.

### Checklist

Before we get started, make sure you have the following

- [ ] Before you can create new AWS accounts under your organization, you must [verify your email address](https://docs.aws.amazon.com/console/organizations/email-verification).
- [ ] Open a support ticket to [request the limit](https://console.aws.amazon.com/support/v1#/case/create) of AWS accounts be increased for your organization (the default is 1).
- [ ] Clone this repo on your workstation.
- [ ] Create a _temporary_ pair of [Access Keys](https://console.aws.amazon.com/iam/home#/security_credential). These should be deleted afterwards.
- [ ] Export your AWS "root" account credentials as `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` (this is _temporary_ for bootstrapping).
- [ ] An available domain we can use for DNS-base service discovery (E.g. `ourcompany.co`). This domain must not be in use elsewhere as the root account will need to be the authoritative name server (`SOA`).
- [ ] Ensure that any users who will be added during this bootstrap process have created their [keybase](http://keybase.io) profile, and have an associated GPG key. You'll need this if setting them up in the `users` section of the [`config/root.tfvars`](https://github.com/cloudposse/reference-architectures/blob/master/configs/root.tfvars). For example you should be able to [verify each user's public key](https://keybase.io/osterman/key.asc) on `keybase.io` by running `curl https://keybase.io/$username/key.asc`.

## Get Started

### 1. Provision Root Account

The "root" account is the top-most AWS account from which all other AWS accounts are programmatically created.

**WARNING:** Terraform cannot remove an AWS account from an organization. Terraform **cannot** close the account. The child account must be prepared to be a standalone account beforehand. To do this, issue a password reset using the child account's email address. Login and accept the prompts. Then you should be good to go. See the [AWS Organizations documentation](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html) for more information.

**WARNING:** Do not chain the `make` targets together (e.g. `make root children finalize`) as it is not currently supported.

This account is provisioned slightly different from the other subaccounts.

Update the configuration for this account by editing the `configs/root.tfvar` file.

Then to get started, run:

```bash
make root
```

**NOTE:** We need to know each account's `AWS_ACCOUNT_ID` for Step 2.
**NOTE:** Sometimes provisioning of the `account` module fails due to rate limiting by AWS on creating subaccounts. If this happens, just run `make root/provision` to retry. If that works, just continue on to step 2, once it completes.

<details>
  <summary>Here's what that roughly looks like (but entirely automated). </summary>

1. Create a new account git repo.
2. Render templates into the repo (including `Dockerfile`).
3. Build a docker image.
4. Run the docker image and start provisioning resources including the Terraform state backend and child accounts.
5. Create the IAM groups to permit access to child accounts.
6. Write a list of child account IDs so we can use them in the next phase.

</details>

### 2. Provision Subaccounts

Subaccounts are created by the root account, but are ultimately provisioned using the subaccount containers.

Update the configuration for all the child accounts by editing the `configs/$stage.tfvar` file (replace `$stage` with the name of the account).

To get started, run:

```bash
make children
```

<details>

<summary>Here's what that roughly looks like (but entirely automated).</summary>

For each child account:

1. Create a new account git repo.
2. Render the templates for a `child` account into the repo directory (include `Dockerfile`). Obtain the account ID from the previous phase.
3. Build a docker image.
4. Run the docker image and start provisioning the child account's Terraform state bucket, DNS zone, cloudtrail logs, etc.

</details>

### 3. Delegate DNS

Now that each subaccount has been provisioned, we can delegate each DNS zone to those accounts.

To finish up, run:

```bash
make finalize
```

<details>
<summary>Here's what that roughly looks like (but entirely automated).</summary>

1. Re-use the docker images from phase (1) and phase (2).
2. Update DNS so that root account delegates DNS zones to the child accounts.
3. Enable cloudtrail log forwarding to audit account.

</details>

---

## Next Steps

At this point, you have everything you need to start terraforming your way to success.

All of your account configurations are currently in `repos/`

- [ ] Commit the changes in `repos/`. Open Pull Requests.
- [ ] Ensure that the name servers for the service discovery domain (e.g. `ourcompany.co`) have been configured with your domain registrar (e.g. GoDaddy).
- [ ] Delete your root account credentials. They are no longer needed and should not be used. Instead use the created IAM users.
- [ ] Request limits for EC2 instances to be raised in each account corresponding to the region you will be operating in.
- [ ] Set the child account's credentials. To do this, issue a password reset using the child account's email address. Login and accept the prompts. Setup MFA.
- [ ] Ensure you have MFA setup on your root account.
- [ ] Consider adding some other capabilities from our service catalog.
- [ ] Create your own [`terraform-root-modules`](https://github.com/cloudposse/terraform-root-modules) service catalog for your organization.

**NOTE:** _This_ repo can be deleted once you're all done and pushed your changes in the `repos/` directory to GitHub. The rest of your development should happen inside your infrastructure repos.

## Getting Help

Did you get stuck? Find us on [slack](https://sweetops.cloudposse.com) in the `#geodesic` channel.
