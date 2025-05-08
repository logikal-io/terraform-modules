variable "project" {
  description = "The project to use"
  type = string
}

variable "project_id" {
  description = "The project ID to use"
  type = string
}

variable "domain" {
  description = "The service domain"
  type = string

  validation {
    condition = can(regex("^[a-z0-9-.]+$", var.domain))
    error_message = (
      "Only lowercase alphanumeric characters, dashes and dots are allowed in domains."
    )
  }
}

variable "name" {
  description = "The service name to use"
  type = string
}

variable "region" {
  description = "The region in which the service should be deployed"
  type = string
}

variable "server_cpu" {
  description = "The number of server vCPU cores to use"
  type = string
  default = "1"
}

variable "server_memory" {
  description = "The amount of server memory to use"
  type = string
  default = "512Mi"
}

variable "min_instances" {
  description = "The number of minimum server instances"
  type = number
  default = 1
}

variable "max_instances" {
  description = "The number of maximum server instances"
  type = number
  default = 2
}

variable "image" {
  description = "The image to use"
  type = string
}

variable "cloud_sql_instances" {
  description = "The Cloud SQL instances to mount into the service container"
  type = list(string)
  default = []
}

variable "container_port" {
  description = "The container port to use"
  type = number
}

variable "env" {
  description = "The environment variables to set"
  type = map(string)
}

variable "security_policy" {
  description = "The security policy ID to use"
  type = string
}

variable "publisher_service_account" {
  description = "The publisher service account email address to use"
  type = string
}
