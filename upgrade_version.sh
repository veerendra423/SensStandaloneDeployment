#!/bin/bash

if [ -z "$1" ]; then
    echo "Missing machine type controller or sandbox?"
    exit 1
fi

if [ -z "$2" ]; then
    echo "Missing Version to upgrade FROM"
    exit 1
fi

if [ -z "$3" ]; then
    echo "Missing  Version to upgrade TO"
    exit 1
fi

if [ -z "$4" ]; then
    echo "Missing username"
    exit 1
fi

source ./.env

replace_var()
{
        rc=`grep "^$1=" $3`
        if [ -z "$rc" ]; then
                echo $1=$2 >> $3
        else
              sudo sed "\|^$1|s|=.*$|=$2|1" $3 > t
               sudo  mv t $3
        fi
}

machine_type=$1
from_version=$2
to_version=$3
username=$4

if ! test -f "$1-$3.tar.gz"; then
    echo "File ($1) doesn't exist!"
    exit 1
fi


#If You want to change the product version on controller machine and update it to latest one.
if [[ $machine_type == 'controller' ]]; then
    sudo mkdir /opt/$to_version
    sudo tar xvzf /opt/$from_version/app/$1-$to_version.tar.gz --no-same-owner -C /opt/$to_version/
    cd /opt/$to_version/app
    sudo chown -R $username:$username ../app


    SANDBOX_HOSTNAME=`cat /opt/$from_version/app/.env | grep -w ^NO_KUBE_SANDBOX | awk -F '=' '{ print substr($2,2,length($2)-2)}'`
    CONTROLLER_IP=`cat /opt/$from_version/app/.env | grep -w SENSORIANT_SPIRE_SERVER_HOSTNAME | awk -F '=' '{ print substr($2,2,length($2)-2)}'`
    #SECURE_CLOUD_API_GCS_BUCKET_NAME=`cat /opt/$from_version/app/.env | grep -w SECURE_CLOUD_API_GCS_BUCKET_NAME | awk -F '=' '{ print $2}'`
    GCS_BUCKET_NAME=`cat /opt/$from_version/app/.env | grep -w ^GCS_BUCKET_NAME | awk -F '=' '{ print $2}'`
    SCLI_DREG=`cat /opt/$from_version/app/.env | grep -w SENSCLI_DREG | awk -F '=' '{ print $2}'`
    SCLI_DCRED=`cat /opt/$from_version/app/.env | grep -w SENSCLI_DCRED | awk -F '=' '{ print $2}'`
    SECURE_CLOUD_API_SANDBOX_USERNAME=`cat /opt/$from_version/app/.env | grep -w SECURE_CLOUD_API_SANDBOX_USERNAME | awk -F '=' '{ print $2}'`

    sudo sed -i 's/REPLACE_WITH_SANDBOX_NAME/'"${SANDBOX_HOSTNAME}"'/g' /opt/${to_version}/app/.env
    sudo sed -i 's/REPLACE_WITH_CONTROLLER_IP/'"${CONTROLLER_IP}"'/g' /opt/${to_version}/app/.env
    sudo sed -i 's/REPLACE_WITH_USER_NAME/'"${username}"'/g' /opt/${to_version}/app/.env

    #Replace bucket name with the value from the from_version
    replace_var SECURE_CLOUD_API_GCS_BUCKET_NAME ${GCS_BUCKET_NAME} /opt/${to_version}/app/.env
    replace_var GCS_BUCKET_NAME ${GCS_BUCKET_NAME} /opt/${to_version}/app/.env
    replace_var SENSCLI_DREG ${SCLI_DREG} /opt/${to_version}/app/.env
    replace_var SENSCLI_DCRED ${SCLI_DCRED} /opt/${to_version}/app/.env
    replace_var SECURE_CLOUD_API_SANDBOX_USERNAME ${SECURE_CLOUD_API_SANDBOX_USERNAME} /opt/${to_version}/app/.env

    #copy credentials from old version

    sudo cp /opt/$from_version/app/operator/credentials/* /opt/$to_version/app/operator/credentials/
    sudo chown -R $username:$username  /opt/$to_version/app/operator/credentials/*
    sudo cp /opt/$from_version/app/keys/*.json /opt/$to_version/app/keys/ >> /dev/null

    pushd /opt/$from_version/app/operator >> /dev/null
    docker-compose down
    popd >> /dev/null

    pushd /opt/$to_version/app/
    ./start.sh $to_version
    sudo sed -i 's/'"$from_version"'/'"$to_version"'/g'  /etc/crontab

fi

#If You want to change the product version on sandbox machine and update it to latest one.
if [[ $machine_type == 'sandbox' ]]; then
    if [ $USE_PREFECT == "true" ];
    then
	    sudo killall -9 prefect
	    echo "previous prefect agent killed"
    fi
    sudo mkdir /opt/$to_version
    sudo tar xvzf /opt/$from_version/app/$1-$to_version.tar.gz --no-same-owner -C /opt/$to_version/
    cd /opt/$to_version/app
    sudo chown -R $username:$username ../app

    SANDBOX_HOSTNAME=`cat /opt/$from_version/app/.env | grep -w ^NO_KUBE_SANDBOX | awk -F '=' '{ print substr($2,2,length($2)-2)}'`
    CONTROLLER_IP=`cat /opt/$from_version/app/.env | grep -w SENSORIANT_SPIRE_SERVER_HOSTNAME | awk -F '=' '{ print substr($2,2,length($2)-2)}'`
    GCS_BUCKET_NAME=`cat /opt/$from_version/app/.env | grep -w ^GCS_BUCKET_NAME | awk -F '=' '{ print $2}'`
    SCLI_DREG=`cat /opt/$from_version/app/.env | grep -w SENSCLI_DREG | awk -F '=' '{ print $2}'`
    SCLI_DCRED=`cat /opt/$from_version/app/.env | grep -w SENSCLI_DCRED | awk -F '=' '{ print $2}'`
    PLATFORM_PROVIDER=`cat /opt/$from_version/app/.env | grep -w SENSORIANT_PLATFORM_PROVIDER | awk -F '=' '{ print substr($2,2,length($2)-2)}'`
    ALGORITHM_MODE=`cat /opt/$from_version/app/.env | grep -w ALGORITHM_MODE | awk -F '=' '{ print substr($2,2,length($2)-2)}'`
    SECURE_CLOUD_API_SANDBOX_USERNAME=`cat /opt/$from_version/app/.env | grep -w SECURE_CLOUD_API_SANDBOX_USERNAME | awk -F '=' '{ print $2}'`

    sed -i 's/REPLACE_WITH_SANDBOX_NAME/'"${SANDBOX_HOSTNAME}"'/g' /opt/${to_version}/app/.env
    sed -i 's/REPLACE_WITH_CONTROLLER_IP/'"${CONTROLLER_IP}"'/g' /opt/${to_version}/app/.env
    sed -i 's/REPLACE_WITH_USER_NAME/'"${username}"'/g' /opt/${to_version}/app/.env

    OUTPUT=$(lsmod | grep intel_sgx)
    echo "${OUTPUT}"
    if [ ! -n "$OUTPUT" ] ;
    then
    sed -i 's/REPLACE_WITH_PLATFORM_PROVIDER/'${PLATFORM_PROVIDER}'/g' /opt/${to_version}/app/.env
    sed -i 's/REPLACE_WITH_ALGORITHM_MODE/'${ALGORITHM_MODE}'/g' /opt/${to_version}/app/.env
    else
    sed -i 's/REPLACE_WITH_PLATFORM_PROVIDER/'${PLATFORM_PROVIDER}'/g' /opt/${to_version}/app/.env
    sed -i 's/REPLACE_WITH_ALGORITHM_MODE/'${ALGORITHM_MODE}'/g' /opt/${to_version}/app/.env
    fi ;


    #Replace bucket name with the value from the from_version
    replace_var SECURE_CLOUD_API_GCS_BUCKET_NAME ${GCS_BUCKET_NAME} /opt/${to_version}/app/.env
    replace_var GCS_BUCKET_NAME ${GCS_BUCKET_NAME} /opt/${to_version}/app/.env
    replace_var SENSCLI_DREG ${SCLI_DREG} /opt/${to_version}/app/.env
    replace_var SENSCLI_DCRED ${SCLI_DCRED} /opt/${to_version}/app/.env
    replace_var SECURE_CLOUD_API_SANDBOX_USERNAME ${SECURE_CLOUD_API_SANDBOX_USERNAME} /opt/${to_version}/app/.env

    #copy credentials from old version
    sudo cp /opt/$from_version/app/operator/credentials/* /opt/$to_version/app/operator/credentials/
    sudo chown -R $username:$username  /opt/$to_version/app/operator/credentials/*
    sudo cp /opt/$from_version/app/keys/*.json /opt/$to_version/app/keys/

    pushd /opt/$from_version/app/operator >> /dev/null
    docker-compose down
    popd >> /dev/null

    pushd /opt/$to_version/app/
    ./start_sandbox_setup.sh $to_version
    sudo sed -i 's/'"$from_version"'/'"$to_version"'/g'  /etc/crontab
fi
