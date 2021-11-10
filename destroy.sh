docker run -it --env-file azure-credentials -e TF_VAR_TFUSER=$USER  -v $PWD:/app --rm terraform_img bash -c "/app/deploy/destroy"

