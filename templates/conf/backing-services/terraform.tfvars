vpc_cidr_block = "${backing_services_cidr}"
zone_name = "${domain_name}"
region = "${aws_region}"
postgres_cluster_enabled = "false"
kops_metadata_enabled = "false"
rds_cluster_replica_enabled = "false"
rds_cluster_replica_cluster_identifier = "${namespace}-${stage}-postgres"

