region="${aws_region}"
zone_name="${domain_name}"
cluster_id="${aws_region}.${domain_name}"
efs_enabled="false"
kops_alb_ingress_enabled="false"
dns_zone_names=["${aws_region}.${domain_name}"]
