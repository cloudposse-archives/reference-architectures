# reference-architectures

Get up and running quickly with one of our reference architecture using our cold start process.

This is still under active development and subject to change. 

## High Level Overview

You can provision the basic referrence architecutre in 3 "easy" steps. =)

All steps leverage our [`terraform-root-modules`](https://github.com/cloudposse/terraform-root-modules/) to get started.

### Assumptions

1. We are starting with a clean AWS environment and a new "root" (top-level) AWS account. 
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
make init-root-account
```


Here's the pseudo code of what that roughly looks like (but automated):

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

### 2. Provision Subaccounts

Subaccounts are created by the root account, but are ultimately provisioned using the subaccount containers.

To get started, run: 

```
make init-subaccounts
```

Here's the pseudo code of what that roughly looks like (but automated):

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

### 3. Delegate DNS

Now that each subaccount has been provisioned, we can delegate each DNS zone to those accounts.

To finish up, run:

```
make finalize-root-account
```


Here's the pseudo code of what that roughly looks like (but automated):
```
# Docker run the image
# assume role
# init tfstate
# init accounts
```

---

## Next Steps

At this point, you have everything you need to start terraforming your way to success.

1. Commit your changes. Open Pull Requests. 

2. Ensure that the nameservers for the service discovery domain (e.g. `ourcompany.co`) have been configured with your domain registrar (e.g. GoDaddy)

3. Consider adding some other capabilities from our service catalog.

4. Create your own [`terraform-root-modules`](https://github.com/cloudposse/terraform-root-modules) service catalog for your organization


__NOTE:__ *This* `reference-architectures` repo can be deleted once you're all done and pushed your changes to GitHub. The rest of your development will happen inside your infrastructure repos.



