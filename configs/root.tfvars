# This is a terraform configuration file

# The "apex" service discovery domain for *all* infrastructure
domain = "test.co"

# The global namespace that should be shared by all accounts
namespace = "test"

# The "root" account id
aws_account_id = ""

aws_region = "us-west-2"

docker_registry = "cloudposse"

templates = ["Dockerfile.root", ".gitignore", ".dockerignore", "Makefile", "conf/Makefile"]
