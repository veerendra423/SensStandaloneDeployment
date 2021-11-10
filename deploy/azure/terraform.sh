#!/bin/bash
source /app/.envcmd

terraform refresh
terraform init
p_version=$1
terraform plan -var "product_version=$1"
terraform apply -auto-approve -var "product_version=$1"



instance_ip_addr=$(terraform output instance_ip_addr)
product_output=$(terraform output product_output)
USERNAME=$(terraform output USERNAME)

if [[ $DEPLOYMENT == "controller" ]];
then 
echo 'This is a controller machine.'
else
FILE=/app/controller-$product_output.tar.gz
if [ -f "$FILE" ];
then
       mkdir -p /app/$product_output
       tar xvzf $FILE -C /app/$product_output/
       cp  /app/.envcmd /app/$product_output/app/
       cp  /app/envoverride /app/$product_output/app/
       cp  /app/updateenv.sh /app/$product_output/app/
       cp  /app/gcp-algo-storage-credentials.json /app/$product_output/app/operator/credentials/
       cp  /app/gcp-compute-credentials.json /app/$product_output/app/operator/credentials/
       cp  /app/gcp-dataset-storage-credentials.json /app/$product_output/app/operator/credentials/
       cp  /app/gcp-dataset-storage-credentials.json /app/$product_output/app/operator/credentials/Sensoriant-gcs-data-bucket-ServiceAcct.json
       cp  /app/pmgr.key /app/$product_output/app/operator/credentials/  
       pushd /app/$product_output/ >> /dev/null
       tar cvzf /app/$product_output.tar.gz app/
       popd
       if test -d "/app/$product_output"; then
           rm -rf /app/$product_output
       fi
else
    tar cvzf /app/$product_output.tar.gz /app
    exit 1
fi
fi

#tar cvf /tmp/$product_output.tar.gz /app
rm -f privatekey.key
terraform output tls_private_key > privatekey.key
terraform output tls_private_key > privatekeynew.key
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


#To copy the project tar file on azzure machine...
if [ $DEPLOYMENT == "controller" ];
then 
echo 'This is a controller machine.'
else
a=0
while [ $a -lt 10 ]
do
  scp -i privatekey.key /app/$product_output.tar.gz $USERNAME@$instance_ip_addr:/home/$USERNAME
  EXIT_STATUS=$?
  if [ $EXIT_STATUS -eq 0 ]; then
     echo "The project tar has been copied to the azzure machine.."
     break
  fi  
  sleep 10
  a=`expr $a + 1`
done
fi

