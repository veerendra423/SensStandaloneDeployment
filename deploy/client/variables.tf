variable "location" {
    type = string
    description = "Azure location of terraform server environment"
    default = "eastus"
}

variable "docker_user" {
    type = string
    description = "Docker user used to login"
    default = "sensoriant"
}
variable "TFUSER" {
    type = string
}

variable "AZURE_USER" {
    type = string
}


variable "AZURE_PWD" {
    type = string
}


variable "AZURE_SUB_ID" {
    type = string
}

variable "product_version" {
    type = string
    description = "version name"
    
}


variable "USERNAME" {
    type = string
    default = "sensuser"
}

variable "docker_pwd" {
    type = string
    description = "Docker password used to login"
    default = "bWHet0pvl/ul13WidHMyY4kLZxi+=eO5"
}

variable "docker_registry" {
    type = string
    description = "Docker registry to login into"
    default = "sensoriant.azurecr.io"
}



variable "controller_name" {
    type = string
    description = "controller name"
    default = "safectl-machine"
}

variable "con_name_init" {
    type = string
    description = "controller name init "
    default = "sm"
}

variable "controller_azurerm_resource_group" {
    type = string
    description = "controller azurerm resource group"
}

variable "whitelist_mariadb_ips" {
    type = list
    description = "mariaDB whitelist IPs"
    default = ["13.72.97.58","34.86.224.5","173.48.112.27"]
}

variable "SENSOAUTH_AD_PRIMARY_DOMAIN"{
    type = string
}

variable "SENSOAUTH_CLIENT_ID" {
    type = string
}

variable "SENSOAUTH_CLIENT_SECRET" {
    type = string
}

variable "SENSOAUTH_TENANT_ID" {
    type = string
}

variable "SAFECTL_ROOT_AUTHORITY" {
    type = string
}

variable "SAFECTL_ROOT_CLIENT_ID" {
    type = string
}

variable "SAFECTL_ROOT_USERNAME" {
    type = string
}

variable "SAFECTL_ROOT_PASSWORD" {
    type = string
}

variable "SUBDOMAIN" {
    type = string
}


variable "SAFECTL_VERSION" {
    type = string
}
variable "SENSKUBEDEPLOY_VERSION" {
    type = string
}

