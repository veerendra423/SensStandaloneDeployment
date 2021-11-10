FROM ubuntu:18.04

RUN apt-get update 
RUN apt-get update --fix-missing

# Install components required by az cli
RUN apt-get install ca-certificates curl apt-transport-https lsb-release gnupg unzip ssh -y

# Download and install the Microsoft signing key
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

# Add the Azure CLI software repository
RUN AZ_REPO=$(lsb_release -cs) && echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list

# Update repository information and install the azure-cli package
RUN apt-get update && apt-get install azure-cli -y

# Get terraform binary
RUN curl https://releases.hashicorp.com/terraform/0.13.0/terraform_0.13.0_linux_amd64.zip --output /tmp/terraform.zip

# Extract terraform binary
RUN unzip /tmp/terraform.zip -d /usr/local/bin/
RUN chmod +x /usr/local/bin/terraform

# Add project
RUN mkdir -p /app
# WORKDIR /app
# COPY . /app

# ENTRYPOINT ["bash","/app/run"]
