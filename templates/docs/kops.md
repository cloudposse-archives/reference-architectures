- [Configuration Settings](#configuration-settings)
- [Provision a Kops Cluster](#provision-a-kops-cluster)
- [Populate `chamber` Secrets](#populate-chamber-secrets)
- [Provision `vpc` from `backing-services` with Terraform](#provision-vpc-from-backing-services-with-terraform)
- [Provision `vpc-peering` from `kops-aws-platform` with Terraform](#provision-vpc-peering-from-kops-aws-platform-with-terraform)
- [Provision the rest of `kops-aws-platform` with Terraform](#provision-the-rest-of-kops-aws-platform-with-terraform)
- [Provision the rest of `backing-services` with Terraform](#provision-the-rest-of-backing-services-with-terraform)
- [Provision Kubernetes Resources](#provision-kubernetes-resources)
  - [Deploy heapster](#deploy-heapster)
  - [Deploy kubernetes-dashboard](#deploy-kubernetes-dashboard)
  - [Deploy kiam](#deploy-kiam)
  - [Deploy external-dns](#deploy-external-dns)
  - [Deploy kube-lego](#deploy-kube-lego)
  - [Deploy prometheus-operator](#deploy-prometheus-operator)
  - [Deploy kube-prometheus](#deploy-kube-prometheus)
  - [Deploy nginx-ingress](#deploy-nginx-ingress)
  - [Deploy fluentd-elasticsearch-logs](#deploy-fluentd-elasticsearch-logs)
  - [Deploy portal](#deploy-portal)
- [Check Cluster Health](#check-cluster-health)
- [References](#references)

## Configuration Settings

Most configuration settings are defined as environment variables. These can be set using the `ENV` declaration in the [`Dockerfile`](Dockerfile). These have been set to _sane defaults_ and shouldn't need to be touched. All these settings are required.

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

## Provision a Kops Cluster

We create a [`kops`](https://github.com/kubernetes/kops) cluster from a manifest.

The manifest template is located in [`/templates/kops/default.yaml`](https://github.com/cloudposse/geodesic/blob/master/rootfs/templates/kops/default.yaml)
and is compiled by running `build-kops-manifest` in the [`Dockerfile`](Dockerfile).

Provisioning a `kops` cluster takes three steps:

1. Provision the `kops` backend (config S3 bucket, cluster DNS zone, and SSH keypair to access the k8s masters and nodes) in Terraform
2. Update the [`Dockerfile`](Dockerfile) and rebuild/restart the `geodesic` shell to generate a `kops` manifest file
3. Execute the `kops` manifest file to create the `kops` cluster

Run Terraform to provision the `kops` backend (S3 bucket, DNS zone, and SSH keypair):

```bash
make -C /conf/kops init apply
```

From the Terraform outputs, copy the `zone_name` and `bucket_name` into the ENV vars `KOPS_CLUSTER_NAME` and `KOPS_STATE_STORE` in the [`Dockerfile`](Dockerfile).

The `Dockerfile` `kops` config should look like this:

```docker
# kops config
ENV KOPS_CLUSTER_NAME="${aws_region}.${image_name}"
ENV KOPS_DNS_ZONE=${KOPS_CLUSTER_NAME}
ENV KOPS_STATE_STORE="s3://${namepsace}-${stage}-kops-state"
ENV KOPS_STATE_STORE_REGION="${aws_region}"
ENV KOPS_AVAILABILITY_ZONES="${aws_region}a,${aws_region}d,${aws_region}c"
ENV KOPS_BASTION_PUBLIC_NAME="bastion"
ENV BASTION_MACHINE_TYPE="t2.medium"
ENV MASTER_MACHINE_TYPE="t2.medium"
ENV NODE_MACHINE_TYPE="t2.medium"
ENV NODE_MAX_SIZE="2"
ENV NODE_MIN_SIZE="2"
```

Type `exit` (or hit ^D) to leave the shell.

Note, if you've assumed a role, you'll first need to leave that also by typing `exit` (or hit ^D).

Rebuild the Docker image:

```bash
make docker/build
```

Run the `geodesic` shell again and assume role to login to AWS:

```bash
${image_name}
assume-role
```

Change directory to `kops` folder:

```bash
cd /conf/kops
```

You will see the `kops` manifest file `manifest.yaml` generated.

Run the following command to create the cluster. This will just initialize the cluster state and store it in the S3 bucket, but not actually provision any AWS resources for the cluster.

```bash
kops create -f manifest.yaml
```

Run the following command to add the SSH public key to the cluster:

```bash
kops create secret sshpublickey admin -i /secrets/tf/ssh/${namepsace}-${stage}-kops-${aws_region}.pub --name $KOPS_CLUSTER_NAME
```

Run the following command to provision the AWS resources for the cluster:

```bash
kops update cluster --yes
```

All done. The `kops` cluster is now up and running.

To use the `kubectl` command (_e.g._ `kubectl get nodes`, `kubectl get pods`), you need to export the `kubecfg` configuration settings from the cluster.

Run the following command to export `kubecfg` settings needed to connect to the cluster:

```bash
kops export kubecfg
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
✓   (${namepsace}-${stage}-admin) kops ⨠  kops validate cluster
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
✓   (${namepsace}-${stage}-admin) kops ⨠  kubectl get nodes
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
✓   (${namepsace}-${stage}-admin) backing-services ⨠  kubectl get pods --all-namespaces
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

## Populate `chamber` Secrets

**NOTE:** We use `chamber` to first populate the environment with the secrets from the specified service (`backing-services`, `kops`)
and then execute the given commands (`terraform plan` or `terraform apply`).
You need to do it only once for a given set of secrets. Repeat this step if you want to add new secrets.

Populate `chamber` secrets for `kops` project (make sure to change the keys and values to reflect your environment; add new secrets as needed)

```bash
chamber write kops <key1> <value1>
chamber write kops <key2> <value2>
...
```

**NOTE:** Run `chamber list -e kops` to list the secrets stored for `kops` project

Populate `chamber` secrets for `backing-services` project (make sure to change the values to reflect your environment; add new secrets as needed)

```bash
chamber write backing-services TF_VAR_POSTGRES_DB_NAME ${namepsace}_${stage}
chamber write backing-services TF_VAR_POSTGRES_ADMIN_NAME ${namepsace}_admin
chamber write backing-services TF_VAR_POSTGRES_ADMIN_PASSWORD XXXXXXXXXXXX
```

**NOTE:** Run `chamber list -e backing-services` to list the secrets stored for `backing-services` project
<br/>

## Provision `vpc` from `backing-services` with Terraform

**NOTE:** We provision `backing-services` in two phases because:

- `aurora-postgres` and other backing services depend on `vpc-peering` (they use `kops` Security Group to allow `kops` applications to connect)
- `vpc-peering` depends on `vpc` and `kops` (it creates a peering connection between the two networks)

To break the circular dependencies, we provision `kops`, then `vpc` (from `backing-services`), then `vpc-peering`,
and finally the rest of `backing-services` (`aurora-postgres` and other services).

Provision `vpc` for `backing-services`:

```bash
cd /conf/backing-services
init-terraform
terraform plan -target=data.aws_availability_zones.available -target=module.vpc -target=module.subnets
terraform apply -target=data.aws_availability_zones.available -target=module.vpc -target=module.subnets
```

## Provision `vpc-peering` from `kops-aws-platform` with Terraform

```bash
cd /conf/kops-aws-platform
init-terraform
terraform plan -target=data.aws_vpc.backing_services_vpc -target=module.kops_vpc_peering
terraform apply -target=data.aws_vpc.backing_services_vpc -target=module.kops_vpc_peering
```

You should see the following output:

<details><summary>Show Output</summary>

```
Apply complete! Resources: 10 added, 0 changed, 0 destroyed.
Releasing state lock. This may take a few moments...

Outputs:

kops_vpc_peering_accept_status = active
kops_vpc_peering_connection_id = pcx-014d91a03f56e3170
```

</details>
<br>

## Provision the rest of `kops-aws-platform` with Terraform

```bash
cd /conf/kops-aws-platform
terraform plan
terraform apply
```

You should see the following output:

<details><summary>Show Output</summary>

```
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
Releasing state lock. This may take a few moments...

Outputs:

kops_external_dns_policy_arn = arn:aws:iam::xxxxxxxx:policy/${namepsace}-${stage}-external-dns
kops_external_dns_policy_id = arn:aws:iam::xxxxxxxx:policy/${namepsace}-${stage}-external-dns
kops_external_dns_policy_name = ${namepsace}-${stage}-external-dns
kops_external_dns_role_arn = arn:aws:iam::xxxxxxxx:role/${namepsace}-${stage}-external-dns
kops_external_dns_role_name = ${namepsace}-${stage}-external-dns
kops_external_dns_role_unique_id = XXXXXXXXXXXXXXXX
```

</details>
<br>

## Provision the rest of `backing-services` with Terraform

**NOTE:** Make sure you have populated the `chamber` secrets for `backing-services` (see Populate `chamber` secrets above) :

```bash
chamber write backing-services TF_VAR_POSTGRES_DB_NAME ${namepsace}_${stage}
chamber write backing-services TF_VAR_POSTGRES_ADMIN_NAME ${namepsace}_admin
chamber write backing-services TF_VAR_POSTGRES_ADMIN_PASSWORD XXXXXXXXXXXXXXXX
```

Provision `aurora-postgres` and `elasticsearch`:

```bash
cd /conf/backing-services
chamber exec backing-services -- terraform plan
chamber exec backing-services -- terraform apply
```

You should see the following output:

<details><summary>Show Output</summary>

```
aurora_postgres_cluster_name = ${namepsace}-${stage}-postgres
aurora_postgres_database_name = ${namepsace}_${stage}
aurora_postgres_master_hostname = master.postgres.${image_name}
aurora_postgres_master_username = ${namepsace}_admin
aurora_postgres_replicas_hostname = replicas.postgres.${image_name}
elasticsearch_domain_arn = arn:aws:es:${aws_region}:091456519406:domain/${namepsace}-${stage}-elasticsearch
elasticsearch_domain_endpoint = vpc-${namepsace}-${stage}-elasticsearch-35lgg7m52qybtqf3cftblowblm.${aws_region}.es.amazonaws.com
elasticsearch_domain_hostname = elasticsearch.${image_name}
elasticsearch_domain_id = 091456519406/${namepsace}-${stage}-elasticsearch
elasticsearch_kibana_endpoint = vpc-${namepsace}-${stage}-elasticsearch-35lgg7m52qybtqf3cftblowblm.${aws_region}.es.amazonaws.com/_plugin/kibana/
elasticsearch_kibana_hostname = kibana-elasticsearch.${image_name}
elasticsearch_security_group_id = sg-0cc1155c8bd45a6c2
```

</details>
<br>

## Provision Kubernetes Resources

**NOTE:** We use [helmfile](https://github.com/roboll/helmfile) to deploy [Helm](https://helm.sh/) [charts](https://github.com/kubernetes/charts) to provision Kubernetes resources.
We use `chamber` to first populate the environment with the secrets from the `kops` chamber service and then execute commands (_e.g._ `helmfile sync`)

**NOTE:** Make sure to export Kubernetes config by executing `kops export kubecfg`

Run `helm init` to initialize `helm` and `tiller`:

<details><summary>Show Output</summary>

```
✓   (${namepsace}-${stage}-admin) ⨠  helm init
$HELM_HOME has been configured at /var/lib/helm.

Tiller (the Helm server-side component) has been installed into your Kubernetes Cluster.

Please note: by default, Tiller is deployed with an insecure 'allow unauthenticated users' policy.
To prevent this, run `helm init` with the --tiller-tls-verify flag.
For more information on securing your installation see: https://docs.helm.sh/using_helm/#securing-your-helm-installation
Happy Helming!
```

</details>
<br>

### Deploy heapster

```bash
cd /conf
chamber exec kops -- helmfile --selector namespace=kube-system,chart=heapster sync
```

<details><summary>Show Output</summary>

```
✓   (${namepsace}-${stage}-admin) ⨠  chamber exec kops -- helmfile --selector namespace=kube-system,chart=heapster sync
Adding repo stable https://kubernetes-charts.storage.googleapis.com
"stable" has been added to your repositories

Updating repo
Hang tight while we grab the latest from your chart repositories...
...Skip local chart repository
...Successfully got an update from the "incubator" chart repository
...Successfully got an update from the "cloudposse-incubator" chart repository
...Successfully got an update from the "coreos-stable" chart repository
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈ Happy Helming!⎈

Upgrading stable/heapster
Release "heapster" does not exist. Installing it now.
NAME:   heapster
LAST DEPLOYED: Fri Nov 30 17:58:10 2018
NAMESPACE: kube-system
STATUS: DEPLOYED

RESOURCES:
==> v1/Service
NAME      AGE
heapster  3s

==> v1beta1/Deployment
heapster-heapster  3s

==> v1/Pod(related)

NAME                                READY  STATUS             RESTARTS  AGE
heapster-heapster-68d4c66f4c-b6j85  0/2    ContainerCreating  0         3s
```

</details>
<br>

### Deploy kubernetes-dashboard

```bash
chamber exec kops -- helmfile --selector namespace=kube-system,chart=kubernetes-dashboard sync
```

### Deploy kiam

```bash
cd /conf/scripts/kiam
make all
make chamber/write/agent
make chamber/write/server
make annotate
cd /conf
chamber exec kops -- helmfile --selector namespace=kube-system,chart=kiam sync
```

### Deploy external-dns

```bash
chamber write kops EXTERNAL_DNS_TXT_OWNER_ID ${aws_region}.${image_name}
chamber write kops EXTERNAL_DNS_TXT_PREFIX 27ba410b-1809-491b-bc06-8f2b7f703209-
chamber write kops EXTERNAL_DNS_IAM_ROLE ${namepsace}-${stage}-external-dns
chamber exec kops -- helmfile --selector namespace=kube-system,chart=external-dns sync
```

### Deploy kube-lego

```bash
chamber write kops KUBE_LEGO_EMAIL ops@${domain_name}
chamber write kops KUBE_LEGO_PROD true
chamber exec kops -- helmfile --selector namespace=kube-system,chart=kube-lego sync
```

### Deploy prometheus-operator

```bash
chamber exec kops -- helmfile --selector namespace=kube-system,chart=prometheus-operator sync
```

### Deploy kube-prometheus

**NOTE:** Update `KUBE_PROMETHEUS_ALERT_MANAGER_SLACK_WEBHOOK_URL` and `KUBE_PROMETHEUS_ALERT_MANAGER_SLACK_CHANNEL` to the values specific to the current project.

```bash
chamber write kops KUBE_PROMETHEUS_ALERT_MANAGER_SLACK_WEBHOOK_URL https://xxxxxxxxxx.xxx
chamber write kops KUBE_PROMETHEUS_ALERT_MANAGER_SLACK_CHANNEL test
chamber write kops KUBE_PROMETHEUS_ALERT_MANAGER_HOSTNAME alerts.${aws_region}.${image_name}
chamber write kops KUBE_PROMETHEUS_ALERT_MANAGER_INGRESS ingress.${aws_region}.${image_name}
chamber write kops KUBE_PROMETHEUS_ALERT_MANAGER_SECRET_NAME alertmanager-general-tls
chamber write kops KUBE_PROMETHEUS_HOSTNAME prometheus.${aws_region}.${image_name}
chamber write kops KUBE_PROMETHEUS_INGRESS ingress.${aws_region}.${image_name}
chamber write kops KUBE_PROMETHEUS_SECRET_NAME prometheus-general-tls
chamber write kops KUBE_PROMETHEUS_EXTERNAL_VALUES_FILE "./values/kube-prometheus.grafana.dashboards.yaml"
chamber exec kops -- helmfile --selector namespace=monitoring,chart=kube-prometheus --selector namespace=monitoring,chart=kube-prometheus-grafana sync
```

### Deploy nginx-ingress

```bash
chamber write kops NGINX_INGRESS_HOSTNAME ingress.${aws_region}.${image_name}
chamber exec kops -- helmfile --selector namespace=kube-system,chart=nginx-ingress sync
```

### Deploy fluentd-elasticsearch-logs

```bash
chamber write kops ELASTICSEARCH_HOST vpc-${namepsace}-${stage}-elasticsearch-45lgg4m52qybkqz3cftbxowbxm.${aws_region}.es.amazonaws.com
chamber write kops ELASTICSEARCH_PORT 443
chamber write kops ELASTICSEARCH_SCHEME "https"
chamber exec kops -- helmfile --selector namespace=kube-system,name=fluentd-elasticsearch-logs sync
```

### Deploy portal

```bash
chamber write kops PORTAL_TITLE "($stage)"
chamber write kops PORTAL_BRAND "NOC"
chamber write kops PORTAL_HOSTNAME portal.${aws_region}.${image_name}
chamber write kops PORTAL_BRAND_IMAGE_FAVICON_URL "https://cloudposse.com/wp-content/uploads/sites/29/2016/04/favicon-152.png"
chamber write kops PORTAL_BRAND_IMAGE_URL "https://avatars3.githubusercontent.com/u/10550344?s=200&v=4"
chamber write kops PORTAL_BRAND_IMAGE_WIDTH 35
chamber write kops PORTAL_INGRESS_TLS_ENABLED true
chamber write kops PORTAL_INGRESS ingress.${aws_region}.${image_name}
chamber write kops PORTAL_COOKIE_DOMAIN .${aws_region}.${image_name}
chamber write kops PORTAL_OAUTH2_PROXY_COOKIE_NAME 333044c9-ff9a-4e4e-97ed-3cc0ec237ab3
chamber write kops PORTAL_OAUTH2_PROXY_COOKIE_SECRET 34ac6b86-7df5-493b-ad2e-e1c1feb48cf3
chamber write kops PORTAL_OAUTH2_PROXY_GITHUB_ORGANIZATION xxxxxxxx
chamber write kops PORTAL_OAUTH2_PROXY_GITHUB_TEAM li
chamber write kops PORTAL_OAUTH2_PROXY_CLIENT_ID xxxxxxxxxxxxxxxxxx
chamber write kops PORTAL_OAUTH2_PROXY_CLIENT_SECRET xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
chamber write kops PORTAL_OAUTH2_PROXY_REDIRECT_URL https://portal.${aws_region}.${image_name}/oauth2/callback
chamber write kops PORTAL_BACKEND_KIBANA_EXTERNAL_NAME vpc-${namepsace}-${stage}-elasticsearch-35lgg7m52qybtqf3cftblowblm.${aws_region}.es.amazonaws.com
chamber write kops PORTAL_BACKEND_KIBANA_ENABLED true
chamber exec kops -- helmfile --selector namespace=monitoring,chart=portal sync
```

## Check Cluster Health

To confirm that all `helm` releases are deployed and running, run the following command:

```bash
helm list -a
```

<details><summary>Show Output</summary>

Below is an example of what it should _roughly_ look like (IPs and Availability Zones may differ).

```
✓   (${namepsace}-${stage}-admin) ⨠  helm list -a
NAME                      	REVISION	UPDATED                 	STATUS  	CHART                      	APP VERSION	NAMESPACE
dns                       	1       	Fri Nov 30 19:15:23 2018	DEPLOYED	external-dns-0.5.4         	0.4.8      	kube-system
fluentd-elasticsearch-logs	1       	Mon Dec  3 19:37:57 2018	DEPLOYED	fluentd-kubernetes-0.3.0   	0.12       	kube-system
heapster                  	2       	Mon Dec  3 15:38:29 2018	DEPLOYED	heapster-0.2.10            	1.3.0      	kube-system
ingress                   	2       	Sat Dec  1 06:05:15 2018	DEPLOYED	nginx-ingress-0.25.1       	0.17.1     	kube-system
ingress-backend           	2       	Sat Dec  1 06:05:14 2018	DEPLOYED	nginx-default-backend-0.2.2	           	kube-system
ingress-monitoring        	2       	Sat Dec  1 06:05:15 2018	DEPLOYED	monochart-0.4.0            	0.4.0      	monitoring
kiam                      	2       	Sat Dec  1 04:04:31 2018	DEPLOYED	kiam-2.0.0-rc1             	3.0-rc1    	kube-system
kube-prometheus           	1       	Mon Dec  3 19:06:53 2018	DEPLOYED	kube-prometheus-0.0.105    	           	monitoring
kube-prometheus-grafana   	1       	Mon Dec  3 18:49:39 2018	DEPLOYED	monochart-0.4.0            	0.4.0      	monitoring
kubernetes-dashboard      	1       	Fri Nov 30 18:27:09 2018	DEPLOYED	kubernetes-dashboard-0.6.7 	1.8.3      	kube-system
portal                    	3       	Mon Dec  3 17:57:49 2018	DEPLOYED	portal-0.2.4               	           	monitoring
prometheus-operator       	1       	Fri Nov 30 18:43:55 2018	DEPLOYED	prometheus-operator-0.0.29 	0.20.0     	kube-system
tls                       	2       	Sat Dec  1 05:10:12 2018	DEPLOYED	kube-lego-0.1.2            	           	kube-system
```

</details>
<br>

To check the status of all Kubernetes pods, run the following command:

```bash
kubectl get pods --all-namespaces
```

<details><summary>Show Output</summary>

Below is an example of what it should _roughly_ look like (IPs and Availability Zones may differ).

```
✓   (${namepsace}-${stage}-admin) ⨠  kubectl get pods --all-namespaces
NAMESPACE     NAME                                                                        READY   STATUS    RESTARTS   AGE
kube-system   calico-kube-controllers-69c6bdf999-7sfdg                                    1/1     Running   0          3d
kube-system   calico-node-4qlj2                                                           2/2     Running   0          3d
kube-system   calico-node-668x9                                                           2/2     Running   0          3d
kube-system   calico-node-jddc9                                                           2/2     Running   0          3d
kube-system   calico-node-pszd8                                                           2/2     Running   0          3d
kube-system   calico-node-rqfbk                                                           2/2     Running   0          3d
kube-system   dns-controller-75b75f6f5d-tdg9s                                             1/1     Running   0          3d
kube-system   dns-external-dns-67b99686c4-chl8w                                           1/1     Running   0          3d
kube-system   etcd-server-events-ip-172-20-125-166.${aws_region}.compute.internal        1/1     Running   0          3d
kube-system   etcd-server-events-ip-172-20-62-206.${aws_region}.compute.internal         1/1     Running   2          3d
kube-system   etcd-server-events-ip-172-20-74-158.${aws_region}.compute.internal         1/1     Running   0          3d
kube-system   etcd-server-ip-172-20-125-166.${aws_region}.compute.internal               1/1     Running   0          3d
kube-system   etcd-server-ip-172-20-62-206.${aws_region}.compute.internal                1/1     Running   2          3d
kube-system   etcd-server-ip-172-20-74-158.${aws_region}.compute.internal                1/1     Running   0          3d
kube-system   fluentd-elasticsearch-logs-fluentd-kubernetes-24zcq                         1/1     Running   0          21m
kube-system   fluentd-elasticsearch-logs-fluentd-kubernetes-5mjbp                         1/1     Running   0          21m
kube-system   fluentd-elasticsearch-logs-fluentd-kubernetes-7d682                         1/1     Running   0          21m
kube-system   fluentd-elasticsearch-logs-fluentd-kubernetes-lskkt                         1/1     Running   0          21m
kube-system   fluentd-elasticsearch-logs-fluentd-kubernetes-n9ddf                         1/1     Running   0          21m
kube-system   heapster-heapster-59b674774c-8c689                                          2/2     Running   0          3d
kube-system   ingress-backend-default-6f987d4648-bk4kh                                    1/1     Running   0          2d
kube-system   ingress-backend-default-6f987d4648-j8frw                                    1/1     Running   0          2d
kube-system   ingress-nginx-ingress-controller-659759dc98-c8w7z                           1/1     Running   0          2d
kube-system   ingress-nginx-ingress-controller-659759dc98-f9xsr                           1/1     Running   0          2d
kube-system   ingress-nginx-ingress-controller-659759dc98-rp6jv                           1/1     Running   0          2d
kube-system   ingress-nginx-ingress-controller-659759dc98-zl872                           1/1     Running   0          2d
kube-system   kiam-agent-hh4f8                                                            1/1     Running   0          3d
kube-system   kiam-agent-wqqbw                                                            1/1     Running   0          3d
kube-system   kiam-server-ft956                                                           1/1     Running   0          3d
kube-system   kiam-server-mdfds                                                           1/1     Running   0          3d
kube-system   kiam-server-rqp76                                                           1/1     Running   0          3d
kube-system   kube-apiserver-ip-172-20-125-166.${aws_region}.compute.internal            1/1     Running   0          3d
kube-system   kube-apiserver-ip-172-20-62-206.${aws_region}.compute.internal             1/1     Running   3          3d
kube-system   kube-apiserver-ip-172-20-74-158.${aws_region}.compute.internal             1/1     Running   0          3d
kube-system   kube-controller-manager-ip-172-20-125-166.${aws_region}.compute.internal   1/1     Running   0          3d
kube-system   kube-controller-manager-ip-172-20-62-206.${aws_region}.compute.internal    1/1     Running   0          3d
kube-system   kube-controller-manager-ip-172-20-74-158.${aws_region}.compute.internal    1/1     Running   0          3d
kube-system   kube-dns-5fbcb4d67b-kp2pp                                                   3/3     Running   0          3d
kube-system   kube-dns-5fbcb4d67b-wg6gv                                                   3/3     Running   0          3d
kube-system   kube-dns-autoscaler-6874c546dd-tvbhq                                        1/1     Running   0          3d
kube-system   kube-proxy-ip-172-20-108-58.${aws_region}.compute.internal                 1/1     Running   0          3d
kube-system   kube-proxy-ip-172-20-125-166.${aws_region}.compute.internal                1/1     Running   0          3d
kube-system   kube-proxy-ip-172-20-62-206.${aws_region}.compute.internal                 1/1     Running   0          3d
kube-system   kube-proxy-ip-172-20-74-158.${aws_region}.compute.internal                 1/1     Running   0          3d
kube-system   kube-proxy-ip-172-20-88-143.${aws_region}.compute.internal                 1/1     Running   0          3d
kube-system   kube-scheduler-ip-172-20-125-166.${aws_region}.compute.internal            1/1     Running   0          3d
kube-system   kube-scheduler-ip-172-20-62-206.${aws_region}.compute.internal             1/1     Running   0          3d
kube-system   kube-scheduler-ip-172-20-74-158.${aws_region}.compute.internal             1/1     Running   0          3d
kube-system   kubernetes-dashboard-76ddc7694c-twxjn                                       1/1     Running   0          3d
kube-system   prometheus-operator-5f4669c455-dt588                                        1/1     Running   0          1h
kube-system   tiller-deploy-6fd8d857bc-v2q5l                                              1/1     Running   0          3d
kube-system   tls-kube-lego-679f49f8ff-pmxhf                                              1/1     Running   0          2d
monitoring    alertmanager-kube-prometheus-0                                              2/2     Running   0          52m
monitoring    alertmanager-kube-prometheus-1                                              2/2     Running   0          51m
monitoring    alertmanager-kube-prometheus-2                                              2/2     Running   0          51m
monitoring    alertmanager-kube-prometheus-3                                              2/2     Running   0          51m
monitoring    kube-prometheus-exporter-kube-state-7cb68c5b6c-wj4z9                        2/2     Running   0          52m
monitoring    kube-prometheus-exporter-node-4fj5s                                         1/1     Running   0          52m
monitoring    kube-prometheus-exporter-node-fb5p5                                         1/1     Running   0          52m
monitoring    kube-prometheus-exporter-node-gv5jn                                         1/1     Running   0          52m
monitoring    kube-prometheus-exporter-node-xhvqt                                         1/1     Running   0          52m
monitoring    kube-prometheus-exporter-node-xvrsv                                         1/1     Running   0          52m
monitoring    kube-prometheus-grafana-79454f96dc-gmmrd                                    2/2     Running   0          52m
monitoring    portal-oauth2-proxy-8558678f5d-q8wll                                        1/1     Running   0          4h
monitoring    portal-portal-6f8b759d64-v898p                                              1/1     Running   0          2h
monitoring    portal-portal-6f8b759d64-zwp2g                                              1/1     Running   0          2h
monitoring    prometheus-kube-prometheus-0                                                3/3     Running   1          52m
monitoring    prometheus-kube-prometheus-1                                                3/3     Running   1          51m
monitoring    prometheus-kube-prometheus-2                                                0/3     Pending   0          51m
```

</details>
<br>

## References

- https://docs.cloudposse.com
- https://github.com/segmentio/chamber
- https://github.com/kubernetes/kops
- https://github.com/kubernetes-incubator/external-dns/blob/master/docs/faq.md
- https://github.com/gravitational/workshop/blob/master/k8sprod.md
