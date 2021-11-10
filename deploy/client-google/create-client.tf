provider "azurerm" {
  version = "=2.21.0"
  features {}
}

provider "google" {
  version = "3.86.0"
  credentials = file("../../gcp-compute-credentials.json")                  
  project = local.json_data.project_id
  region  = var.region_location
  zone    = var.glocation
}

provider "google-beta" {
  version = "3.86.0"
  credentials = file("../../852157164149-compute@developer.gserviceaccount.com.json")
  project     = local.json_data1.project_id
  region      = var.glocation
}

# Create a internal GCS Bucket
resource "google_storage_bucket" "my_internal_bucket" {
name     = "${var.USERNAME}-internal-storage"
location = var.region_location
force_destroy = true
}

# Create a input GCS Bucket
resource "google_storage_bucket" "my_input_bucket" {
name     = "${var.USERNAME}-input-storage"
location = var.region_location
force_destroy = true
}

# Create a output GCS Bucket
resource "google_storage_bucket" "my_output_bucket" {
name     = "${var.USERNAME}-output-storage"
location = var.region_location
force_destroy = true
}

resource "google_artifact_registry_repository" "myrepo" {
  provider = google-beta
  location = var.glocation
  repository_id = "${var.USERNAME}algos"
  description = "docker repository"
  format = "DOCKER"
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


locals {
json_data = jsondecode(file("../../gcp-compute-credentials.json"))
json_data1 = jsondecode(file("../../852157164149-compute@developer.gserviceaccount.com.json"))
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
#To install the gcloud
sudo snap install --classic google-cloud-sdk
#gcloud config set project lyrical-gantry-279014  > gcloudtry.txt
gcloud auth activate-service-account gcs-data-bucket@lyrical-gantry-279014.iam.gserviceaccount.com --key-file=/mnt/staging/Sensoriant-gcs-data-bucket-ServiceAcct.json --project=lyrical-gantry-279014 >> gcloudtry.txt

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



#To clone the code
cd /home/${var.USERNAME}/
git_token=`cat /mnt/staging/github-creds`

git clone https://$git_token@github.com/sensoriant/SensKubeDeploy.git
git clone https://$git_token@github.com/sensoriant/Safectl.git

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
echo "SENS_ALGO_DREG=us-east4-docker.pkg.dev" >> teracustom.env
echo "SENS_ALGO_USER=_json_key_base64" >> teracustom.env
echo "SENS_ALGO_PASSWD=\"ewogICJ0eXBlIjogInNlcnZpY2VfYWNjb3VudCIsCiAgInByb2plY3RfaWQiOiAia3ViZS1wcm9qZWN0LTMwNTgxNyIsCiAgInByaXZhdGVfa2V5X2lkIjogImFjODM5ZGFiMTRhZmNjMjg3MWNjMGRjZWQ2Y2NiYWE1MjA2NmI3NzQiLAogICJwcml2YXRlX2tleSI6ICItLS0tLUJFR0lOIFBSSVZBVEUgS0VZLS0tLS1cbk1JSUV2UUlCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQktjd2dnU2pBZ0VBQW9JQkFRQzRuSmVlcXZBR3FxNVBcbkdOVDZtVzFEOS9iTUVwZzNRcFdrSTQwckJGRFVsL3FYNWhtcUI0UjltbnNJdVNiR0hsNDJmSW9EUnRZNFFwTDJcbnNET2xqemptTkd2RVpDK1IyVEdrdE1RZ3A0WXdPZFJsY1FrU2F2VUxNclE5Z0l5QlZXbWRDVTVRV2ltTGVMTkRcbnFFVmVSZVJSMHRkdFdLRGNYNWlyaTJDSWFzQmZwY25CQjBUN1BwRGxQcFh0ZnI1RVptNm5ObVZnQkhWbjFwWE5cbkhXQzJMVTBkTVZXdVJVWlMrMk43UUlYSmZJQVljT2pPTExtVEVyd2k1cy90NG9VNTkrYmwwSFZpWS8rVXRwcE9cbnRpTkY4cTFhOWEwa0RnUk05U2R6SlppUVBtQis4VFpSOXg2bXB5aFNIMkg3aHBGK1ZRY1lTd2lTKzYxdVh5TUZcbkFtUTljMkFUQWdNQkFBRUNnZ0VBVzdwMi9jQTZ0bDFOY2dESkptRmdzTkorL3VSSVhNREpZTDdIY0hYYkFkOG9cbkJSeXdhTk1HYW5COUxKYnU1S2NITWZTTWtOYzhMc1VwaDhpQ1NRT1NocFBLYmxGSGI2VW5MUXNpbm9VT3dGeWpcbm8rblgwNTV3ZG1seHRGTnd2UHluRnYrZU9YK3JQK0V2MVhEQlV2ZlFYRFd5aytMalBzeURLODE3b0J6R3pGN1lcbmYvL3dZT1JiTmhoamxRZ2ltREdpTTlZa3BlQWlwaDBscVV5UlhHNjdUcVIwajhkVlQxTll4blZwWnJjRjlWbXRcbnhOZEhTSUJXN25CSWhXRThWR3FLdW5sNHRNSE9WVTJOaVprZGZ5d0VtNTN2TEl2bXpqanVRd0lSNCt1b3BYMmFcbkVNNU51QnlZWGt1ZXlIZGVnTVozbncxejFuVno3a3MxOTNvdVlsaGN1UUtCZ1FEZEs4KzRJRC9MQmFxRzEvZ29cbmZMcHlKS3hpY3M3L0tLbjlLVjdRUllUemllWXhueEZZRnBnNWozcTVHSG51U2pPT05YTDBiSG4veGVlbzRucy9cbjd2dTZRN04vSjc3V0YwVU5MVzR3N2JuZ2duSXN5WXdWK0x0VVkxZUVibzNKd04yRHBqR2t2QW8yNmpnYkVvbFFcbkNEK2hWL0NIQTV0MURrdStEWk5jcTRWOXFRS0JnUURWcnZERkJBN29jZWlrM2Z4cXlGR1FRS1FKaWJ2NEdDQ2VcbjlQSFdDTmhPdHpINWNhWnMrNUZLYWhNMnB3dk5OV1hrSDJmWkJNZDJKa05HOXhOSHI0RUdtRTdscGJJckZzZkNcbkxidUkweEFISldNOE9MSENDVGFCeXhhaFB5bVQ2RCtUcVduNHJFdkF1MXVocGNpVVhUN0dFQy9udDhRclI2a2Fcbm9Vc2Nka0V0V3dLQmdGTWNLb05EUXhXVWZIOE5Xd2hEem9Bai9jOUUyem9RMnNmeUt0blN0ZUlhV0xFZTJCS2tcbjh2RDJWS1NIYVJJOU9lQmZmMklQL1V3NjN4R2NnYm9Gb1B4ZWdtM3V6b3grMUFqZW9JQ3NaR1BVUVBsSmgyV2VcblFTNjE0ZVkyOFByMmlZYjJCY09ra2FZUEg2UTBzL3FxRHRjZlI1aEVwNzgxN3dwczZZb3lQZ2g1QW9HQWFZa3RcbmdTQ3YvRDNHR1NkS003TWNGWkxYY1o2Rko5TkN5VDlROGRVTWdGUWFhb2luR2N4bHhjcitFbEFPbEJ0N1oxL2JcbmVtUFIzNWltUWJabDMxSGU5OUxocEtwaGhNYUxnbXZ6NDIvYXlxeThobEc1K1l0elVFZHR0ZFhzUXhEQjFid21cbmlwc09Edko2SHl3eUZKUzVIRG1DYjM5amM3ekEyRll4TXExMUkyRUNnWUVBd0dSWWc2RXpsR205MUR6aUZyT09cbnVyVTVHR2d4czF6NGYxTmNzd0w2amo1TzJ1SU16YyswVVRmZVh5UCtQeXFBQW5WRWJtNkN5ZnhONlF3K3gwemlcbk15SS9VNlh1L0RZM002M3R5U2JzQ09lOW9rWFdoVnZmQUhwT200ZnlmMExhS0xoSDdIOEYyT0tweDNjRVBiMzFcbkQwdjZMS2pzSSsydTh4bkJrVm9kS3VvPVxuLS0tLS1FTkQgUFJJVkFURSBLRVktLS0tLVxuIiwKICAiY2xpZW50X2VtYWlsIjogIjg1MjE1NzE2NDE0OS1jb21wdXRlQGRldmVsb3Blci5nc2VydmljZWFjY291bnQuY29tIiwKICAiY2xpZW50X2lkIjogIjEwNzg1NTE1NTI5MTA3NTA3MDc0MSIsCiAgImF1dGhfdXJpIjogImh0dHBzOi8vYWNjb3VudHMuZ29vZ2xlLmNvbS9vL29hdXRoMi9hdXRoIiwKICAidG9rZW5fdXJpIjogImh0dHBzOi8vb2F1dGgyLmdvb2dsZWFwaXMuY29tL3Rva2VuIiwKICAiYXV0aF9wcm92aWRlcl94NTA5X2NlcnRfdXJsIjogImh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL29hdXRoMi92MS9jZXJ0cyIsCiAgImNsaWVudF94NTA5X2NlcnRfdXJsIjogImh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL3JvYm90L3YxL21ldGFkYXRhL3g1MDkvODUyMTU3MTY0MTQ5LWNvbXB1dGUlNDBkZXZlbG9wZXIuZ3NlcnZpY2VhY2NvdW50LmNvbSIKfQo=\"" >> teracustom.env
echo 'SENS_ALGO_DCRED=$SENS_ALGO_USER:$SENS_ALGO_PASSWD' >> teracustom.env
echo 'SENS_ALGO_DREG_AZURE_TOKEN=$SENS_ALGO_DCRED' >> teracustom.env

#For Internal 
echo "#For Internal Bucket" >> teracustom.env
echo "SENSINT_STORAGE_PROVIDER='GOOGLE'" >> teracustom.env
echo "SENSINT_BUCKET_NAME=${var.USERNAME}-internal-storage" >> teracustom.env
echo "SENSINT_GCS_CREDENTIALS='`cat /home/${var.USERNAME}/gcp-bucket-storage-credentials.json`'" >> teracustom.env
echo "SENSINT_AZURE_STORAGE_ACCOUNT=idk" >> teracustom.env
echo "SENSINT_AZURE_STORAGE_ACCESS_KEY=idk" >> teracustom.env

#For inputdata
echo "#For inputdata Bucket" >> teracustom.env
echo 'INPBUCKET_STORAGE_PROVIDER=$SENSINT_STORAGE_PROVIDER' >> teracustom.env
echo 'INPBUCKET_NAME=${var.USERNAME}-input-storage' >> teracustom.env
echo 'INPBUCKET_GCS_CREDENTIALS=$SENSINT_GCS_CREDENTIALS' >> teracustom.env
echo 'INPBUCKET_AZURE_ACCOUNT=$SENSINT_AZURE_STORAGE_ACCOUNT' >> teracustom.env
echo 'INPBUCKET_AZURE_ACCESSKEY=$SENSINT_AZURE_STORAGE_ACCESS_KEY' >> teracustom.env

#For output data
echo "#For outputdata Bucket" >> teracustom.env
echo 'OUTBUCKET_STORAGE_PROVIDER=$SENSINT_STORAGE_PROVIDER' >> teracustom.env
echo 'OUTBUCKET_NAME=${var.USERNAME}-output-storage' >> teracustom.env
echo 'OUTBUCKET_GCS_CREDENTIALS=$SENSINT_GCS_CREDENTIALS' >> teracustom.env
echo 'OUTBUCKET_AZURE_ACCOUNT=$SENSINT_AZURE_STORAGE_ACCOUNT' >> teracustom.env
echo 'OUTBUCKET_AZURE_ACCESSKEY=$SENSINT_AZURE_STORAGE_ACCESS_KEY' >> teracustom.env

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
USER="{USER}"	
echo "export SAFECTL_ROOT_SAFELET_DOCKER_APP_FOLDER=client" > $filename
echo "export SAFECTL_ROOT_CLUSTER_API_ENDPOINT=https://api-<clustername>.${var.SUBDOMAIN}.sensoriant.net/secure_cloud_api/v1/" >> $filename
echo "export SAFECTL_HELPER_CLUSTER_PROVIDER=GOOGLE" >> $filename
echo "export PATH=<FULL PATH to safectl binary>:\$PATH" >> $filename


echo "export SAFECTL_IN_DATASET_STORAGE_ACCOUNT=${var.USERNAME}inputstorage" >> $filename
echo "export SAFECTL_IN_DATASET_STORAGE_BUCKETNAME=${var.USERNAME}-input-storage" >> $filename
echo "export SAFECTL_IN_DATASET_STORAGE_CREDENTIALS='`cat /home/${var.USERNAME}/gcp-bucket-storage-credentials.json`'" >> $filename
echo "export SAFECTL_IN_DATASET_STORAGE_PROVIDER=GOOGLE" >> $filename
echo 'export SAFECTL_OUT_DATASET_STORAGE_ACCOUNT=$SAFECTL_IN_DATASET_STORAGE_ACCOUNT' >> $filename
echo "export SAFECTL_OUT_DATASET_STORAGE_BUCKETNAME=${var.USERNAME}-output-storage" >> $filename
echo "export SAFECTL_OUT_DATASET_STORAGE_CREDENTIALS='`cat /home/${var.USERNAME}/gcp-bucket-storage-credentials.json`'" >> $filename
echo 'export SAFECTL_OUT_DATASET_STORAGE_PROVIDER=$SAFECTL_IN_DATASET_STORAGE_PROVIDER' >> $filename
echo "export SAFECTL_ROOT_IMAGE_REGISTRY_CREDENTIALS=safelishareexternal:4PLkCF/uArKNffcNQpxzSamUclnH5V3n" >> $filename
echo "export SAFECTL_ROOT_IMAGE_REGISTRY=safelishareexternal.azurecr.io" >> $filename

echo "export SAFECTL_ROOT_SAFELET_REGISTRY_CREDENTIALS=\"_json_key_base64:ewogICJ0eXBlIjogInNlcnZpY2VfYWNjb3VudCIsCiAgInByb2plY3RfaWQiOiAia3ViZS1wcm9qZWN0LTMwNTgxNyIsCiAgInByaXZhdGVfa2V5X2lkIjogImFjODM5ZGFiMTRhZmNjMjg3MWNjMGRjZWQ2Y2NiYWE1MjA2NmI3NzQiLAogICJwcml2YXRlX2tleSI6ICItLS0tLUJFR0lOIFBSSVZBVEUgS0VZLS0tLS1cbk1JSUV2UUlCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQktjd2dnU2pBZ0VBQW9JQkFRQzRuSmVlcXZBR3FxNVBcbkdOVDZtVzFEOS9iTUVwZzNRcFdrSTQwckJGRFVsL3FYNWhtcUI0UjltbnNJdVNiR0hsNDJmSW9EUnRZNFFwTDJcbnNET2xqemptTkd2RVpDK1IyVEdrdE1RZ3A0WXdPZFJsY1FrU2F2VUxNclE5Z0l5QlZXbWRDVTVRV2ltTGVMTkRcbnFFVmVSZVJSMHRkdFdLRGNYNWlyaTJDSWFzQmZwY25CQjBUN1BwRGxQcFh0ZnI1RVptNm5ObVZnQkhWbjFwWE5cbkhXQzJMVTBkTVZXdVJVWlMrMk43UUlYSmZJQVljT2pPTExtVEVyd2k1cy90NG9VNTkrYmwwSFZpWS8rVXRwcE9cbnRpTkY4cTFhOWEwa0RnUk05U2R6SlppUVBtQis4VFpSOXg2bXB5aFNIMkg3aHBGK1ZRY1lTd2lTKzYxdVh5TUZcbkFtUTljMkFUQWdNQkFBRUNnZ0VBVzdwMi9jQTZ0bDFOY2dESkptRmdzTkorL3VSSVhNREpZTDdIY0hYYkFkOG9cbkJSeXdhTk1HYW5COUxKYnU1S2NITWZTTWtOYzhMc1VwaDhpQ1NRT1NocFBLYmxGSGI2VW5MUXNpbm9VT3dGeWpcbm8rblgwNTV3ZG1seHRGTnd2UHluRnYrZU9YK3JQK0V2MVhEQlV2ZlFYRFd5aytMalBzeURLODE3b0J6R3pGN1lcbmYvL3dZT1JiTmhoamxRZ2ltREdpTTlZa3BlQWlwaDBscVV5UlhHNjdUcVIwajhkVlQxTll4blZwWnJjRjlWbXRcbnhOZEhTSUJXN25CSWhXRThWR3FLdW5sNHRNSE9WVTJOaVprZGZ5d0VtNTN2TEl2bXpqanVRd0lSNCt1b3BYMmFcbkVNNU51QnlZWGt1ZXlIZGVnTVozbncxejFuVno3a3MxOTNvdVlsaGN1UUtCZ1FEZEs4KzRJRC9MQmFxRzEvZ29cbmZMcHlKS3hpY3M3L0tLbjlLVjdRUllUemllWXhueEZZRnBnNWozcTVHSG51U2pPT05YTDBiSG4veGVlbzRucy9cbjd2dTZRN04vSjc3V0YwVU5MVzR3N2JuZ2duSXN5WXdWK0x0VVkxZUVibzNKd04yRHBqR2t2QW8yNmpnYkVvbFFcbkNEK2hWL0NIQTV0MURrdStEWk5jcTRWOXFRS0JnUURWcnZERkJBN29jZWlrM2Z4cXlGR1FRS1FKaWJ2NEdDQ2VcbjlQSFdDTmhPdHpINWNhWnMrNUZLYWhNMnB3dk5OV1hrSDJmWkJNZDJKa05HOXhOSHI0RUdtRTdscGJJckZzZkNcbkxidUkweEFISldNOE9MSENDVGFCeXhhaFB5bVQ2RCtUcVduNHJFdkF1MXVocGNpVVhUN0dFQy9udDhRclI2a2Fcbm9Vc2Nka0V0V3dLQmdGTWNLb05EUXhXVWZIOE5Xd2hEem9Bai9jOUUyem9RMnNmeUt0blN0ZUlhV0xFZTJCS2tcbjh2RDJWS1NIYVJJOU9lQmZmMklQL1V3NjN4R2NnYm9Gb1B4ZWdtM3V6b3grMUFqZW9JQ3NaR1BVUVBsSmgyV2VcblFTNjE0ZVkyOFByMmlZYjJCY09ra2FZUEg2UTBzL3FxRHRjZlI1aEVwNzgxN3dwczZZb3lQZ2g1QW9HQWFZa3RcbmdTQ3YvRDNHR1NkS003TWNGWkxYY1o2Rko5TkN5VDlROGRVTWdGUWFhb2luR2N4bHhjcitFbEFPbEJ0N1oxL2JcbmVtUFIzNWltUWJabDMxSGU5OUxocEtwaGhNYUxnbXZ6NDIvYXlxeThobEc1K1l0elVFZHR0ZFhzUXhEQjFid21cbmlwc09Edko2SHl3eUZKUzVIRG1DYjM5amM3ekEyRll4TXExMUkyRUNnWUVBd0dSWWc2RXpsR205MUR6aUZyT09cbnVyVTVHR2d4czF6NGYxTmNzd0w2amo1TzJ1SU16YyswVVRmZVh5UCtQeXFBQW5WRWJtNkN5ZnhONlF3K3gwemlcbk15SS9VNlh1L0RZM002M3R5U2JzQ09lOW9rWFdoVnZmQUhwT200ZnlmMExhS0xoSDdIOEYyT0tweDNjRVBiMzFcbkQwdjZMS2pzSSsydTh4bkJrVm9kS3VvPVxuLS0tLS1FTkQgUFJJVkFURSBLRVktLS0tLVxuIiwKICAiY2xpZW50X2VtYWlsIjogIjg1MjE1NzE2NDE0OS1jb21wdXRlQGRldmVsb3Blci5nc2VydmljZWFjY291bnQuY29tIiwKICAiY2xpZW50X2lkIjogIjEwNzg1NTE1NTI5MTA3NTA3MDc0MSIsCiAgImF1dGhfdXJpIjogImh0dHBzOi8vYWNjb3VudHMuZ29vZ2xlLmNvbS9vL29hdXRoMi9hdXRoIiwKICAidG9rZW5fdXJpIjogImh0dHBzOi8vb2F1dGgyLmdvb2dsZWFwaXMuY29tL3Rva2VuIiwKICAiYXV0aF9wcm92aWRlcl94NTA5X2NlcnRfdXJsIjogImh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL29hdXRoMi92MS9jZXJ0cyIsCiAgImNsaWVudF94NTA5X2NlcnRfdXJsIjogImh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL3JvYm90L3YxL21ldGFkYXRhL3g1MDkvODUyMTU3MTY0MTQ5LWNvbXB1dGUlNDBkZXZlbG9wZXIuZ3NlcnZpY2VhY2NvdW50LmNvbSIKfQo=\"" >> $filename

echo "export SAFECTL_ROOT_SAFELET_REGISTRY=us-east4-docker.pkg.dev" >> $filename
echo "" >> $filename
#echo "if [ -z \$SAFECTL_ROOT_SAFELET_REGISTRY##*.azurecr.io ]; then" >> $filename
echo 'if [ -z $'""'{SAFECTL_ROOT_SAFELET_REGISTRY##*.azurecr.io}'""' ]; then' >> $filename
echo "export SAFECTL_HELPER_SAFELET_REPO_PREFIX=" >> $filename
echo "elif [ -z \$"''"{SAFECTL_ROOT_SAFELET_REGISTRY##*.pkg.dev}"''" ]; then" >> $filename
echo "export SAFECTL_HELPER_SAFELET_REPO_PREFIX=\"kube-project-305817/${var.USERNAME}algos/\"" >> $filename
echo "else" >> $filename
echo "echo Unsupported registry \$SAFECTL_ROOT_SAFELET_REGISTRY" >> $filename
echo "exit 1" >> $filename
echo "fi" >> $filename

#For oauth
echo "#For oauth" >> $filename
echo "export SAFECTL_SENSOAUTH_AD_PRIMARY_DOMAIN=${var.SENSOAUTH_AD_PRIMARY_DOMAIN}" >> $filename
echo "export SAFECTL_ROOT_AUTHORITY=${var.SAFECTL_ROOT_AUTHORITY}" >> $filename
echo "export SAFECTL_ROOT_CLIENT_ID=${var.SAFECTL_ROOT_CLIENT_ID}" >> $filename
echo "export SAFECTL_ROOT_USERNAME=${var.SAFECTL_ROOT_USERNAME}" >> $filename
echo "export SAFECTL_ROOT_PASSWORD=${var.SAFECTL_ROOT_PASSWORD}" >> $filename
echo "export SAFECTL_ROOT_SCOPES=\"https://${var.SENSOAUTH_AD_PRIMARY_DOMAIN}.onmicrosoft.com/${var.SAFECTL_ROOT_CLIENT_ID}/api.getpost\"" >> $filename	

echo "source \$SAFECTL_ROOT_SAFELET_DOCKER_APP_FOLDER/app.env" >> $filename
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

resource "null_resource" remoteExecProvisionerWFolder {

  provisioner "file" {
    source      = "../../gcp-compute-credentials.json"
    destination = "/home/${var.USERNAME}/gcp-compute-credentials.json"
  }
  provisioner "file" {
    source      = "../../gcp-bucket-storage-credentials.json"
    destination = "/home/${var.USERNAME}/gcp-bucket-storage-credentials.json"
  }
  provisioner "file" {
    source      = "../../852157164149-compute@developer.gserviceaccount.com.json"
    destination = "/home/${var.USERNAME}/852157164149-compute@developer.gserviceaccount.com.json"
  }

  connection {
    host     = azurerm_linux_virtual_machine.main.public_ip_address
    type     = "ssh"
    user     = var.USERNAME
    private_key = tls_private_key.sens_controller_ssh.private_key_pem
    agent    = "false"
  }
}

resource "azurerm_network_interface_security_group_association" "security_group_controller_association" {
  network_interface_id = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.sens_controller.id
}


output "sandbox_instance_ip_addr" {
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

