FROM jenkins/jenkins:lts

# Switch to root to install packages
USER root

# Install dependencies for Terraform and AWS CLI
RUN apt-get update && apt-get install -y curl unzip groff less \
    && rm -rf /var/lib/apt/lists/*

# Install Terraform
ENV TF_VERSION=1.5.3
RUN curl -fsSL https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip -o terraform.zip \
    && unzip terraform.zip \
    && mv terraform /usr/local/bin/ \
    && rm terraform.zip

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip.sha256" -o "awscliv2.zip.sha256" \
    && sha256sum -c awscliv2.zip.sha256 \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip aws awscliv2.zip.sha256

# Ensure proper permissions for Jenkins user
RUN chown jenkins:jenkins /usr/local/bin/terraform /usr/local/bin/aws

# Return to Jenkins user
USER jenkins
