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

variable "USERNAME" {
    type = string
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

variable "product_version" {
    type = string
    description = "version name"
    
}

variable "controller_name" {
    type = string
    description = "controller name"
    default = "azure-sensoriant-controller"
}

variable "con_name_init" {
    type = string
    description = "controller name init "
    default = "pks"
}
variable "sandbox_azure_name" {
    type = string
    description = "sandbox name"
    default = "pks-sensoriant-azure-sandbox"
}
variable "sandbox_google_name" {
    type = string
    description = "sandbox name"
    default = "pks-sensoriant-google-sandbox"
}
variable "controller_skif_azurerm_resource_group" {
    type = string
    description = "controller azurerm resource group"
    default =  "safelishare-skifvm-azure"
}

variable "whitelist_mariadb_ips" {
    type = list
    description = "mariaDB whitelist IPs"
    default = ["13.72.97.58","34.86.224.5","173.48.112.27"]
}

variable "PLATFORM_PROVIDER" {
    type = string
    description = "PLATFORM_PROVIDER"
    default = ""
}
variable "SSM_TYPE" {
    type = string
    description = "SSM_TYPE"
    default = ""
}

