provider "google" {
  version = "3.5.0"

  credentials = file("../../gcp-compute-credentials.json")                  
  project = local.json_data.project_id
  region  = var.region_location
  zone    = var.location
}

resource "tls_private_key" "sandbox_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}

output "tls_private_key_sandbox" { value = "${tls_private_key.sandbox_ssh.private_key_pem}" }

locals {
json_data = jsondecode(file("../../gcp-compute-credentials.json"))

  custom_data1 = <<CUSTOM_DATA
#!/bin/bash
if ! test -f /opt/${var.product_version}/app/instance_status.txt ; then
fallocate -l 16G /swapfile
dd if=/dev/zero of=/swapfile bs=1024 count=16048576
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
apt update
apt-get install jq -y
apt install make gcc apt-transport-https ca-certificates curl jq software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg |  apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt update														   
apt-cache policy docker-ce
apt install docker-ce python3 python3-pip -y
curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-Linux-x86_64" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
git clone https://github.com/PrefectHQ/prefect.git
tar xvf /home/${var.USERNAME}/graphene-sgx-driver.tar.gz -C .
mv /app/graphene-sgx-driver/ .
mkdir -p "/lib/modules/"`uname -r`"/kernel/drivers/intel/sgx"   
cd /graphene-sgx-driver
export ISGX_DRIVER_PATH=/graphene-sgx-driver
ISGX_DRIVER_PATH=/graphene-sgx-driver make
cp gsgx.ko "/lib/modules/"`uname -r`"/kernel/drivers/intel/sgx"
sh -c "cat /etc/modules | grep -Fxq gsgx || echo gsgx >> /etc/modules"
/sbin/depmod
/sbin/modprobe gsgx
FILE=/home/${var.USERNAME}/${var.product_version}.tar.gz
until [ -f $FILE ]
do
sleep 30
done
sleep 60
My_prod_vers1=${var.product_version}
My_prod_vers=/opt/$My_prod_vers1
mkdir -p $My_prod_vers
tar xvf /home/${var.USERNAME}/${var.product_version}.tar.gz -C /opt/${var.product_version}
docker network create sensnet
docker login -u ${var.docker_user} -p ${var.docker_pwd} ${var.docker_registry}
groupadd docker
usermod -aG docker ${var.USERNAME}
docker login -u ${var.docker_user} -p ${var.docker_pwd} ${var.docker_registry}
echo "@reboot ${var.USERNAME} /opt/${var.product_version}/app/start_sandbox_setup.sh ${var.product_version}" >> /etc/crontab
mkdir -p /home/${var.USERNAME}/.docker
cp /root/.docker/config.json /home/${var.USERNAME}/.docker/
chown -R ${var.USERNAME}:${var.USERNAME} /home/${var.USERNAME}/.docker
chown -R ${var.USERNAME}:${var.USERNAME} /opt/${var.product_version}	
sed -i 's/REPLACE_WITH_SANDBOX_NAME/'"${var.sandbox_name}-${var.TFUSER}"'/g' /opt/${var.product_version}/app/.env
sed -i 's/REPLACE_WITH_CONTROLLER_IP/'"${var.controlleripaddr}"'/g' /opt/${var.product_version}/app/.env
pushd /opt/${var.product_version}/app/ > /dev/null
./updateenv.sh
popd > /dev/null
sudo chown -R ${var.USERNAME}:${var.USERNAME} /opt/${var.product_version}/app/.env
#su - ${var.USERNAME} -c 'bash /opt/${var.product_version}/app/start_sandbox_setup.sh ${var.product_version}'
#sudo su
if [ ${var.GPU_MODE} == "true" ];
then
curl -s -L https://nvidia.github.io/nvidia-container-runtime/gpgkey | \
 sudo apt-key add -
#cuda drivers
distribution=$(. /etc/os-release;echo $ID$VERSION_ID | sed -e 's/\.//g')
wget https://developer.download.nvidia.com/compute/cuda/repos/$distribution/x86_64/cuda-$distribution.pin
sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/$distribution/x86_64/7fa2af80.pub
echo "deb https://developer.download.nvidia.com/compute/cuda/repos/$distribution/x86_64 /" | sudo tee /etc/apt/sources.list.d/cuda.list
#nvidia runtime
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-container-runtime/$distribution/nvidia-container-runtime.list | \
 sudo tee /etc/apt/sources.list.d/nvidia-container-runtime.list
sudo apt update
sudo cat <<EOF >> /etc/docker/daemon.json
{
  "default-runtime": "nvidia",
  "runtimes": {
    "nvidia": {
      "path": "nvidia-container-runtime",
      "runtimeArgs": []
    }
  }
}
EOF
sudo apt-get -y install cuda-drivers
sudo apt-get update
sudo apt-get -y install nvidia-container-runtime
sudo apt-get update
fi
sudo touch /opt/${var.product_version}/app/instance_status.txt
sudo reboot
fi

CUSTOM_DATA
}

resource "google_compute_instance" "sens_sandbox" {
  name         = "${var.sandbox_name}-${var.TFUSER}"
  machine_type = (var.GPU_MODE != "true" ? var.machine_CPU : var.machine_GPU)

  zone         = var.location
  tags         = ["web"]

  boot_disk {
    initialize_params {

      image = "ubuntu-os-cloud/ubuntu-1804-lts"

      size  = 100

    }

  }

 metadata = {
   ssh-keys = "${var.USERNAME}:${tls_private_key.sandbox_ssh.public_key_openssh}"
 }

  network_interface {
    network = "default"

    access_config {
   
      // Include this section to give the VM an external ip address
    }
  }

 guest_accelerator{
    type = var.gpu_type // Type of GPU attahced
    count = (var.GPU_MODE != "true" ? 0 : 1) // Num of GPU attached
  }
  scheduling{
    on_host_maintenance = (var.GPU_MODE != "true" ? "MIGRATE" : "TERMINATE") // Need to terminate GPU on maintenance
  }

  metadata_startup_script = local.custom_data1
    // Apply the firewall rule to allow external IPs to access this instance    
	 
  service_account {
  email = local.json_data.client_email
  scopes = ["cloud-platform"]
  }
}

// A variable for extracting the external IP address of the instance
output "instance_ip_sandbox" {
 value = google_compute_instance.sens_sandbox.network_interface.0.access_config.0.nat_ip
}

output "product_output" {
  value       = var.product_version
  description = "The product_version."
}

output "sandbox_machine_name" {
  value       = "${var.sandbox_name}-${var.TFUSER}"
  description = "The product_version."
}

output "USERNAME" {
  value       = var.USERNAME
  description = "The user name."
}
