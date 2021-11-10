#!/bin/bash

terraform refresh
terraform init
terraform plan 
terraform apply -auto-approve 


instance_ip_addr=$(terraform output instance_ip_addr)
USERNAME=$(terraform output USERNAME)
admin_password=$(terraform output admin_password)

rm -f privatekey.key
terraform output tls_private_key > privatekey.key
chmod 600 privatekey.key
mkdir -p /root/.ssh/
echo "Waiting for new Machine to start"

RET=0
timeout 180 bash -c 'until printf "" 2>>/dev/null >>/dev/tcp/$0/$1; do sleep 1; done' $instance_ip_addr 22 || RET=$? || true
if [ $RET -ne 0 ]; then
    echo "FAIL! Server did not start within 3  minutes"
    exit 1
else
    ssh-keyscan $instance_ip_addr >> /root/.ssh/known_hosts
    echo "Server is booted. It will install the application and reboot. Please wait few minutes before accessing it!"
fi



