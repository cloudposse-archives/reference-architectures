# reference-architectures

Get up and running quickly with one of our reference architecture using our cold start process. 

This is still under active development and subject to change. 

## High Level Overview

You can provision the basic referrence architecutre in 3 "easy" steps. =)

All steps leverage our [`terraform-root-modules`](https://github.com/cloudposse/terraform-root-modules/) to get started.

This process involves using terraform to generate the code (`Dockerfile`, `Makefile`, `terraform.tfvar`, etc) you will use to manage your infrastructure. 

This is a "bootstrap" process. You do it once and then you throw *this* repo away.

## Architecture

Our "reference architecture" is an opinionated approach to architecting accounts for AWS. 

This process provisions (7) accounts which have different designations. 

Here is what it includes.

| Account | Description                                                                       |
|---------|-----------------------------------------------------------------------------------|
| root    | The "root" (parent) account which creates all child accounts                      |
| prod    | The "production" account where you run your most mission critical applications    |
| staging | The "staging" account where you run all of your QA/UAT/Testing                    |
| dev     | The "dev" sandbox account where you let your developers have fun and break things |
| audit   | The "audit" account is where all logs end up.                                     |
| corp    | The "corp" account is where you run platform services for the company             |
| data    | The "data" account is where the quants live =)                                    |

Each account has its own [terraform state backend](https://github.com/cloudposse/terraform-aws-tfstate-backend), along with a [dedicated DNS zone](https://www.terraform.io/docs/providers/aws/r/route53_zone.html) for service discovery.

The root account owns the top-level DNS zone and then delegates NS authority to each child account.

### Assumptions

1. We are starting with a clean AWS environment and a new "root" (top-level) AWS account. This means you need the "root" credentials, since a fresh AWS account doesn't even have any AWS roles that can be assumed.
2. You have administrator access to this account

### Checklist

Before we get started, make sure you have the following

- [ ] Clone this repo on your workstation
- [ ] Have your AWS credentials handy
- [ ] DNS Zone which will be used for AWS service discovery (E.g. `ourcompany.co`)

### 1. Provision Root Account

The "root" account is the top-most AWS account from which all other AWS accounts are programatically created.

This account is provisioned slightly different from the other subccounts.

To get started, run:

```
make init/root
```

<details>
  <summary>Here's the pseudo code of what that roughly looks like (but automated). </summary>

```
| mkdir repo
| cd repo
| git init
| Render dockerfile from template
|   (Use multi-stage for tfstate, accounts, root-dns)
| Build docker image
| Docker run the image mounting `scripts/` and `artifacts/`
|   Setup AWS vault
|   aws-vault exec ${AWS_PROFILE} -- /scripts/init-tfstate
|   aws-vault exec ${AWS_PROFILE} -- /scripts/init-accounts
```

We need to know each account's `AWS_ACCOUNT_ID` for Step 2.
</details>

### 2. Provision Subaccounts

Subaccounts are created by the root account, but are ultimately provisioned using the subaccount containers.

To get started, run: 

```
make init/child
```

<details>

<summary>Here's the pseudo code of what that roughly looks like (but automated):</summary>

```
for account in ${ACCOUNTS}; do
  mkdir $account
  cd $account
  git init
  # Render dockerfile from template
  # Use multi-stage for tfstate and account-dns
  # Build docker image
  # Docker run the image -v scripts/:/scripts
  # Setup AWS vault
  # assume-role
  # init tfstate
  # init account-dns
  cd ..
done
```
</details>

### 3. Delegate DNS

Now that each subaccount has been provisioned, we can delegate each DNS zone to those accounts.

To finish up, run:

```
make finalize/root
```


<details>
<summary>Here's the pseudo code of what that roughly looks like (but automated).</summary>
```
# Docker run the image
# assume role
# init tfstate
# init accounts
```
</details>

---

## Next Steps

At this point, you have everything you need to start terraforming your way to success.

1. Commit your changes. Open Pull Requests. 

2. Ensure that the nameservers for the service discovery domain (e.g. `ourcompany.co`) have been configured with your domain registrar (e.g. GoDaddy)

3. Consider adding some other capabilities from our service catalog.

4. Create your own [`terraform-root-modules`](https://github.com/cloudposse/terraform-root-modules) service catalog for your organization


__NOTE:__ *This* `reference-architectures` repo can be deleted once you're all done and pushed your changes to GitHub. The rest of your development will happen inside your infrastructure repos.

