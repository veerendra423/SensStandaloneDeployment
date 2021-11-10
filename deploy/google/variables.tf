variable "location" {
    type = string
    description = "Google zone location of terraform server environment"
    default = "us-east4-b"
}
variable "region_location" {
    type = string
    description = "Google region location of terraform server environment"
    default = "us-east4"
}

variable "machine_CPU" {
    type = string
    description = "Google machine type"
    default = "e2-standard-8"
}

variable "machine_GPU" {
    type = string
    description = "Google machine type"
    default = "n1-standard-8"
}

variable "GPU_MODE" {
    type = string
    description = "gpu mode"
    default = ""
}

variable "gpu_type" {
    type = string
    description = "gpu machine type"
    default = "nvidia-tesla-p4"
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
  
}

variable "sandbox_name" {
    type = string
    description = "sandbox name"
    default = "pks-sensoriant-google-sandbox"
}
variable "controlleripaddr" {
    type = string
    description = "controller ip address"
    default = ""
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
