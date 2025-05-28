variable "project_id" {
  type = string
}

variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "image_version" {
  type = string
}

variable "pypi_packages" {
  type = map(string)
  default = {}
}

variable "webserver_instance_name" {
  type = string
}

variable "webserver_navbar_color" {
  type = string
  default = "#ffffff"
}

variable "webserver_navbar_hover_color" {
  type = string
  default = "#eeeeee"
}

variable "webserver_navbar_logo_text_color" {
  type = string
  default = "#51504f"
}

variable "webserver_navbar_text_color" {
  type = string
  default = "#51504f"
}

variable "webserver_navbar_text_hover_color" {
  type = string
  default = "#51504f"
}

variable "config_overrides" {
  type = map(any)
  default = {}
}

variable "env_variables" {
  type = map(string)
  default = {}
}

variable "environment_size" {
  type = string
  default = "ENVIRONMENT_SIZE_SMALL"
}

# We are using the smallest reasonable values
# See https://cloud.google.com/composer/docs/composer-2/scale-environments#limits
variable "worker_cpu" {
  type = number
  default = 0.5
}

variable "worker_memory_gb" {
  type = number
  default = 1
}

variable "worker_storage_gb" {
  type = number
  default = 1
}

variable "workers_min" {
  type = number
  default = 1
}

variable "workers_max" {
  type = number
  default = 2
}

variable "scheduler_cpu" {
  type = number
  default = 0.5
}

variable "scheduler_memory_gb" {
  type = number
  default = 1
}

variable "scheduler_storage_gb" {
  type = number
  default = 1
}

variable "scheduler_count" {
  type = number
  default = 1
}

variable "triggerer_cpu" {
  type = number
  default = 0.5
}

variable "triggerer_memory_gb" {
  type = number
  default = 1
}

variable "triggerer_count" {
  type = number
  default = 1
}

variable "webserver_cpu" {
  type = number
  default = 0.5
}

variable "webserver_memory_gb" {
  type = number
  default = 2
}

variable "webserver_storage_gb" {
  type = number
  default = 1
}

variable "webserver_allowed_source_ip_ranges" {
  type = list(string)
  default = []
}

variable "max_task_instances_per_scheduler" {
  type = number
  default = 64
}

variable "max_active_runs_per_dag" {
  type = number
  default = 8
}

variable "maintenance_window_start_time" {
  description = "The maintenance window start time"
  type = string
  default = "2025-01-01T23:00:00Z"
}

variable "maintenance_window_end_time" {
  description = "The maintenance window end time (only used for the duration calculation)"
  type = string
  default = "2025-01-02T05:00:00Z"
}

variable "maintenance_window_recurrence" {
  # See https://tools.ietf.org/html/rfc5545
  description = "The recurrence of the maintenance window in RFC-5545 'RRULE' format"
  type = string
  default = "FREQ=WEEKLY;BYDAY=SA,SU"
}

variable "publisher_service_account" {
  type = string
}

variable "connections" {
  type = list(string)
  default = []
}

variable "secret_ids" {
  type = list(string)
  default = []
}
