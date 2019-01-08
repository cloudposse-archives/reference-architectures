# Kops (Kubernetes Operations)

## Table of Contents
- [Kops (Kubernetes Operations)](#kops-kubernetes-operations)
  - [Table of Contents](#table-of-contents)
  - [Configuration Settings](#configuration-settings)
  - [Provision a Kops Cluster](#provision-a-kops-cluster)
    - [Step 1 - Configuration](#step-1---configuration)
    - [Step 2 - Provision AWS Dependencies](#step-2---provision-aws-dependencies)
    - [Step 3 - Provision the Cluster](#step-3---provision-the-cluster)
  - [References](#references)
  - [Getting Help](#getting-help)

## Configuration Settings

Most configuration settings are defined as environment variables.  These have been set to _sane defaults_ and shouldn't need to be touched. All these settings are required.

<details>
<summary>List of Supported Environment Variables</summary>

| Environment Variable                               | Description of the setting                                                                    |
| -------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| BASTION_MACHINE_TYPE                               | AWS EC2 instance type of bastion host                                                         |
| KOPS_ADMISSION_CONTROL_ENABLED                     | Toggle if adminission controller should be enabled                                            |
| KOPS_API_LOAD_BALANCER_IDLE_TIMEOUT_SECONDS        | AWS ELB idle connection timeout for the API load balancer                                     |
| KOPS_AUTHORIZATION_RBAC_ENABLED                    | Toggle Kubernetes RBAC support                                                                |
| KOPS_AVAILABILITY_ZONES                            | AWS Availability Zones (AZs) to use. Must all reside in the same region. Use an _odd_ number. |
| KOPS_AWS_IAM_AUTHENTICATOR_ENABLED                 | Toggle IAM Authenticator support                                                              |
| KOPS_BASE_IMAGE                                    | AWS AMI base image for all EC2 instances                                                      |
| KOPS_BASTION_PUBLIC_NAME                           | Hostname that will be used for the bastion instance                                           |
| KOPS_CLOUDWATCH_DETAILED_MONITORING                | Toggle detailed CloudWatch monitoring (increases operating costs)                             |
| KOPS_CLUSTER_AUTOSCALER_ENABLED                    | Toggle the Kubernetes node autoscaler capability                                              |
| KOPS_CLUSTER_NAME                                  | Cluster base hostname (E.g. `${aws_region}.${image_name}`)                                    |
| KOPS_DNS_ZONE                                      | Authoritative DNS Zone that will be populated automatic with hostnames                        |
| KOPS_KUBE_API_SERVER_AUTHORIZATION_MODE            | Ordered list of plug-ins to do authorization on secure port                                   |
| KOPS_KUBE_API_SERVER_AUTHORIZATION_RBAC_SUPER_USER | Username of the Kubernetes Super User                                                         |
| KOPS_NETWORK_CIDR                                  | The network used by kubernetes for `Pods` and `Services` in the cluster                       |
| KOPS_NON_MASQUERADE_CIDR                           | A list of strings in CIDR notation that specify the non-masquerade ranges.                    |
| KOPS_PRIVATE_SUBNETS                               | Subnet CIDRs for all EC2 instances                                                            |
| KOPS_STATE_STORE                                   | S3 Bucket that will be used to store the cluster state (E.g. `${aws_region}.${image_name}`)   |
| KOPS_UTILITY_SUBNETS                               | Subnet CIDRs for the publically facing services (e.g. ingress ELBs)                           |
| KUBERNETES_VERSION                                 | Version of Kubernetes to deploy. Must be compatible with the `kops` release.                  |
| NODE_MACHINE_TYPE                                  | AWS EC2 instance type for the _default_ node pool                                             |
| NODE_MAX_SIZE                                      | Maximum number of EC2 instances in the _default_ node pool                                    |
| NODE_MIN_SIZE                                      | Minimum number of EC2 instances in the _default_ node pool                                    |

**IMPORTANT:**

1.  `KOPS_NETWORK_CIDR` and `KOPS_NON_MASQUERADE_CIDR` **MUST NOT** overlap
2.  `KOPS_KUBE_API_SERVER_AUTHORIZATION_MODE` is a comma-separated list (e.g.`AlwaysAllow`,`AlwaysDeny`,`ABAC`,`Webhook`,`RBAC`,`Node`)

</details>

There are (3) was to set environment variables.

1. Set them in the [`Dockerfile`](../Dockerfile). This is not recommended as they are global in scope.
2. Set them in `chamber`. This requires an AWS session and access to KMS + Parameter Store.
3. Set them in the `.envrc`. This is suitable for most values. Just to put any secrets in there.

## Provision a Kops Cluster

We create a [`kops`](https://github.com/kubernetes/kops) cluster from a manifest.

The manifest template is located in [`/templates/kops/default.yaml`](https://github.com/cloudposse/geodesic/blob/master/rootfs/templates/kops/default.yaml)
and is compiled by running `build-kops-manifest` either in the [`Dockerfile`](Dockerfile) or at runtime by calling `make kops/build-manifest`.

Provisioning a `kops` cluster takes three steps:

1. Update the the [environment settings](#configuration-settings) and rebuild/restart the `geodesic` shell.
2. Provision the `kops` backend (config S3 bucket, cluster DNS zone, and SSH keypair to access the k8s masters and nodes) in Terraform.
3. Build the cluster from the manifest file using the `kops` command.

Let's get started...

### Step 1 - Configuration

Tune the cluster settings by adding them to the `conf/kops/.envrc` file. Make sure you commit this file. 

Here's an example of what that might look like:

```docker
# kops config
ENV BASTION_MACHINE_TYPE="t2.medium"
ENV MASTER_MACHINE_TYPE="t2.medium"
ENV NODE_MACHINE_TYPE="t2.medium"
ENV NODE_MAX_SIZE="2"
ENV NODE_MIN_SIZE="2"
```

After saving those changes, rebuild the Docker image:

```bash
make docker/build
```

### Step 2 - Provision AWS Dependencies

Kops depends on a number of AWS resources that cannot be provisioned by `kops` itself. For this reason, we use `terraform` to provision those resources.


Run the `geodesic` shell again and assume role to login to AWS:

```bash
${image_name}
assume-role
```

Change directory to `kops` folder:

```bash
cd /conf/kops
```

Run Terraform to provision the `kops` backend (S3 bucket, DNS zone, and SSH keypair):

```bash
make apply
```

At this point, `terraform` has written all the essential settings to the `kops` service namespace in SSM parameter store. This way they can be consumed by `chamber`.

### Step 3 - Provision the Cluster

Now we will deploy the actual cluster. This assumes you're still in the shell and have run `assume-role`.

```bash
# Change directory to the kops project folder
cd /conf/kops
# Start a shell with all the envs exported from chamber
make kops/shell
# Build the kops manifest file
make kops/build-manifest
```

You will see the `kops` manifest file `manifest.yaml` has been generated. Inspect the manifest to ensure everything looks good.

Then run this command to write the state to the S3 state storage bucket. This won't actually bring up the cluster. 

```bash
make kops/create
```

Run the following command to provision the AWS resources for the cluster:

```bash
kops update cluster --yes
```

**NOTE** You can omit the `--yes` argument to get a plan of the changes that will be made.

All done. The `kops` cluster is now up and running.

To use the `kubectl` command (_e.g._ `kubectl get nodes`, `kubectl get pods`), you need to export the `kubecfg` configuration settings from the cluster.

Run the following command to export `kubecfg` settings needed to connect to the cluster:

```bash
make kops/export
```

**IMPORTANT:** You need to run this command every time you start a new shell and before you work with the cluster (e.g. before running `kubectl`).

See the documentation for [`kubecfg` settings for `kubectl`](https://github.com/kubernetes/kops/blob/master/docs/kubectl.md) for more details.
<br>

Run the following command to validate the cluster:

```bash
kops validate cluster
```

<details><summary>Show Output</summary>

Below is an example of what it should _roughly_ look like (IPs and Availability Zones may differ).

```
✓   (${namespace}-${stage}-admin) kops ⨠  kops validate cluster
Validating cluster ${aws_region}.${image_name}

INSTANCE GROUPS
NAME			ROLE	MACHINETYPE	MIN	MAX	SUBNETS
bastions		Bastion	t2.medium	1	1	utility-${aws_region}a,utility-${aws_region}d,utility-${aws_region}c
master-${aws_region}a	Master	t2.medium	1	1	${aws_region}a
master-${aws_region}c	Master	t2.medium	1	1	${aws_region}c
master-${aws_region}d	Master	t2.medium	1	1	${aws_region}d
nodes			Node	t2.medium	2	2	${aws_region}a,${aws_region}d,${aws_region}c

NODE STATUS
NAME							ROLE	READY
ip-172-20-108-58.${aws_region}.compute.internal	node	True
ip-172-20-125-166.${aws_region}.compute.internal	master	True
ip-172-20-62-206.${aws_region}.compute.internal	master	True
ip-172-20-74-158.${aws_region}.compute.internal	master	True
ip-172-20-88-143.${aws_region}.compute.internal	node	True

Your cluster ${aws_region}.${image_name} is ready
```

</details>
<br>

Run the following command to list all nodes:

```bash
kubectl get nodes
```

<details><summary>Show Output</summary>

Below is an example of what it should _roughly_ look like (IPs and Availability Zones may differ).

```
✓   (${namespace}-${stage}-admin) kops ⨠  kubectl get nodes
NAME                                                STATUS   ROLES    AGE   VERSION
ip-172-20-108-58.${aws_region}.compute.internal    Ready    node     15m   v1.10.8
ip-172-20-125-166.${aws_region}.compute.internal   Ready    master   17m   v1.10.8
ip-172-20-62-206.${aws_region}.compute.internal    Ready    master   18m   v1.10.8
ip-172-20-74-158.${aws_region}.compute.internal    Ready    master   17m   v1.10.8
ip-172-20-88-143.${aws_region}.compute.internal    Ready    node     16m   v1.10.8
```

</details>
<br>

Run the following command to list all pods:

```bash
kubectl get pods --all-namespaces
```

<details><summary>Show Output</summary>

Below is an example of what it should _roughly_ look like (IPs and Availability Zones may differ).

```
✓   (${namespace}-${stage}-admin) backing-services ⨠  kubectl get pods --all-namespaces
NAMESPACE     NAME                                                                        READY   STATUS    RESTARTS   AGE
kube-system   calico-kube-controllers-69c6bdf999-7sfdg                                    1/1     Running   0          1h
kube-system   calico-node-4qlj2                                                           2/2     Running   0          1h
kube-system   calico-node-668x9                                                           2/2     Running   0          1h
kube-system   calico-node-jddc9                                                           2/2     Running   0          1h
kube-system   calico-node-pszd8                                                           2/2     Running   0          1h
kube-system   calico-node-rqfbk                                                           2/2     Running   0          1h
kube-system   dns-controller-75b75f6f5d-tdg9s                                             1/1     Running   0          1h
kube-system   etcd-server-events-ip-172-20-125-166.${aws_region}.compute.internal        1/1     Running   0          1h
kube-system   etcd-server-events-ip-172-20-62-206.${aws_region}.compute.internal         1/1     Running   2          1h
kube-system   etcd-server-events-ip-172-20-74-158.${aws_region}.compute.internal         1/1     Running   0          1h
kube-system   etcd-server-ip-172-20-125-166.${aws_region}.compute.internal               1/1     Running   0          1h
kube-system   etcd-server-ip-172-20-62-206.${aws_region}.compute.internal                1/1     Running   2          1h
kube-system   etcd-server-ip-172-20-74-158.${aws_region}.compute.internal                1/1     Running   0          1h
kube-system   kube-apiserver-ip-172-20-125-166.${aws_region}.compute.internal            1/1     Running   0          1h
kube-system   kube-apiserver-ip-172-20-62-206.${aws_region}.compute.internal             1/1     Running   3          1h
kube-system   kube-apiserver-ip-172-20-74-158.${aws_region}.compute.internal             1/1     Running   0          1h
kube-system   kube-controller-manager-ip-172-20-125-166.${aws_region}.compute.internal   1/1     Running   0          1h
kube-system   kube-controller-manager-ip-172-20-62-206.${aws_region}.compute.internal    1/1     Running   0          1h
kube-system   kube-controller-manager-ip-172-20-74-158.${aws_region}.compute.internal    1/1     Running   0          1h
kube-system   kube-dns-5fbcb4d67b-kp2pp                                                   3/3     Running   0          1h
kube-system   kube-dns-5fbcb4d67b-wg6gv                                                   3/3     Running   0          1h
kube-system   kube-dns-autoscaler-6874c546dd-tvbhq                                        1/1     Running   0          1h
kube-system   kube-proxy-ip-172-20-108-58.${aws_region}.compute.internal                 1/1     Running   0          1h
kube-system   kube-proxy-ip-172-20-125-166.${aws_region}.compute.internal                1/1     Running   0          1h
kube-system   kube-proxy-ip-172-20-62-206.${aws_region}.compute.internal                 1/1     Running   0          1h
kube-system   kube-proxy-ip-172-20-74-158.${aws_region}.compute.internal                 1/1     Running   0          1h
kube-system   kube-proxy-ip-172-20-88-143.${aws_region}.compute.internal                 1/1     Running   0          1h
kube-system   kube-scheduler-ip-172-20-125-166.${aws_region}.compute.internal            1/1     Running   0          1h
kube-system   kube-scheduler-ip-172-20-62-206.${aws_region}.compute.internal             1/1     Running   0          1h
kube-system   kube-scheduler-ip-172-20-74-158.${aws_region}.compute.internal             1/1     Running   0          1h
```

</details>
<br>
<br>

To upgrade the cluster or change settings (_e.g_. number of nodes, instance types, Kubernetes version, etc.):

1. Modify the `kops` settings in the [`Dockerfile`](Dockerfile)
2. Rebuild Docker image (`make docker/build`)
3. Run `geodesic` shell (`${image_name}`), assume role (`assume-role`) and change directory to `/conf/kops` folder
4. Run `kops export kubecfg`
5. Run `kops replace -f manifest.yaml` to replace the cluster resources (update state)
6. Run `kops update cluster`
7. Run `kops update cluster --yes`
8. Run `kops rolling-update cluster`
9. Run `kops rolling-update cluster --yes --force` to force a rolling update (replace EC2 instances)
   <br>


## References

- https://docs.cloudposse.com
- https://github.com/segmentio/chamber
- https://github.com/kubernetes/kops
- https://github.com/kubernetes-incubator/external-dns/blob/master/docs/faq.md
- https://github.com/gravitational/workshop/blob/master/k8sprod.md

## Getting Help

Did you get stuck? Find us on [slack](https://slack.cloudposse.com) in the `#geodesic` channel.
