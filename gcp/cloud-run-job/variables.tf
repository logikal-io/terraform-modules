variable "project_id" {
  type = string
}

variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "server_cpu" {
  type = string
  default = "1"
}

variable "server_memory" {
  type = string
  default = "512Mi"
}

variable "image" {
  type = string
  default = null
}

variable "image_name" {
  type = string
  default = null
}

variable "image_version" {
  type = string
  default = null
}

variable "env" {
  type = map(string)
  default = {}
}

variable "env_secrets" {
  type = map(string)
  default = {}
}

variable "egress_subnetwork_id" {
  type = string
  default = null
}

variable "command" {
  type = list(string)
  default = null
}

variable "args" {
  type = list(string)
  default = null
}

variable "service_account_email" {
  type = string
  default = null
}

variable "cloud_sql_instances" {
  type = list(object({
    name = string
    connection_name = string
  }))
  default = []
}

variable "secret_ids" {
  type = list(string)
  default = []
}

variable "publisher_service_account_email" {
  type = string
  default = null
}
