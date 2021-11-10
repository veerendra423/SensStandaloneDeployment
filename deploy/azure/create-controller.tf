provider "azurerm" {
  version = "=2.21.0"
  features {}
}

resource "azurerm_resource_group" "sens_controller" {
  name     = "${var.controller_skif_azurerm_resource_group}-${var.TFUSER}"
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
git clone https://github.com/intel/linux-sgx-driver.git
git clone https://github.com/PrefectHQ/prefect.git
git clone https://github.com/oscarlab/graphene-sgx-driver.git
chown -R ${var.USERNAME}:${var.USERNAME} linux-sgx-driver
cd linux-sgx-driver
make clean
make
mkdir -p "/lib/modules/"`uname -r`"/kernel/drivers/intel/sgx"   
cp isgx.ko "/lib/modules/"`uname -r`"/kernel/drivers/intel/sgx"   
sh -c "cat /etc/modules | grep -Fxq isgx || echo isgx >> /etc/modules"   
/sbin/depmod
/sbin/modprobe isgx
cd /graphene-sgx-driver
export ISGX_DRIVER_PATH=/graphene-sgx-driver
ISGX_DRIVER_PATH=/graphene-sgx-driver make
cp gsgx.ko "/lib/modules/"`uname -r`"/kernel/drivers/intel/sgx"
sh -c "cat /etc/modules | grep -Fxq gsgx || echo gsgx >> /etc/modules"
/sbin/depmod
/sbin/modprobe gsgx

if [ ${var.SSM_TYPE} == "true" ];
then
echo "This is a ssm type machine" > check.txt
else
FILE=/home/${var.USERNAME}/${var.product_version}.tar.gz
until [ -f $FILE ]
do
sleep 30
done
mkdir -p /opt/${var.product_version}
tar xvzf /home/${var.USERNAME}/${var.product_version}.tar.gz -C /opt/${var.product_version}
fi


docker network create sensnet
docker login -u ${var.docker_user} -p ${var.docker_pwd} ${var.docker_registry}
groupadd docker
usermod -aG docker ${var.USERNAME}

if [ ${var.PLATFORM_PROVIDER} == "AZURE" ];
then
sed -i 's/REPLACE_WITH_SANDBOX_NAME/'"${var.sandbox_azure_name}-${var.TFUSER}"'/g' /opt/${var.product_version}/app/.env
fi
if [ ${var.PLATFORM_PROVIDER} == "GOOGLE" ];
then
sed -i 's/REPLACE_WITH_SANDBOX_NAME/'"${var.sandbox_google_name}-${var.TFUSER}"'/g' /opt/${var.product_version}/app/.env
fi
pushd /opt/${var.product_version}/app/ > /dev/null
./updateenv.sh
popd > /dev/null

PUBLIC_IP_ADDRESS=$(curl checkip.amazonaws.com)
echo PUBLIC_IP_ADDRESS=$(curl checkip.amazonaws.com) >> /opt/${var.product_version}/app/.env
sed -i 's/REPLACE_WITH_CONTROLLER_IP/'"$PUBLIC_IP_ADDRESS"'/g' /opt/${var.product_version}/app/.env
echo "@reboot ${var.USERNAME} docker login -u ${var.docker_user} -p ${var.docker_pwd} ${var.docker_registry}" >> /etc/crontab
if [ ${var.SSM_TYPE} == "false" ];
then
echo "@reboot ${var.USERNAME} /opt/${var.product_version}/app/start.sh ${var.product_version}" >> /etc/crontab
fi
mkdir -p /home/${var.USERNAME}/.docker
cp /root/.docker/config.json /home/${var.USERNAME}/.docker/
chown -R ${var.USERNAME}:${var.USERNAME} /home/${var.USERNAME}/.docker
chown -R ${var.USERNAME}:${var.USERNAME} /opt/${var.product_version}
docker pull sensoriant.azurecr.io/swagger_repo_list:1.0	
docker-compose -f /opt/${var.product_version}/app/operator/docker-compose.yml --project-directory /opt/${var.product_version}/app/operator pull
reboot
CUSTOM_DATA
}

resource "azurerm_linux_virtual_machine" "main" {
    name                  = "${var.con_name_init}-${var.controller_name}-${var.TFUSER}"
    location              = var.location
    resource_group_name   = azurerm_resource_group.sens_controller.name
    network_interface_ids = [azurerm_network_interface.main.id]
    size                  = "Standard_DC4s_v2"

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

  security_rule {
    name                       = "sens-pm1"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8081"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "sens-pm2"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "18765"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
   security_rule {
    name                       = "sens-pm3"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "sens-pm4"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5010"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  security_rule {
    name                       = "sens-pm5"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "*"
    destination_address_prefixes = ["${azurerm_linux_virtual_machine.main.public_ip_address}",var.whitelist_mariadb_ips[0],var.whitelist_mariadb_ips[1],var.whitelist_mariadb_ips[2]]
  }
  
  security_rule {
    name                       = "sens-pm6"
    priority                   = 106
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9201"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  security_rule {
    name                       = "sens-pm7"
    priority                   = 107
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9103"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }


  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface_security_group_association" "security_group_controller_association" {
  network_interface_id = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.sens_controller.id
}

output "instance_ip_addr" {
  value       = "${azurerm_linux_virtual_machine.main.public_ip_address}"
  description = "The public IP address of the main server instance."
}
output "product_output" {
  value       = var.product_version
  description = "The product_version."
}
output "USERNAME" {
  value       = var.USERNAME
  description = "The user name."
}
