variable "project_id" {
  type = string
}

variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "domain_project_id" {
  type = string
  default = null
}

variable "domain_managed_zone_name" {
  type = string
}

variable "domain" {
  type = string

  validation {
    condition = can(regex("^[a-z0-9-.]+$", var.domain))
    error_message = (
    "Only lowercase alphanumeric characters, dashes and dots are allowed in domains."
    )
  }
}

variable "www_redirect" {
  type = bool
  default = false
}

variable "alert_notification_channel_ids" {
  type = list(string)
}

variable "alert_severity" {
  type = string
  default = "ERROR"
}

variable "availability_slo_goal" {
  type = number
  default = 0.995
}

variable "alert_latency_threshold_ms" {
  type = number
  default = 10 * 1000
}

variable "alert_cpu_threshold" {
  type = number
  default = 0.8
}

variable "alert_ram_threshold" {
  type = number
  default = 0.8
}

variable "server_cpu" {
  type = string
  default = "1"
}

variable "server_memory" {
  type = string
  default = "512Mi"
}

variable "min_instances" {
  type = number
  default = 1
}

variable "max_instances" {
  type = number
  default = 2
}

variable "image" {
  type = string
  default = null
}

variable "image_version" {
  type = string
  default = "latest"
}

variable "container_port" {
  type = number
}

variable "startup_probe_period_seconds" {
  type = number
  default = 10
}

variable "startup_probe_initial_delay_seconds" {
  type = number
  default = 0
}

variable "startup_probe_failure_threshold" {
  type = number
  default = 3
}

variable "startup_probe_timeout_seconds" {
  type = number
  default = 3
}

variable "liveness_probe_failure_threshold" {
  type = number
  default = 3
}

variable "liveness_probe_timeout_seconds" {
  type = number
  default = 3
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

variable "allowed_source_ip_ranges" {
  type = list(string)
  default = null
}

variable "allow_uptime_check_source_ips" {
  type = bool
  default = true
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
