variable "location" {
    type = string
    description = "Azure location of terraform server environment"
    default = "eastus"
}

variable "docker_user" {
    type = string
    description = "Docker user used to login"
    default = "bb3fd7f0-72e4-4d76-ace4-b17582cc1993"
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
    default = "mHhFNKgo-Bp2sY9pylu~ayLSMCPJuV3S1r"
}

variable "docker_registry" {
    type = string
    description = "Docker registry to login into"
    default = "sensoriant.azurecr.io"
}

variable "product_version" {
    type = string
    description = "version name"
    default = ""
}

variable "sandbox_name" {
    type = string
    description = "sandbox name"
    default = "pks-sensoriant-azure-sandbox"
}

variable "controlleripaddr" {
    type = string
    description = "controller ip address"
    default = ""
}

variable "sandbox_azurerm_resource_group" {
    type = string
    description = "sandbox azurerm resource group"
    default =  "sens-azure-sandbox-resource-group-test"
}

variable "PLATFORM_PROVIDER" {
    type = string
    description = "PLATFORM_PROVIDER"
    default = ""
}

variable "ALGORITHM_MODE" {
    type = string
    description = "ALGORITHM_MODE"
    default = ""
}

