# \${image_name}

This repository provides all the tooling to manage the `${stage}` account infrastructure on AWS. It distributes a single docker container which bundles the entire tool-chain and infrastructure as code necessary to administer the account.

## Acount Details

| Property       | Value                                                                                                                         |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| AWS Account ID | ${aws_account_id}                                                                                                             |
| Account Email  | ${account_email_address}                                                                                                      |
| Login URL      | <https://signin.aws.amazon.com/switchrole?account=${aws_account_id}&roleName=role_name&displayName=${namespace}-${stage}-admin> |
| Namespace      | ${namespace}                                                                                                                  |
| Stage          | ${stage}                                                                                                                      |
| Default Region | ${aws_region}                                                                                                                 |

## Goals & Principles

This project aims to be lightweight. It follows these principles:

- **Use industry standard tools** over custom ones. e.g. [terraform](https://github.com/hashicorp/terraform) and [chamber](https://github.com/segmentio/chamber)
- **Favor documentation over automation.** Instead of wrapping [terraform](https://github.com/hashicorp/terraform) and obfuscating layers of complexity, provide documentation on [terraform](https://github.com/hashicorp/terraform) "best practices" and actionable examples.
- **Automate Repetitive Processes** using `Makefiles`. Only introduce automation when a repetitive workflow emerges. Write simple shell scripts that provide minimal orchestration to avoid obfuscation of the underlying workflows.

We use the [Geodesic](https://github.com/cloudposse/geodesic) base image for the `${stage}` account infrastructure. It’s a swiss army knife for creating and building consistent platforms to be shared across a team environment. It easily versions environments in a repeatable manner that can be followed by any team member.

**NOTE:** This repo was created automatically using the [`cloudposse/reference-architectures`](https://github.com/cloudposse/reference-architectures) cold-start project.

## Introduction

We use [geodesic](https://github.com/cloudposse/geodesic) to define and build world-class cloud infrastructures backed by AWS and powered by Kubernetes.

The `geodesic` base docker image exposes many tools that can be used to define and provision AWS and Kubernetes resources.

There's no need to install any native software dependencies on your workstation other than docker.

Here is the list of some of the tools we use to provision `${image_name}` infrastructure in order to facilitate cloud fabrication and administration:

- [aws-vault](https://github.com/99designs/aws-vault)
- [chamber](https://github.com/segmentio/chamber)
- [terraform](https://www.terraform.io/)
- [kops](https://github.com/kubernetes/kops)
- [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/)
- [helm](https://helm.sh/)
- [helmfile](https://github.com/roboll/helmfile)

**NOTE:** Additional documentation can be found in the [`docs/`](docs/) directory.

## Layout

This repo is organized in the following way.

```text
${image_name}/
├── conf/                          # All configurations should be kept here
│   ├── Makefile                   # Makefile for controlling interactions between projects
│   ├── module1/                   # Example terraform "root" module (aka project)
│   │   └── terraform.tfvars       # Define project specific settings using a varfile (do not commit secrets)
│   ├── module2/                   # Another terraform "root" module
│   │   └── terraform.tfvars       # Terraform settings specific to this project
│   └── module3/                   # Another terraform "root" module
│       ├── file1.tf               # Overlay additional files
│       └── file2.tf               #
├── docs/                          # Additional documentation
├── Dockerfile                     # Dockerfile that describes how to build this image
├── Makefile                       # Makefile that uses the `build-harness` to facilitate building the image
└── rootfs/                        # "Root" (`/`) filesystem which is overlayed inside of the docker image
```

## Configuration Settings

Most configuration settings are defined as environment variables. These can be set using the `ENV` declaration in the [`Dockerfile`](Dockerfile). These have been set to _sane defaults_ and shouldn't need to be touched. All these settings are required.

<details>
<summary>List of Supported Environment Variables</summary>

| Environment Variable  | Description of the setting                                                    |
| --------------------- | ----------------------------------------------------------------------------- |
| DOCKER_IMAGE          | _This_ docker image name (and repository). This is for the bootstrap script.  |
| DOCKER_TAG            | The default image tag to use by the bootstrap script.                         |
| NAMESPACE             | Resource namespace used as a prefix for all AWS resources.                    |
| STAGE                 | Operating stage of this account (e.g. prod, corp, audit, root).               |
| BANNER                | Banner text to display when launching an interactive shell.                   |
| MOTD_URL              | URL to a "Message of the Day" to display when launching an interactive shell. |
| AWS_REGION            | Current operating region for this account.                                    |
| AWS_DEFAULT_REGION    | Default operating region for this account.                                    |
| AWS_ACCOUNT_ID        | AWS Account ID (used by `aws-config-setup`).                                  |
| AWS_ROOT_ACCOUNT_ID   | AWS "Root" (parent) Account ID (used by `aws-config-setup`).                  |
| ORG_NETWORK_CIDR      | Organizations Network CIDR .                                                  |
| ACCOUNT_NETWORK_CIDR  | _This_ account's network CIDR.                                                |
| TF_BUCKET             | Terraform state bucket.                                                       |
| TF_BUCKET_REGION      | Region where the Terraform state bucket was created.                          |
| TF_DYNAMODB_TABLE     | DynamoDB table that will be used by Terraform for state locking.              |
| AWS_DEFAULT_PROFILE   | AWS Profile that will be used by `aws-vault` to assume roles.                 |
| CHAMBER_KMS_KEY_ALIAS | Default KMS key that will be used to encrypt secrets for chamber.             |

**NOTE:** You can use [`tfenv`](https://github.com/cloudposse/tfenv) to easily pass environment variables to terraform.

</details>

## Prerequisites

- [Docker](https://docs.docker.com/install/) is required to build & run all containers
- Standard development tools (e.g. `xcode-select --install` on OSX): `git`, `make`

**NOTE:** It should work out-of-the-box with Mac OSX, Linux, and Windows 10 (using WSL).

## Quick Start

Here's how to get started with this repository.

<details>
<summary>Basic Operating Instructions</summary>

### Initialize the Project

First, let's initialize the [`build-harness`](https://github.com/cloudposse/build-harness). You only need to do this once per `git clone` of this repository.

```bash
# Initialize the project's build-harness
make init
```

### Build Docker Image

Build the docker image we'll use for local development, to provision infrastructure or to administer AWS.

```bash
make docker/build
```

### Install the Wrapper Shell

Install the helper script which makes it easier to start the docker container. You only really need to do this once.

```bash
make install
```

### Run the Shell

Anytime you want to interact with tools like terraform, chamber, etc we recommend you do so from within the shell.

```bash
/usr/local/bin/${image_name}
```

**NOTE (a):** You can just run `${image_name}`, if your `PATH` contains `/usr/local/bin`
**NOTE (b):** Your `HOME` directory is mounted to `/localhost` inside of the container. This makes it easier to do local development or use your IDE of choice.

### Setup AWS IAM Account

_([inside the shell](#run-the-shell))_

Configure your AWS profile in `~/.aws/config` by running `aws-config-setup` inside of the shell. This will also prompt you to setup [`aws-vault`](https://github.com/99designs/aws-vault).

**NOTE:** You only need to do this once per AWS account.

```bash
aws-config-setup
```

### Login to AWS

_([inside the shell](#run-the-shell))_

Run this command anytime you start a new shell and need to operate on AWS:

```bash
assume-role
```

## Using Terraform

_([inside the shell](#run-the-shell))_

**NOTE:** Before provisioning AWS resources with Terraform, you need to create a `tfstate-backend` first. This is an S3 bucket that is used to store the Terraform state and a DynamoDB table for state locking.

You need to do it only once per account during the cold-start.

```bash
make -C /conf/tfstate-backend init
```

After `tfstate-backend` has been provisioned, you can just run `init-terraform` from any project folder to reattach the remote state.

For more info, see [Using Geodesic with Terraform](https://docs.cloudposse.com/geodesic/module/with-terraform/)

</details>

## References

- https://docs.cloudposse.com
- https://github.com/cloudposse/geodesic
- https://github.com/cloudposse/packages
- https://github.com/cloudposse/build-harness

## Getting Help

Did you get stuck? Find us on [slack](https://slack.cloudposse.com) in the `#geodesic` channel.
