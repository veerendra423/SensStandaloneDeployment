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
    default =  "safelishare-client-google-adminvm-azure-resource-group"
}

variable "whitelist_mariadb_ips" {
    type = list
    description = "mariaDB whitelist IPs"
    default = ["13.72.97.58","34.86.224.5","173.48.112.27"]
}

variable "SENSOAUTH_AD_PRIMARY_DOMAIN"{
    type = string
    default = ""
}

variable "SENSOAUTH_CLIENT_ID" {
    type = string
    default = ""
}

variable "SENSOAUTH_CLIENT_SECRET" {
    type = string
    default = ""
}

variable "SENSOAUTH_TENANT_ID" {
    type = string
    default = ""
}

variable "SAFECTL_ROOT_AUTHORITY" {
    type = string
    default = ""
}

variable "SAFECTL_ROOT_CLIENT_ID" {
    type = string
    default = ""
}

variable "SAFECTL_ROOT_USERNAME" {
    type = string
    default = ""
}

variable "SAFECTL_ROOT_PASSWORD" {
    type = string
    default = ""
}

variable "SUBDOMAIN" {
    type = string
    default = ""
}


variable "SAFECTL_VERSION" {
    type = string
    default = ""
}
variable "SENSKUBEDEPLOY_VERSION" {
    type = string
    default = ""
}


variable "glocation" {
    type = string
    description = "Google zone location of terraform server environment"
    default = "us-east4"
}
variable "region_location" {
    type = string
    description = "Google region location of terraform server environment"
    default = "EU"
}

variable "controlleripaddr" {
    type = string
    description = "controller ip address"
    default = ""
}
