terraform refresh
terraform init
ip_address=$1
p_version=$2
terraform plan -var "controlleripaddr=$1" -var "product_version=$2"
terraform apply -auto-approve -var "controlleripaddr=$1" -var "product_version=$2"


instance_ip_sandbox=$(terraform output instance_ip_sandbox)
product_output=$(terraform output product_output)
USERNAME=$(terraform output USERNAME)


FILE=/app/sandbox-$product_output.tar.gz
if [ -f "$FILE" ]; 
then
       echo "Its a new tar file"
       mkdir -p /app/$product_output
       tar xvzf $FILE -C /app/$product_output/
       cp  /app/.envcmd /app/$product_output/app/
       cp  /app/updateenv.sh /app/$product_output/app/
       cp  /app/gcp-algo-storage-credentials.json /app/$product_output/app/operator/credentials/
       cp  /app/gcp-compute-credentials.json /app/$product_output/app/operator/credentials/
       cp  /app/gcp-dataset-storage-credentials.json /app/$product_output/app/operator/credentials/
       cp  /app/gcp-dataset-storage-credentials.json /app/$product_output/app/operator/credentials/Sensoriant-gcs-data-bucket-ServiceAcct.json
       
       pushd /app/$product_output/ >> /dev/null
       tar cvzf /app/$product_output.tar.gz app/
       popd
       pushd /app/$product_output/ >> /dev/null
       tar cvzf /app/graphene-sgx-driver.tar.gz app/graphene-sgx-driver
       popd
       if test -d "/app/$product_output"; then
           rm -rf /app/$product_output
       fi
else
    tar cvzf /app/$product_output.tar.gz /app
    exit 1
fi


#tar cvf /tmp/$product_output.tar.gz /app
#tar cvf /tmp/graphene-sgx-driver.tar.gz /app/graphene-sgx-driver
rm -f privatekey_sandbox.key
terraform output tls_private_key_sandbox > privatekey_sandbox.key
chmod 600 privatekey_sandbox.key
mkdir -p /root/.ssh/
echo $instance_ip_sandbox
echo "Waiting for new Machine to start"
RET=0
timeout 180 bash -c 'until printf "" 2>>/dev/null >>/dev/tcp/$0/$1; do sleep 1; done' $instance_ip_sandbox 22 || RET=$? || true
if [ $RET -ne 0 ]; then
    echo "FAIL! Server did not start within 3 minutes"
    exit 1
else
    ssh-keyscan $instance_ip_sandbox >> /root/.ssh/known_hosts
    echo "Server is booted. It will install the application and reboot. Please wait few minutes before accessing it!"
fi
#sleep 60

#To copy the project Tar file on sandbox machine...
a=0

while [ $a -lt 10 ]
do
  scp -i privatekey_sandbox.key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null /app/$product_output.tar.gz $USERNAME@$instance_ip_sandbox:/home/$USERNAME
  EXIT_STATUS=$?
  if [ $EXIT_STATUS -eq 0 ]; then
     echo "The $product_output Tar file has been copied to the sandbox machine.."
     break
fi
  sleep 20
  a=`expr $a + 1`
done

#To copy the graphene-sgx-driver Tar file on sandbox machine...

b=0

while [ $b -lt 10 ]
do
  scp -i privatekey_sandbox.key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null /app/graphene-sgx-driver.tar.gz $USERNAME@$instance_ip_sandbox:/home/$USERNAME
  EXIT_STATUS=$?
  if [ $EXIT_STATUS -eq 0 ]; then
     echo "The graphene-sgx-driver tar file has been copied to the sandbox machine.."
     break
fi
  sleep 20
  b=`expr $b + 1`
done


