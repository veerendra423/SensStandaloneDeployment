docker-compose -f /opt/$1/app/operator/docker-compose.yml --project-directory /opt/$1/app/operator stop cas
docker-compose -f /opt/$1/app/operator/docker-compose.yml --project-directory /opt/$1/app/operator stop secure_cloud_api_container
docker-compose -f /opt/$1/app/operator/docker-compose.yml --project-directory /opt/$1/app/operator stop docker_registry_api_container
docker-compose -f /opt/$1/app/operator/docker-compose.yml --project-directory /opt/$1/app/operator stop sens-mariadb
docker-compose -f /opt/$1/app/operator/docker-compose.yml --project-directory /opt/$1/app/operator stop nginx
docker-compose -f /opt/$1/app/operator/docker-compose.yml --project-directory /opt/$1/app/operator stop ras_server
docker-compose -f /opt/$1/app/operator/docker-compose.yml --project-directory /opt/$1/app/operator stop senscli

