# This is a terraform configuration file

domain      = "test.co"
namespace   = "testing"
stage       = "testing"
aws_account_id = ""
aws_root_account_id = ""
aws_region = "us-west-2"
docker_registry = "cloudposse"
templates   = ["Dockerfile.child", ".gitignore", ".dockerignore", "Makefile", "conf/Makefile"]
