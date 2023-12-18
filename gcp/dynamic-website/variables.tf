variable "project_id" {
  description = "The project ID to use"
  type = string
}

variable "domain" {
  description = "The dynamic website domain"
  type = string

  validation {
    condition = can(regex("^[a-z0-9.]+$", var.domain))
    error_message = "Only lowercase alphanumeric characters and dots are allowed in domains."
  }
}

variable "name" {
  description = "The website name to use"
  type = string
}

variable "region" {
  description = "The region in which the service should be deployed"
  type = string
}

variable "image_tag" {
  description = "The image tag to use when creating the service"
  type = string
  default = "latest"
}

variable "server_cpu" {
  description = "The number of web server vCPU cores to use"
  type = string
  default = "1"
}

variable "server_memory" {
  description = "The amount of web server memory to use"
  type = string
  default = "512Mi"
}

variable "database_tier" {
  description = "The database tier to use"
  type = string
  default = "db-custom-1-3840" # 1 vCPU and 3840 MB
}

variable "database_disk_size_gb" {
  description = "The database disk size to use"
  type = string
  default = "10"
}

variable "publisher_service_account_email" {
  description = "The email address of the website publisher service account"
  type = string
}
