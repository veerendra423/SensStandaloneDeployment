#!/bin/bash
source ./.envcmd
source ./azure-credentials
AZURE_COMPUTE_CREDS_FILE=azure-credentials
GCS_COMPUTE_CREDS_FILE=gcp-compute-credentials.json
GCS_DATA_BUCKET_CREDS_FILE=gcp-bucket-storage-credentials.json
GCS_DATA_CREDS_FILE=gcp-dataset-storage-credentials.json
GCS_ALGO_CREDS_FILE=gcp-algo-storage-credentials.json
GCS_ARTIFACT_REPOSITORY_CREDS_FILE=852157164149-compute@developer.gserviceaccount.com.json
PMGR_KEY_FILE=pmgr.key

uname -r | grep -e "-azure" > /dev/null 2>&1
if [ $? -ne 0 ]; then
   echo "Please run this on an Azure machine"
   exit 1
fi
display_help()
{
        echo "----------------------------------------------------------------------"
        echo "                           --help"
        echo "----------------------------------------------------------------------"
        echo -e ""
        echo -e "./deploy.sh"
        echo -e "usage : Update the SENSORIANT_PLATFORM_PROVIDER parameter in .envcmd file\n\texample AZURE or GOOGLE "
        echo -e "usage : Update the TEE_TYPE parameter in .envcmd file\n\texample TEE_SGX for AZURE and TEE_TPM for GOOGLE"
        echo -e "usage : Update the ALGORITHM_MODE parameter in .envcmd file\n\texample hw for AZURE and sim for GOOGLE"
        echo -e "usage : Update the VERSION_NUMBER parameter in .envcmd file\n\texample VERSION_1_X_X"
        echo -e ""
        echo "----------------------------------------------------------------------"
        echo "                           --END of the help"
        echo "----------------------------------------------------------------------"
        exit 1
}

#for resource group validation of duplicates.
az account set --subscription $AZ_SUB_ID
az group list | jq '.[].name' | grep $ADMINVM_RESOURCE_GROUP-$USER
if [ $? == 0 ]; then
echo "The resource group already exists"
exit 1
else
	echo "The resource group is not available.Its creating.."
fi

if [ $CLUSTER_TYPE == "doublenode" ] || [ $CLUSTER_TYPE == "singlenode" ] ; then
echo $CLUSTER_TYPE
else
    CLUSTER_TYPE="doublenode"
    echo $CLUSTER_TYPE
fi

if [[ $MACHINE_TYPE == "adminvm" ]] && [[ $CLUSTER_PLATFORM_PROVIDER == "GOOGLE" ]] && [[ $SKIFIP == "" ]]; then
if ! test -f "$GCS_COMPUTE_CREDS_FILE"; then
       echo $GCS_COMPUTE_CREDS_FILE does not exist - try again when you have it
       exit 1
fi
if ! test -f "$GCS_DATA_BUCKET_CREDS_FILE"; then
       echo $GCS_DATA_BUCKET_CREDS_FILE does not exist - try again when you have it
       exit 1
fi
if ! test -f "$GCS_ARTIFACT_REPOSITORY_CREDS_FILE"; then
       echo $GCS_ARTIFACT_REPOSITORY_CREDS_FILE does not exist - try again when you have it
       exit 1
fi
echo "This is a google adminvm and google buckets and without skifip.Skif machine is creating..."
docker run --env-file azure-credentials -e TF_VAR_TFUSER=$USER -e TF_VAR_USERNAME=$USERNAME -e TF_VAR_controller_azurerm_resource_group=$ADMINVM_RESOURCE_GROUP -e TF_VAR_PLATFORM_PROVIDER=$SENSORIANT_PLATFORM_PROVIDER -e TF_VAR_ALGORITHM_MODE=$ALGORITHM_MODE -e TF_VAR_SSM_TYPE=$SSM_TYPE -e TF_VAR_GPU_MODE=$GPU_MODE -e TF_VAR_USERNAME=$USERNAME -e TF_VAR_AZURE_USER=$AZ_USER -e TF_VAR_AZURE_PWD=$AZ_PWD -e TF_VAR_AZURE_SUB_ID=$AZ_SUB_ID -e TF_VAR_product_version=$VERSION_NUMBER -e TF_VAR_SENSOAUTH_AD_PRIMARY_DOMAIN=$SENSOAUTH_AD_PRIMARY_DOMAIN -e TF_VAR_SENSOAUTH_CLIENT_ID=$SENSOAUTH_CLIENT_ID -e TF_VAR_SENSOAUTH_CLIENT_SECRET=$SENSOAUTH_CLIENT_SECRET -e TF_VAR_SENSOAUTH_TENANT_ID=$SENSOAUTH_TENANT_ID -e TF_VAR_SAFECTL_ROOT_AUTHORITY=$SAFECTL_ROOT_AUTHORITY -e TF_VAR_SAFECTL_ROOT_CLIENT_ID=$SAFECTL_ROOT_CLIENT_ID -e TF_VAR_SAFECTL_ROOT_USERNAME=$SAFECTL_ROOT_USERNAME -e TF_VAR_SAFECTL_ROOT_PASSWORD=$SAFECTL_ROOT_PASSWORD -e TF_VAR_SUBDOMAIN=$SUBDOMAIN -e TF_VAR_SAFECTL_VERSION=$SAFECTL_VERSION -e TF_VAR_SENSKUBEDEPLOY_VERSION=$SENSKUBEDEPLOY_VERSION -v $PWD:/app --rm terraform_img bash -c "/app/deploy/controller-run"


elif [[ $MACHINE_TYPE == "adminvm" ]] && [[ $CLUSTER_PLATFORM_PROVIDER == "GOOGLE" ]]; then
if ! test -f "$GCS_COMPUTE_CREDS_FILE"; then
       echo $GCS_COMPUTE_CREDS_FILE does not exist - try again when you have it
       exit 1
fi
if ! test -f "$GCS_DATA_BUCKET_CREDS_FILE"; then
       echo $GCS_DATA_BUCKET_CREDS_FILE does not exist - try again when you have it
       exit 1
fi
if ! test -f "$GCS_ARTIFACT_REPOSITORY_CREDS_FILE"; then
       echo $GCS_ARTIFACT_REPOSITORY_CREDS_FILE does not exist - try again when you have it
       exit 1
fi
echo "This is a google adminvm and google buckets."
docker run --env-file azure-credentials -e TF_VAR_TFUSER=$USER -e TF_VAR_controller_azurerm_resource_group=$ADMINVM_RESOURCE_GROUP -e TF_VAR_USERNAME=$USERNAME -e TF_VAR_AZURE_USER=$AZ_USER -e TF_VAR_AZURE_PWD=$AZ_PWD -e TF_VAR_AZURE_SUB_ID=$AZ_SUB_ID -e TF_VAR_product_version=$VERSION_NUMBER -e TF_VAR_SENSOAUTH_AD_PRIMARY_DOMAIN=$SENSOAUTH_AD_PRIMARY_DOMAIN -e TF_VAR_SENSOAUTH_CLIENT_ID=$SENSOAUTH_CLIENT_ID -e TF_VAR_SENSOAUTH_CLIENT_SECRET=$SENSOAUTH_CLIENT_SECRET -e TF_VAR_SENSOAUTH_TENANT_ID=$SENSOAUTH_TENANT_ID -e TF_VAR_SAFECTL_ROOT_AUTHORITY=$SAFECTL_ROOT_AUTHORITY -e TF_VAR_SAFECTL_ROOT_CLIENT_ID=$SAFECTL_ROOT_CLIENT_ID -e TF_VAR_SAFECTL_ROOT_USERNAME=$SAFECTL_ROOT_USERNAME -e TF_VAR_SAFECTL_ROOT_PASSWORD=$SAFECTL_ROOT_PASSWORD -e TF_VAR_SUBDOMAIN=$SUBDOMAIN -e TF_VAR_SAFECTL_VERSION=$SAFECTL_VERSION -e TF_VAR_SENSKUBEDEPLOY_VERSION=$SENSKUBEDEPLOY_VERSION -v $PWD:/app --rm terraform_img bash -c "/app/deploy/client-google-run"

elif [[ $MACHINE_TYPE == "adminvm" ]] && [[ $CLUSTER_PLATFORM_PROVIDER == "AZURE" ]]; then
echo "This is a azure adminvm and azure buckets."
if ! test -f "$GCS_DATA_BUCKET_CREDS_FILE"; then
       echo $GCS_DATA_BUCKET_CREDS_FILE does not exist - try again when you have it
       exit 1
fi
docker run --env-file azure-credentials -e TF_VAR_TFUSER=$USER -e TF_VAR_controller_azurerm_resource_group=$ADMINVM_RESOURCE_GROUP -e TF_VAR_USERNAME=$USERNAME -e TF_VAR_AZURE_USER=$AZ_USER -e TF_VAR_AZURE_PWD=$AZ_PWD -e TF_VAR_AZURE_SUB_ID=$AZ_SUB_ID -e TF_VAR_product_version=$VERSION_NUMBER -e TF_VAR_SENSOAUTH_AD_PRIMARY_DOMAIN=$SENSOAUTH_AD_PRIMARY_DOMAIN -e TF_VAR_SENSOAUTH_CLIENT_ID=$SENSOAUTH_CLIENT_ID -e TF_VAR_SENSOAUTH_CLIENT_SECRET=$SENSOAUTH_CLIENT_SECRET -e TF_VAR_SENSOAUTH_TENANT_ID=$SENSOAUTH_TENANT_ID -e TF_VAR_SAFECTL_ROOT_AUTHORITY=$SAFECTL_ROOT_AUTHORITY -e TF_VAR_SAFECTL_ROOT_CLIENT_ID=$SAFECTL_ROOT_CLIENT_ID -e TF_VAR_SAFECTL_ROOT_USERNAME=$SAFECTL_ROOT_USERNAME -e TF_VAR_SAFECTL_ROOT_PASSWORD=$SAFECTL_ROOT_PASSWORD -e TF_VAR_SUBDOMAIN=$SUBDOMAIN -e TF_VAR_SAFECTL_VERSION=$SAFECTL_VERSION -e TF_VAR_SENSKUBEDEPLOY_VERSION=$SENSKUBEDEPLOY_VERSION -v $PWD:/app --rm terraform_img bash -c "/app/deploy/client-run"

else

if [ "$1" == "-h" ] || [ "$1" == "--help" ] ;
then
        display_help
fi
#If username is not provided in the .envcmd file,By default username will be sensuser.
if [ $USERNAME == "REPLACE_WITH_USERNAME" ]; then
    USERNAME="sensuser"
fi




if [ $SENSORIANT_PLATFORM_PROVIDER == "REPLACE_WITH_PLATFORM_PROVIDER" ];
then
        echo "Please provide the (SENSORIANT_PLATFORM_PROVIDER) parameter in .envcmd file "
        exit 1
else
        if [ $SENSORIANT_PLATFORM_PROVIDER  == "AZURE" ] || [ $SENSORIANT_PLATFORM_PROVIDER  == "GOOGLE" ];
        then
            if [ $SENSORIANT_PLATFORM_PROVIDER == "AZURE" ];
            then
                if [ $GPU_MODE == "true" ];
                then
                    echo "Azure GPU_MODE was not supported"
                    echo "Please update GPU_MODE parameter in .envcmd file"
                    exit 1
                fi
            fi
        else
                echo "invalid platform provider use help"
                echo "Please provide the (SENSORIANT_PLATFORM_PROVIDER) parameter in .envcmd file "
                display_help
                exit 1
        fi
fi

if [ $TEE_TYPE == "REPLACE_WITH_TEE_TYPE" ];
then
        echo "Please provide the (TEE_TYPE) parameter in .envcmd file"
        exit 1
else
        if [ $TEE_TYPE == "TEE_SGX" ] || [ $TEE_TYPE == "TEE_TPM" ];
        then
                if [ $SENSORIANT_PLATFORM_PROVIDER == "AZURE" ] && ([ $TEE_TYPE == "TEE_SGX" ] || [ $TEE_TYPE == "TEE_TPM" ]);
                then
                        echo "$TEE_TYPE"
                elif [ $SENSORIANT_PLATFORM_PROVIDER == "GOOGLE" ] && [ $TEE_TYPE == "TEE_TPM" ];
                then
                        echo "$TEE_TYPE"
                else
                        echo "platform provider and tee_type are not matching"
                        echo "please provide valid TEE_TYPE for SENSORIANT_PLATFORM_PROVIDER"
                        display_help
                        exit 1
                fi
        else
                echo "please provide the valid TEE_TYPE"
                display_help
                exit 1
        fi
fi

if [ $ALGORITHM_MODE == "REPLACE_WITH_ALGORITHM_MODE" ];
then
        echo "Please provide the (ALGORITHM_MODE) parameter in .envcmd file"
        exit 1
else
        if [ $SENSORIANT_PLATFORM_PROVIDER == "AZURE" ] && [ $TEE_TYPE == "TEE_SGX" ] && [ $ALGORITHM_MODE == "hw" ];
           then
                echo "$ALGORITHM_MODE"
        elif [ $SENSORIANT_PLATFORM_PROVIDER == "AZURE" ] && [ $TEE_TYPE == "TEE_TPM" ] && [ $ALGORITHM_MODE == "sim" ];
           then
                echo "$ALGORITHM_MODE"
        elif ([ $SENSORIANT_PLATFORM_PROVIDER == "GOOGLE" ] && [ $GPU_MODE == "true" ]) && ([ $ALGORITHM_MODE == "sim" ] || [ $ALGORITHM_MODE == "gpu" ]);
        then
                echo "$ALGORITHM_MODE"
        elif ([ $SENSORIANT_PLATFORM_PROVIDER == "GOOGLE" ] && [ $GPU_MODE == "false" ]) && [ $ALGORITHM_MODE == "sim" ];
        then
                echo "$ALGORITHM_MODE"
        else
                echo "platform provider and algorithm mode are not matching"
                echo "please provide valid ALGORITHM_MODE for SENSORIANT_PLATFORM_PROVIDER"
                display_help
                exit 1
        fi
fi

RELPREFIX="VERSION"

check_target_arg()
{
    TARGET=$VERSION_NUMBER
    VER_REGEX="${RELPREFIX}_[[:digit:]]{1,}(.[[:digit:]]{1,}){1,}"
    if echo ${TARGET} | egrep "^${VER_REGEX}" >/dev/null
    then
            echo "$VERSION_NUMBER"
    else
            echo "version format should be $VER_REGEX"
            display_help
            exit 1
    fi
}

if [ $VERSION_NUMBER == "REPLACE_WITH_VERSION_NUMBER" ];
then
        echo "Please provide the (VERSION Number) parameter in .envcmd file"
        exit 1
else
        check_target_arg $SENSORIANT_PLATFORM_PROVIDER $TEE_TYPE $VERSION_NUMBER
        SENS_CONTROLLER_SOURCE=controller-"$VERSION_NUMBER".tar.gz
        SENS_SANDBOX_SOURCE=sandbox-"$VERSION_NUMBER".tar.gz
fi

#if deployment equal to controller and ssm type equal to true then needed only azure credentials.
if [ $DEPLOYMENT == "controller" ] && [ $SSM_TYPE == "true" ];
then

if ! test -f "$AZURE_COMPUTE_CREDS_FILE"; then
       echo $AZURE_COMPUTE_CREDS_FILE does not exist - try again when you have it
       exit 1
fi

if [  "$(grep "Your azure login" $AZURE_COMPUTE_CREDS_FILE)" ]; then
       echo $AZURE_COMPUTE_CREDS_FILE needs to be updated - try again when you have it
       exit 1
fi
else
if ! test -f "$AZURE_COMPUTE_CREDS_FILE"; then
       echo $AZURE_COMPUTE_CREDS_FILE does not exist - try again when you have it
       exit 1
fi

if [  "$(grep "Your azure login" $AZURE_COMPUTE_CREDS_FILE)" ]; then
       echo $AZURE_COMPUTE_CREDS_FILE needs to be updated - try again when you have it
       exit 1
fi

if ! test -f "$GCS_COMPUTE_CREDS_FILE"; then
       echo $GCS_COMPUTE_CREDS_FILE does not exist - try again when you have it
       exit 1
fi

if ! test -f "$GCS_DATA_CREDS_FILE"; then
       echo $GCS_DATA_CREDS_FILE does not exist - try again when you have it
       exit 1
fi

if ! test -f "$GCS_ALGO_CREDS_FILE"; then
       echo $GCS_ALGO_CREDS_FILE does not exist - try again when you have it
       exit 1
fi

if ! test -f "$PMGR_KEY_FILE"; then
       echo $PMGR_KEY_FILE does not exist - try again when you have it
       exit 1
fi
fi


#if deployment equal to controller and ssm type equal to true then  controller tar validation will not ask
if [ $DEPLOYMENT == "controller" ] && [ $SSM_TYPE == "true" ];
then
echo 'Its an ssm tye machine with controller.'
else
if ! test -f "$SENS_CONTROLLER_SOURCE"; then
       echo $SENS_CONTROLLER_SOURCE does not exist -
       echo $SENS_CONTROLLER_SOURCE tar file needs to be copy to main directory
       echo try again when you have it
       exit 1
fi

if ! test -f "$SENS_SANDBOX_SOURCE"; then
       echo $SENS_SANDBOX_SOURCE does not exist -
       echo $SENS_SANDBOX_SOURCE tar file needs to be copy to main directory
       echo try again when you have it
       exit 1
fi
fi


pushd deploy > /dev/null

if [ !  "$(docker build -t terraform_img .)" ]; then
       echo Error creating terraform docker
       exit 1
fi

popd > /dev/null
echo "we are deploying $SENSORIANT_PLATFORM_PROVIDER machine with $TEE_TYPE setup for $VERSION_NUMBER"

if [ $DEPLOYMENT == "controller" ] && [ $SSM_TYPE == "true" ];
then
echo 'controller'
        docker run --env-file azure-credentials -e TF_VAR_TFUSER=$USER -e TF_VAR_USERNAME=$USERNAME -e TF_VAR_PLATFORM_PROVIDER=$SENSORIANT_PLATFORM_PROVIDER -e TF_VAR_ALGORITHM_MODE=$ALGORITHM_MODE -e TF_VAR_SSM_TYPE=$SSM_TYPE -e TF_VAR_GPU_MODE=$GPU_MODE -v $PWD:/app --rm terraform_img bash -c "/app/deploy/controller-run"
else
echo 'sandbox'
    #echo Please change the deployment to controller in .envcmd file..
     docker run --env-file azure-credentials -e TF_VAR_TFUSER=$USER -e TF_VAR_USERNAME=$USERNAME -e TF_VAR_PLATFORM_PROVIDER=$SENSORIANT_PLATFORM_PROVIDER -e TF_VAR_ALGORITHM_MODE=$ALGORITHM_MODE -e TF_VAR_GPU_MODE=$GPU_MODE -v $PWD:/app --rm terraform_img bash -c "/app/deploy/run"
fi
fi