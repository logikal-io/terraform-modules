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

resource "google_project_service" "cloud_sql_admin" {
  service = "sqladmin.googleapis.com"  # needed for cloud-sql-proxy connections
}

resource "google_sql_database_instance" "this" {
  name = var.name
  database_version = var.database_version

  settings {
    tier = var.tier
    edition = "ENTERPRISE"
    activation_policy = "ALWAYS"
    availability_type = var.availability_type
    deletion_protection_enabled = true

    disk_autoresize = false
    disk_size = var.disk_size_gb
    disk_type = "PD_SSD"

    password_validation_policy {
      min_length = 20
      enable_password_policy = true
    }

    backup_configuration {
      enabled = true
      start_time = var.backup_start_time
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = var.retain_transaction_log_days

      backup_retention_settings {
        retained_backups = var.retain_backup_count
      }
    }

    ip_configuration {
      ipv4_enabled = true
      ssl_mode = "TRUSTED_CLIENT_CERTIFICATE_REQUIRED"
    }

    maintenance_window {
      day = var.maintenance_window_day
      hour = var.maintenance_window_hour
      update_track = "stable"
    }

    insights_config {
      query_insights_enabled = true
      query_string_length = 1024
      record_client_address = true
      query_plans_per_minute = 5
    }
  }
}

resource "google_sql_database" "this" {
  name = var.name
  instance = google_sql_database_instance.this.name
}

resource "random_password" "user" {
  for_each = toset(var.users)

  length = 20
}

resource "google_sql_user" "user" {
  for_each = toset(var.users)

  instance = google_sql_database_instance.this.name
  name = each.value
  password = random_password.user[each.value].result
}
