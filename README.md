# reference-architectures

Get up and running quickly with one of our reference architectures using our cold start process.

This is still under active development and subject to change.

## Known Limitations

* AWS does not support programmatic deletion of accounts. This means that if you use this project to create the account structure, terraform is not able to completely destroy it.
* AWS by default only permits one subaccount. This limit can be easily increased for your organization, but can take up to several days.

## High Level Overview

You can provision the basic reference architecture in 3 "easy" steps. =)

All accounts will leverage our [`terraform-root-modules`](https://github.com/cloudposse/terraform-root-modules/) to get started.

This process involves using terraform to generate the code (`Dockerfile`, `Makefile`, `terraform.tfvar`, etc) you will use to manage your infrastructure. 

This is a "bootstrap" process. You do it once and then you throw *this* repo away.

When you're done, you'll have one Git repo for each AWS account. The repo contains everything necessary to administer that account. We practice a strict "share nothing" approach, which is why each account gets it's own terraform state backend, repo, and DNS zone. This maximally reduces the blast radius of any human errors in one account affecting any other account. Also, because each account has it's own repo, it's *ideally* suited for larger enterprise or corporate environments where various stakeholders will be responsible for running services in their account.

## Architecture

Our "reference architecture" is an opinionated approach to architecting accounts for AWS. 

This process provisions (7) accounts which have different designations. 

Here is what it includes.

| Account | Description                                                                          |
| ------- | ------------------------------------------------------------------------------------ |
| root    | The "root" (parent) account creates all child accounts and is where users login      |
| prod    | The "production" is account where you run your most mission critical applications    |
| staging | The "staging" account is where you run all of your QA/UAT/Testing                    |
| dev     | The "dev" sandbox account is where you let your developers have fun and break things |
| audit   | The "audit" account is where all logs end up.                                        |
| corp    | The "corp" account is where you run platform services for the company                |
| data    | The "data" account is where the quants live =)                                       |

Each account has its own [terraform state backend](https://github.com/cloudposse/terraform-aws-tfstate-backend), along with a [dedicated DNS zone](https://www.terraform.io/docs/providers/aws/r/route53_zone.html) for service discovery.

The root account owns the top-level DNS zone and then delegates NS authority to each child account.

### Assumptions

1. We are starting with a clean AWS environment and a new "root" (top-level) AWS account. This means you need the "root" credentials, since a fresh AWS account doesn't even have any AWS roles that can be assumed.
2. You have administrator access to this account
3. You have [docker](https://docs.cloudposse.com/tools/docker/) installed on your workstation
4. You have [terraform](https://www.terraform.io/downloads.html) installed on your workstation


### Checklist

Before we get started, make sure you have the following

- [ ] Before you can create new AWS accounts under your organization, you must [verify your email address](https://docs.aws.amazon.com/console/organizations/email-verification).
- [ ] Open a support ticket to [request the limit](https://console.aws.amazon.com/support/v1#/case/create) of AWS accounts be increased for your organization (the default is 1).
- [ ] Clone this repo on your workstation
- [ ] Create a *temporary* pair of [Access Keys](https://console.aws.amazon.com/iam/home#/security_credential). These should be deleted afterwards.
- [ ] Export your AWS "root" account credentials as `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` (this is *temporary* for bootstrapping)
- [ ] An available domain we can use for DNS-base service discovery (E.g. `ourcompany.co`). This domain must not be in use else where.

### 1. Provision Root Account

The "root" account is the top-most AWS account from which all other AWS accounts are programmatically created.

__WARNING:__ Terraform cannot remove an AWS account from an organization. Terraform will not close the account. The member account must be prepared to be a standalone account beforehand. See the [AWS Organizations documentation](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html) for more information.

This account is provisioned slightly different from the other subaccounts.

Update the configuration for this account by editing the `configs/root.tfvar` file.

Then to get started, run:

```
make root
```

__NOTE:__ We need to know each account's `AWS_ACCOUNT_ID` for Step 2.

<details>
  <summary>Here's what that roughly looks like (but entirely automated). </summary>

1. Create a new account git repo
2. Render templates into the repo (including `Dockerfile`)
3. Build a docker image
4. Run the docker image and start provisioning resources including the Terraform state backend and child accounts
5. Write a list of child account IDs so we can use them in the next phase

</details>

### 2. Provision Subaccounts

Subaccounts are created by the root account, but are ultimately provisioned using the subaccount containers.

Update the configuration for all the child accounts by editing the `configs/root.tfvar` file.

To get started, run:

```bash
make children
```

<details>

<summary>Here's what that roughly looks like (but entirely automated).</summary>

For each child account:

1. Create a new account git repo
2. Render the templates for a `child` account into the repo directory (include `Dockerfile`). Obtain the account ID from the previous phase.
3. Build a docker image
4. Run the docker image and start provisioning the child account's Terraform state bucket, DNS zone, cloudtrail logs,

</details>

### 3. Delegate DNS

Now that each subaccount has been provisioned, we can delegate each DNS zone to those accounts.

To finish up, run:

```bash
make root/finalize
```

<details>
<summary>Here's what that roughly looks like (but entirely automated).</summary>

1. Rerun the docker image from phase (1)
2. Update DNS so that it delegates DNS zones to the child accounts
3. Create the IAM groups to permit access to child accounts

</details>

---

## Next Steps

At this point, you have everything you need to start terraforming your way to success.

All of your account configurations are currently in `repos/`

1. Commit the changes in `repos/`. Open Pull Requests.

2. Ensure that the name servers for the service discovery domain (e.g. `ourcompany.co`) have been configured with your domain registrar (e.g. GoDaddy)

3. Delete your root account credentials. They are no longer need and should not be used. Instead use IAM users.

4. Request limits for EC2 instances to be raised in each account corresponding to the region you will be operating in.

5. Consider adding some other capabilities from our service catalog.

6. Create your own [`terraform-root-modules`](https://github.com/cloudposse/terraform-root-modules) service catalog for your organization

__NOTE:__ *This* repo can be deleted once you're all done and pushed your changes to GitHub. The rest of your development will happen inside your infrastructure repos.

## Getting Help?

Did you get stuck? Find us on [slack](https://sweetops.cloudposse.com) in the `#geodesic` channel.
