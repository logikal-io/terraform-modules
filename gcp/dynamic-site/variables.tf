# General variables
variable "project_id" {
  type = string
}

variable "name" {
  type = string
}

variable "name_suffix" {
  type = string
  default = null
}

# Cloud Run service variables
variable "region" {
  type = string
}

variable "domain_project_id" {
  type = string
  default = null # defaults to project_id
}

variable "domain_managed_zone_name" {
  type = string
  default = null # defaults to replace(var.domain, ".", "-")
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

variable "server_cpu" {
  type = number
  default = 1
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

variable "container_port" {
  type = number
}

variable "env" {
  type = map(string)
  default = {}
}

variable "env_secrets" {
  type = map(string)
  default = {}
}

variable "allowed_source_ip_ranges" {
  type = list(string)
  default = null
}

variable "allow_uptime_check_source_ips" {
  type = bool
  default = true
}

variable "secret_ids" {
  type = list(string)
  default = []
}

variable "publisher_service_account_email" {
  type = string
  default = null
}

# Cloud Run job variables
variable "job_command" {
  type = list(string)
  default = null # defaults to ["orb", var.name, "--command"]
}

variable "job_egress_subnetwork_id" {
  type = string
  default = null
}

# Database variables
variable "database_version" {
  type = string
}

variable "database_tier" {
  type = string
}

variable "database_availability_type" {
  type = string
}

variable "database_disk_size_gb" {
  type = number
}

variable "database_alert_cpu_threshold" {
  type = number
  default = 0.8
}

variable "database_alert_ram_threshold" {
  type = number
  default = 0.8
}

variable "database_alert_disk_threshold" {
  type = number
  default = 0.8
}

variable "database_retain_transaction_log_days" {
  type = number
  default = 7
}

variable "database_retain_backup_count" {
  type = number
  default = 30
}

variable "database_backup_start_time" {
  type = string
  default = "00:15" # 01:15 UTC+1
}

variable "database_maintenance_window_day" {
  type = number
  default = 7 # Sunday
}

variable "database_maintenance_window_hour" {
  type = number
  default = 1 # 02:00 UTC+1
}

variable "database_user_emails" {
  type = list(string)
  default = []
}

variable "database_service_users" {
  type = list(string)
  default = []
}
