# Infrastructure Projects

Terraform and Kubernetes projects exist in here.

## Terraform workflow

Terraform operates on a "workspace". We have a named workspace for each AWS account.
In these examples, we will use "dev" as the workspace we are operating on, but "dev"
can be replaced with any workspace name for which there is a `conf/$workspace.tfvars` file.

### Manual, multi-step workflow

Remember, replace "dev" with whatever valid workspace name you want.

```bash
make init           # initializes Terraform
make workspace/dev  # selects workspace "dev"
make plan           # make planfile for current workspace
make apply          # apply planfile for current workspace, delete planfile on success
```

### Automatic, single-step workflow

Remember, replace "dev" with whatever valid workspace name you want.

- Generate Terraform planfile (the output of `terraform plan` and input to `terraform apply`), if needed:

  ```bash
  make dev.planfile
  ```

- Optionally/alternatively: (re-)generate Terraform planfile regardless of whether there is a current up-to-date one already:

  ```bash
  make dev.plan
  ```

- Apply an existing planfile and delete it on success. Will fail if planfile does not exist:

  ```bash
  make dev.apply
  ```

## Cold Start

Initiating the project requires a specific order.

* Initialize the [tfstate-backend](tfstate-backend/README.md)
* Create the [accounts](account/README.md)
* Configure [SSO](sso/README.md) with a GSuite Admin
* Configure [primary IAM roles](iam-primary-roles/README.md)
* Configure [delegated IAM roles](iam-delegated-roles/)
* Configure [VPCs](vpc/)
* Configure [CloudTrail bucket](cloudtrail-bucket/) on `master`
* Configure [CloudTrail](cloudtrail/) per account
* Configure [primary DNS zones](dns-primary/)
* Configure [delegated DNS zones](dns-delegated/)
* Configure [EKS clusters](eks/)
* Configure [EFS](efs/)
* Configure [EKS IAM Roles](eks-iam/)
* Configure [Helm external-dns](helmfiles/external-dns)
* Configure [Helm metrics-server](helmfiles/kube-state-metrics)
