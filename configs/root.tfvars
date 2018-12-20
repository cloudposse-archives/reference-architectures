# This is a terraform configuration file

# The "apex" service discovery domain for *all* infrastructure
domain = "test.co"

# The global namespace that should be shared by all accounts
namespace = "test"

# The default region for this account
aws_region = "us-west-2"

# The docker registry that will be used for the images built (nothing will get pushed)
docker_registry = "cloudposse"

# The templates to use for this account
templates = ["Dockerfile.root", ".gitignore", ".dockerignore", "Makefile", "conf/Makefile"]
