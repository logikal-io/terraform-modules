variable "project_id" {
  type = string
}

variable "name" {
  type = string
}

variable "database_version" {
  type = string
}

variable "tier" {
  type = string
}

variable "availability_type" {
  type = string
}

variable "disk_size_gb" {
  type = number
}

variable "alert_notification_channel_ids" {
  type = list(string)
}

variable "alert_severity" {
  type = string
}

variable "alert_cpu_threshold" {
  type = number
  default = 0.8
}

variable "alert_ram_threshold" {
  type = number
  default = 0.8
}

variable "alert_disk_threshold" {
  type = number
  default = 0.8
}

variable "retain_transaction_log_days" {
  type = number
  default = 7
}

variable "retain_backup_count" {
  type = number
  default = 7
}

variable "backup_start_time" {
  type = string
  default = "00:15" # 01:15 UTC+1
}

variable "maintenance_window_day" {
  type = number
  default = 7 # Sunday
}

variable "maintenance_window_hour" {
  type = number
  default = 1 # 02:00 UTC+1
}

variable "users" {
  type = list(string)
  default = []
}
