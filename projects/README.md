# Infrastructure Projects

Terraform and Kubernetes projects exist in here.

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
