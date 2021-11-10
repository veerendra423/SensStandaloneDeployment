#!/bin/bash
apt update
sudo apt-get install jq -y
apt install make gcc apt-transport-https ca-certificates curl jq software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg |  apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt update																			   
apt-cache policy docker-ce
apt install docker-ce python3 python3-pip -y
curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-Linux-x86_64" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
git clone https://github.com/PrefectHQ/prefect.git
git clone https://github.com/oscarlab/graphene-sgx-driver.git
mkdir -p "/lib/modules/"`uname -r`"/kernel/drivers/intel/sgx"   
cd /graphene-sgx-driver
export ISGX_DRIVER_PATH=/graphene-sgx-driver
ISGX_DRIVER_PATH=/graphene-sgx-driver make
cp gsgx.ko "/lib/modules/"`uname -r`"/kernel/drivers/intel/sgx"
#sh -c "cat /etc/modules | grep -Fxq gsgx || echo gsgx >> /etc/modules"
#/sbin/depmod
#/sbin/modprobe gsgx
FILE=/home/nference/${var.product_version}.tar.gz
until [ -f $FILE ]
do
sleep 10
done
#MY_MESSAGE3=${var.product_version}
#echo $MY_MESSAGE3 >> /tmp/hel.log
#MY_MESSAGE2 =/opt/$MY_MESSAGE
#sudo mkdir -p /opt/$MY_MESSAGE
#sudo mkdir -p /home/nference/$MY_MESSAGE
MY_MESSAGE1=${var.product_version}
echo $MY_MESSAGE1 >> /tmp/hello.log
MY_MESSAGE=/opt/$MY_MESSAGE1
echo $MY_MESSAGE
echo $MY_MESSAGE >> /tmp/hel.log
sudo mkdir -p $MY_MESSAGE
sudo tar xvf /home/nference/${var.product_version}.tar.gz -C /opt/${var.product_version}
#sudo tar xvf /home/nference/v1_0_0.tar.gz -C /opt/v1_0_0
docker network create sensnet
docker login -u ${var.docker_user} -p ${var.docker_pwd} ${var.docker_registry}
groupadd docker
usermod -aG docker nference
docker login -u ${var.docker_user} -p ${var.docker_pwd} ${var.docker_registry}
mkdir -p /home/nference/.docker
cp /root/.docker/config.json /home/nference/.docker/
chown -R nference:nference /home/nference/.docker
chown -R nference:nference /opt/${var.product_version}										
