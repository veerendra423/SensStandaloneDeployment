provider "azurerm" {
  version = "=2.21.0"
  features {}
}

resource "azurerm_resource_group" "sens_controller" {
  name     = "${var.controller_azurerm_resource_group}-${var.TFUSER}"
  location = var.location
}

resource "tls_private_key" "sens_controller_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}

output "tls_private_key" { value = "${tls_private_key.sens_controller_ssh.private_key_pem}" }



resource "azurerm_public_ip" "sens_controller" {
  name                    = "sens-controller-ip-addr-${var.TFUSER}"
  location                = var.location
  resource_group_name     = azurerm_resource_group.sens_controller.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30

  tags = {
    environment = "test"
  }
}

resource "azurerm_virtual_network" "main" {
  name                = "sens-network-${var.TFUSER}"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.sens_controller.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.sens_controller.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "main" {
  name                = "sens-nic-${var.TFUSER}"
  resource_group_name = azurerm_resource_group.sens_controller.name
  location            = var.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.sens_controller.id
  }
}

resource "azurerm_storage_account" "internal" {
  name                     = "${var.USERNAME}internal"
  resource_group_name      = azurerm_resource_group.sens_controller.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "staging"
  }
}

resource "azurerm_storage_container" "internalbucket" {
  name                  = "${var.USERNAME}-internal-storage"
  storage_account_name  = azurerm_storage_account.internal.name
  container_access_type = "private"
}

resource "azurerm_storage_account" "inputdata" {
  name                     = "${var.USERNAME}inputdata"
  resource_group_name      = azurerm_resource_group.sens_controller.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "staging"
  }
}
resource "azurerm_storage_container" "inputdatabucket" {
  name                  = "${var.USERNAME}-inputdata-storage"
  storage_account_name  = azurerm_storage_account.inputdata.name
  container_access_type = "private"
}

locals {
  custom_data = <<CUSTOM_DATA
#!/bin/bash
apt update
apt install make gcc apt-transport-https ca-certificates curl jq software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg |  apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt update
apt-cache policy docker-ce
apt install docker-ce python3 python3-pip -y
curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-Linux-x86_64" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker login -u ${var.docker_user} -p ${var.docker_pwd} ${var.docker_registry}
groupadd docker
usermod -aG docker ${var.USERNAME}
#To install the kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(<kubectl.sha256) kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
#To install the node and npm
sudo apt install npm -y
sudo apt install nodejs
sudo apt-get -y install python3-pip
sudo apt-get update
pip3 install html-testRunner
pip3 install pexpect
pip3 install pytz
#To install the az
sudo apt-get update
sudo apt-get install ca-certificates curl apt-transport-https lsb-release gnupg
curl -sL https://packages.microsoft.com/keys/microsoft.asc |     gpg --dearmor |     sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" |     sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-get update
sudo apt-get install azure-cli
#To install the kubectl helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh -v v3.6.3
sleep 50

sudo mkdir /mnt/staging
if [ ! -d "/etc/smbcredentials" ]; then
sudo mkdir /etc/smbcredentials
fi
if [ ! -f "/etc/smbcredentials/sensreleaseartifacts.cred" ]; then
    sudo bash -c 'echo "username=sensreleaseartifacts" >> /etc/smbcredentials/sensreleaseartifacts.cred'
    sudo bash -c 'echo "password=sfRdw1jCI7hp5tUfqf05nSlYKa943bdfrQkBM+XvMJ8QIgOsY3W+QJSOAxA+m3GCEk/h0i4i+bEAk7UwvzFGKg==" >> /etc/smbcredentials/sensreleaseartifacts.cred'
fi
sudo chmod 600 /etc/smbcredentials/sensreleaseartifacts.cred

sudo bash -c 'echo "//sensreleaseartifacts.file.core.windows.net/staging /mnt/staging cifs nofail,vers=3.0,credentials=/etc/smbcredentials/sensreleaseartifacts.cred,dir_mode=0777,file_mode=0777,serverino" >> /etc/fstab'
sudo mount -t cifs //sensreleaseartifacts.file.core.windows.net/staging /mnt/staging -o rw,username=sensreleaseartifacts,password=sfRdw1jCI7hp5tUfqf05nSlYKa943bdfrQkBM+XvMJ8QIgOsY3W+QJSOAxA+m3GCEk/h0i4i+bEAk7UwvzFGKg==

#To clone the code
cd /home/${var.USERNAME}/
git_token=`cat /mnt/staging/github-creds`

#it checks the version number value.It is null or not.
#if [ -z "${var.product_version}" ]
#then
      git clone https://$git_token@github.com/sensoriant/SensKubeDeploy.git
      git clone https://$git_token@github.com/sensoriant/Safectl.git
#else
#      git clone -b ${var.SENSKUBEDEPLOY_VERSION} https://$git_token@github.com/sensoriant/SensKubeDeploy.git
#      git clone -b ${var.SAFECTL_VERSION} https://$git_token@github.com/sensoriant/Safectl.git
#fi

chown -R ${var.USERNAME}:${var.USERNAME} /home/${var.USERNAME}/SensKubeDeploy
chown -R ${var.USERNAME}:${var.USERNAME} /home/${var.USERNAME}/Safectl

FILE=/home/${var.USERNAME}/SensKubeDeploy/opsutils/restartfix-cron.sh
if test -f "$FILE"; then
    echo "*/5 * * * * ${var.USERNAME} /home/${var.USERNAME}/SensKubeDeploy/opsutils/restartfix-cron.sh" >> /etc/crontab
    echo "Directory /home/${var.USERNAME}/SensKubeDeploy/opsutils/restartfix-cron.sh exists." >> /home/${var.USERNAME}/directory.txt
else 
    echo "Error: Directory /home/${var.USERNAME}/SensKubeDeploy/opsutils/restartfix-cron.sh does not exists." /home/${var.USERNAME}/directory.txt
fi

cd /home/${var.USERNAME}/Safectl/
docker pull registry:latest
docker run -d -p 5000:5000 --restart=always --name clientregistry registry
cd /home/${var.USERNAME}/SensKubeDeploy
az login -u ${var.AZURE_USER} -p ${var.AZURE_PWD}  > logfile.txt
az account set --subscription ${var.AZURE_SUB_ID} > logfile1.txt
### Customize domain names
subdomain=${var.SUBDOMAIN}
echo "### Customize domain names" > teracustom.env
echo "SUBDOMAIN=$subdomain" >> teracustom.env
#For Registry
echo "#For Registry" >> teracustom.env
echo "SENS_ALGO_DREG=${var.USERNAME}algos.azurecr.io" >> teracustom.env
echo "SENS_ALGO_USER=${var.USERNAME}algos" >> teracustom.env
pswd=$(az acr credential show -n ${var.USERNAME}algos --query passwords[0].value | tr -d '"')
echo "SENS_ALGO_PASSWD=$pswd" >> teracustom.env
cred=${var.USERNAME}algos:$pswd
echo "SENS_ALGO_DCRED=$cred" >> teracustom.env
algoregistrytoken=$(echo $cred | base64)
echo "SENS_ALGO_DREG_AZURE_TOKEN=\""Basic "$algoregistrytoken\"" >> teracustom.env

#For Internal 
echo "#For Internal Bucket" >> teracustom.env
echo "SENSINT_STORAGE_PROVIDER='AZURE'" >> teracustom.env
echo "SENSINT_BUCKET_NAME=${var.USERNAME}-internal-storage" >> teracustom.env
echo "SENSINT_GCS_CREDENTIALS='`cat /home/${var.USERNAME}/gcp-bucket-storage-credentials.json`'" >> teracustom.env
echo "SENSINT_AZURE_STORAGE_ACCOUNT=${var.USERNAME}internal" >> teracustom.env
key=$(az storage account keys list -g  ${var.controller_azurerm_resource_group}-${var.TFUSER} -n ${var.USERNAME}internal | jq '.[0].value')
echo "SENSINT_AZURE_STORAGE_ACCESS_KEY=$key" >> teracustom.env

#For inputdata
echo "#For inputdata Bucket" >> teracustom.env
echo "INPBUCKET_STORAGE_PROVIDER='AZURE'" >> teracustom.env
echo "INPBUCKET_NAME=${var.USERNAME}-inputdata-storage" >> teracustom.env
echo "INPBUCKET_GCS_CREDENTIALS='`cat /home/${var.USERNAME}/gcp-bucket-storage-credentials.json`'" >> teracustom.env
echo "INPBUCKET_AZURE_ACCOUNT=${var.USERNAME}inputdata" >> teracustom.env
inputdatakey=$(az storage account keys list -g  ${var.controller_azurerm_resource_group}-${var.TFUSER} -n ${var.USERNAME}inputdata | jq '.[0].value' | tr -d '"')
echo "INPBUCKET_AZURE_ACCESSKEY=$inputdatakey" >> teracustom.env

#For oauth
echo "#For oauth" >> teracustom.env
echo "SENSOAUTH_AD_PRIMARY_DOMAIN=${var.SENSOAUTH_AD_PRIMARY_DOMAIN}" >> teracustom.env
echo "SENSOAUTH_CLIENT_ID=${var.SENSOAUTH_CLIENT_ID}" >> teracustom.env
echo "SENSOAUTH_CLIENT_SECRET=${var.SENSOAUTH_CLIENT_SECRET}" >> teracustom.env
echo "SENSOAUTH_TENANT_ID=${var.SENSOAUTH_TENANT_ID}" >> teracustom.env

cp teracustom.env /home/${var.USERNAME}/SensKubeDeploy/config/
cat /home/${var.USERNAME}/SensKubeDeploy/config/teracustom.env >> /home/${var.USERNAME}/SensKubeDeploy/config/custom.env
chown -R ${var.USERNAME}:${var.USERNAME} /home/${var.USERNAME}/SensKubeDeploy/config/custom.env
cp /home/${var.USERNAME}/SensKubeDeploy/config/custom.env /mnt/staging/

#To add the safectl cluster 
filename=safectl-${var.USERNAME}.env
echo 'unset `env | grep SAFECTL_ | sed "s;=.*;;" 2> /dev/null`' >> $filename
echo 'export AZURE_CREDS=$(echo '"'"'{"accountName":"'${var.USERNAME}inputdata'","accountKey":"'$inputdatakey'"}'"'"'| jq . | base64 -w0)' >> $filename
USER="{USER}"
echo "export SAFECTL_ROOT_SAFELET_DOCKER_APP_FOLDER=client" >> $filename
echo "export SAFECTL_ROOT_CLUSTER_API_ENDPOINT=https://api-${var.USERNAME}.$subdomain.sensoriant.net/secure_cloud_api/v1/" >> $filename
echo "export SAFECTL_HELPER_CLUSTER_PROVIDER=AZURE" >> $filename
echo "export PATH=<FULL PATH to safectl binary>:\$PATH" >> $filename
echo "" >> $filename
echo "export SAFECTL_IN_DATASET_STORAGE_ACCOUNT=${var.USERNAME}inputdata" >> $filename
echo "export SAFECTL_IN_DATASET_STORAGE_BUCKETNAME=${var.USERNAME}-inputdata-storage" >> $filename
echo 'export SAFECTL_IN_DATASET_STORAGE_CREDENTIALS=$AZURE_CREDS' >> $filename
echo "export SAFECTL_IN_DATASET_STORAGE_PROVIDER=AZURE" >> $filename
echo "" >> $filename
echo "export SAFECTL_OUT_DATASET_STORAGE_ACCOUNT=${var.USERNAME}inputdata" >> $filename
echo "export SAFECTL_OUT_DATASET_STORAGE_BUCKETNAME=${var.USERNAME}-inputdata-storage" >> $filename
echo 'export SAFECTL_OUT_DATASET_STORAGE_CREDENTIALS=$AZURE_CREDS' >> $filename
echo "export SAFECTL_OUT_DATASET_STORAGE_PROVIDER=AZURE" >> $filename
echo "" >> $filename
echo "export SAFECTL_ROOT_IMAGE_REGISTRY_CREDENTIALS=safelishareexternal:4PLkCF/uArKNffcNQpxzSamUclnH5V3n" >> $filename
echo "export SAFECTL_ROOT_IMAGE_REGISTRY=safelishareexternal.azurecr.io" >> $filename
echo "export SAFECTL_ROOT_SAFELET_REGISTRY=${var.USERNAME}algos.azurecr.io" >> $filename																																																																	 
echo "export SAFECTL_ROOT_SAFELET_REGISTRY_CREDENTIALS=$cred" >> $filename
#For oauth
echo "#For oauth" >> $filename
echo "export SAFECTL_SENSOAUTH_AD_PRIMARY_DOMAIN=${var.SENSOAUTH_AD_PRIMARY_DOMAIN}" >> $filename
#echo "export SAFECTL_SENSOAUTH_CLIENT_ID=${var.SENSOAUTH_CLIENT_ID}" >> $filename
#echo "export SAFECTL_SENSOAUTH_CLIENT_SECRET=${var.SENSOAUTH_CLIENT_SECRET}" >> $filename
#echo "export SAFECTL_SENSOAUTH_TENANT_ID=${var.SENSOAUTH_TENANT_ID}" >> $filename
echo "export SAFECTL_ROOT_AUTHORITY=${var.SAFECTL_ROOT_AUTHORITY}" >> $filename
echo "export SAFECTL_ROOT_CLIENT_ID=${var.SAFECTL_ROOT_CLIENT_ID}" >> $filename
echo "export SAFECTL_ROOT_USERNAME=${var.SAFECTL_ROOT_USERNAME}" >> $filename
echo "export SAFECTL_ROOT_PASSWORD=${var.SAFECTL_ROOT_PASSWORD}" >> $filename
echo "export SAFECTL_ROOT_SCOPES=\"https://${var.SENSOAUTH_AD_PRIMARY_DOMAIN}.onmicrosoft.com/${var.SAFECTL_ROOT_CLIENT_ID}/api.getpost\"" >> $filename									
echo 'export SAFECTL_HELPER_SAFELET_REPO_PREFIX=""' >> $filename																								   
echo 'source $SAFECTL_ROOT_SAFELET_DOCKER_APP_FOLDER/app.env' >> $filename
echo 'export SAFECTL_ROOT_IMAGE_REGISTRY_RELEASE_TAG=${var.product_version}' >> $filename

cp safectl-${var.USERNAME}.env /mnt/staging/safectl-configs/
sudo mkdir /mnt/staging/clusters/
sudo mkdir /mnt/staging/clusters/aks-${var.USERNAME}
cd /home/${var.USERNAME}/SensKubeDeploy/config
sed -i 's/devel/'"${var.SUBDOMAIN}"'/g' /home/${var.USERNAME}/SensKubeDeploy/config/skif.env
sed -i 's/sensuser/'"${var.USERNAME}"'/g' /home/${var.USERNAME}/SensKubeDeploy/config/skif.env

reboot
CUSTOM_DATA
}

resource "azurerm_linux_virtual_machine" "main" {
    name                  = "${var.con_name_init}-${var.controller_name}-${var.TFUSER}"
    location              = var.location
    resource_group_name   = azurerm_resource_group.sens_controller.name
    network_interface_ids = [azurerm_network_interface.main.id]
    size                  = "Standard_B4ms"

    os_disk {
        name              = "myOsdisk"
        disk_size_gb      = "100"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18_04-lts-gen2"
        version   = "latest"
    }
    
    custom_data = base64encode(local.custom_data)
    computer_name  ="${var.con_name_init}-${var.controller_name}-${var.TFUSER}"
    admin_username = var.USERNAME
    disable_password_authentication = true
        
    admin_ssh_key {
        username       = var.USERNAME
        public_key     = tls_private_key.sens_controller_ssh.public_key_openssh
    }

    tags = {
        environment = "v0.0.1"
    }
}

resource "azurerm_network_security_group" "sens_controller" {
  name                = "sens-network-security-group-${var.TFUSER}"
  location            = var.location
  resource_group_name = azurerm_resource_group.sens_controller.name

  security_rule {
    name                       = "sens-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_container_registry" "acr" {
  name                     = "${var.USERNAME}algos"
  resource_group_name      = azurerm_resource_group.sens_controller.name
  location                 = var.location
  sku                      = "Basic"
  admin_enabled            = true
}

resource "azurerm_network_interface_security_group_association" "security_group_controller_association" {
  network_interface_id = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.sens_controller.id
}

resource "null_resource" remoteExecProvisionerWFolder {

  provisioner "file" {
    source      = "../../gcp-bucket-storage-credentials.json"
    destination = "/home/${var.USERNAME}/gcp-bucket-storage-credentials.json"
  }

  connection {
    host     = azurerm_linux_virtual_machine.main.public_ip_address
    type     = "ssh"
    user     = var.USERNAME
    private_key = tls_private_key.sens_controller_ssh.private_key_pem
    agent    = "false"
  }
}


output "instance_ip_addr" {
  value       = "${azurerm_linux_virtual_machine.main.public_ip_address}"
  description = "The public IP address of the main server instance."
}
output "USERNAME" {
  value       = var.USERNAME
  description = "The user name."
}


output "RSCR_GRP" {
  value       = "${var.controller_azurerm_resource_group}-${var.TFUSER}"
  description = "The user name."
}
output "admin_password" {
  value       = azurerm_container_registry.acr.admin_password
  description = "The object ID of the user"
}
