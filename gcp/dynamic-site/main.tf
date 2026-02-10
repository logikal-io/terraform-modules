terraform {
  required_version = "~> 1.0"
  required_providers {
    random = {
      source = "hashicorp/random"
      version = "~> 3.7"
    }
    google = {
      source = "hashicorp/google"
      version = "~> 7.10"
    }
  }
}

locals {
  database_users = {
    for email in var.database_user_emails :
    "user_${replace(replace(email, "/@.*/", ""), ".", "_")}" => email
  }
}

module "cloud_sql" {
  source = "../cloud-sql"

  project_id = var.project_id
  name = var.name_suffix != null ? "${var.name}-${var.name_suffix}" : var.name
  database_version = var.database_version
  tier = var.database_tier
  availability_type = var.database_availability_type
  disk_size_gb = var.database_disk_size_gb
  alert_notification_channel_ids = var.alert_notification_channel_ids
  alert_severity = var.alert_severity
  alert_cpu_threshold = var.database_alert_cpu_threshold
  alert_ram_threshold = var.database_alert_ram_threshold
  alert_disk_threshold = var.database_alert_disk_threshold
  retain_transaction_log_days = var.database_retain_transaction_log_days
  retain_backup_count = var.database_retain_backup_count
  backup_start_time = var.database_backup_start_time
  maintenance_window_day = var.database_maintenance_window_day
  maintenance_window_hour = var.database_maintenance_window_hour
  users = concat(
    [for service in concat([var.name], var.database_service_users) : "service_${service}"],
    keys(local.database_users),
  )
}

module "cloud_run_service" {
  source = "../cloud-run-service"

  project_id = var.project_id
  name = var.name_suffix != null ? "${var.name}-${var.name_suffix}" : var.name
  region = var.region
  domain_project_id = var.domain_project_id
  domain_managed_zone_name = var.domain_managed_zone_name
  domain = var.domain
  www_redirect = var.www_redirect
  alert_notification_channel_ids = var.alert_notification_channel_ids
  alert_severity = var.alert_severity
  server_cpu = var.server_cpu
  server_memory = var.server_memory
  min_instances = var.min_instances
  max_instances = var.max_instances
  container_port = var.container_port
  env = merge({WORKERS = 2 * var.server_cpu + 1}, var.env)
  env_secrets = var.env_secrets
  allowed_source_ip_ranges = var.allowed_source_ip_ranges
  allow_uptime_check_source_ips = var.allow_uptime_check_source_ips
  cloud_sql_instances = [module.cloud_sql]
  secret_ids = concat([
      google_secret_manager_secret.secret["${var.name}-secret-key"].secret_id,
      google_secret_manager_secret.secret["${var.name}-database-access"].secret_id,
  ], var.secret_ids)
  publisher_service_account_email = var.publisher_service_account_email
}

module "cloud_run_job" {
  source = "../cloud-run-job"

  project_id = var.project_id
  name = var.name_suffix != null ? "${var.name}-command-${var.name_suffix}" : "${var.name}-command"
  region = var.region
  server_cpu = coalesce(var.job_server_cpu, var.server_cpu)
  server_memory = coalesce(var.job_server_memory, var.server_memory)
  image = module.cloud_run_service.image
  env = var.env
  command = var.job_command != null ? var.job_command : ["orb", var.name, "--command"]
  egress_subnetwork_id = var.job_egress_subnetwork_id
  args = ["manage"]
  service_account_email = module.cloud_run_service.service_account_email
  cloud_sql_instances = [module.cloud_sql]
  publisher_service_account_email = var.publisher_service_account_email
}
