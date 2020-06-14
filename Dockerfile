FROM cloudposse/geodesic:0.132.1

# Geodesic message of the Day
ENV MOTD_URL="https://geodesic.sh/motd"

# Some configuration options for Geodesic
ENV AWS_SAML2AWS_ENABLED=true
ENV AWS_VAULT_ENABLED=false
ENV GEODESIC_TERRAFORM_WORKSPACE_PROMPT_ENABLED=true
ENV DIRENV_ENABLED=false

ENV DOCKER_IMAGE="cloudposse/reference-architectures"
ENV DOCKER_TAG="latest"
ENV NAMESPACE="eg"

# Geodesic banner message
ENV BANNER="sweet ops"

# Pin kubectl to version 1.15
RUN apk add kubectl-1.15@cloudposse

# Install terraform
RUN apk add terraform@cloudposse

# Install helmfile
RUN apk add helmfile@cloudposse

# Install saml2aws
# https://github.com/Versent/saml2aws#linux
RUN apk add saml2aws@cloudposse

# Install assume-role
RUN apk add assume-role@cloudposse

# Install variant2 overwriting variant
RUN apk add variant2@cloudposse

# Install the "docker" command to interact with the host's Docker daemon
RUN apk add -u docker-cli

# Limit Makefile searches set up by Geodesic
# Allow a single Makefile to serve all child directories
ENV MAKE_INCLUDES="Makefile.settings ../Makefile.parent Makefile"

COPY rootfs/ /

COPY projects/ /projects/

WORKDIR /projects/
