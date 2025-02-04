resource "google_project_service" "cloud_sql_admin" {
  service = "sqladmin.googleapis.com"  # needed for cloud-sql-proxy connections
}

resource "google_sql_database_instance" "website" {
  name = "${var.name}-website"
  database_version = "POSTGRES_15"

  settings {
    tier = var.database_tier
    edition = "ENTERPRISE"
    activation_policy = "ALWAYS"
    availability_type = var.database_availability_type
    deletion_protection_enabled = true

    disk_autoresize = false
    disk_size = var.database_disk_size_gb
    disk_type = "PD_SSD"

    password_validation_policy {
      min_length = 20
      enable_password_policy = true
    }

    backup_configuration {
      enabled = true
      start_time = "00:15"  # 01:15 UTC+1
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7

      backup_retention_settings {
        retained_backups = var.database_retain_backup_count
      }
    }

    ip_configuration {
      ipv4_enabled = true
      ssl_mode = "TRUSTED_CLIENT_CERTIFICATE_REQUIRED"
    }

    maintenance_window {
      day = 7  # Sunday
      hour = 1  # 02:00 UTC+1
      update_track = "stable"
    }
  }
}

resource "google_sql_database" "website" {
  name = var.name
  instance = google_sql_database_instance.website.name
}

# Users
resource "random_password" "website_user" {
  length = 20
}

resource "google_sql_user" "website" {
  instance = google_sql_database_instance.website.name
  name = "${var.name}-website-service"
  password = random_password.website_user.result
}

resource "google_secret_manager_secret" "website_database_secrets" {
  secret_id = "${var.name}-website-database-secrets"
  replication {
    auto {}
  }

  depends_on = [google_project_service.secret_manager]
}

resource "google_secret_manager_secret_version" "website_user" {
  secret = google_secret_manager_secret.website_database_secrets.id
  secret_data = jsonencode({
    hostname = "/cloudsql/${google_sql_database_instance.website.connection_name}"
    port = 5432
    database = google_sql_database.website.name
    username = google_sql_user.website.name
    password = random_password.website_user.result
  })
}
