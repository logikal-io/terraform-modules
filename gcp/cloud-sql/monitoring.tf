# Metrics: https://docs.cloud.google.com/monitoring/api/metrics_gcp
# Policies: https://docs.cloud.google.com/monitoring/api/ref_v3/rest/v3/projects.alertPolicies

# Dashboard
resource "google_project_service" "monitoring" {
  service = "monitoring.googleapis.com"
}

locals {
  monitoring_name_prefix = "${google_sql_database_instance.this.name}-db"
  database_id = "${var.project_id}:${google_sql_database_instance.this.name}"
}

resource "google_monitoring_dashboard" "this" {
  dashboard_json = templatefile(
    "${path.module}/dashboard.json",
    {
      "name": local.monitoring_name_prefix,
      "database_instance": google_sql_database_instance.this.name,
      "database_id": local.database_id,
      "alert_policy_name": {
        "db_cpu": google_monitoring_alert_policy.db_cpu.name,
        "db_ram": google_monitoring_alert_policy.db_ram.name,
        "db_disk": google_monitoring_alert_policy.db_disk.name,
      },
    },
  )

  depends_on = [google_project_service.monitoring]
}

# Alerts
resource "google_monitoring_alert_policy" "db_cpu" {
  display_name = "${local.monitoring_name_prefix}-cpu"
  combiner = "OR"
  conditions {
    display_name = "high CPU usage"
    condition_threshold {
      threshold_value = var.alert_cpu_threshold
      duration = "${5 * 60}s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period = "60s"
        per_series_aligner = "ALIGN_MAX"
        cross_series_reducer = "REDUCE_MAX"
      }
      filter = join(" AND ", [
        "metric.type = \"cloudsql.googleapis.com/database/cpu/utilization\"",
        "resource.type = \"cloudsql_database\"",
        "resource.label.database_id = \"${local.database_id}\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_NO_OP"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "db_ram" {
  display_name = "${local.monitoring_name_prefix}-ram"
  combiner = "OR"
  conditions {
    display_name = "high RAM usage"
    condition_threshold {
      threshold_value = var.alert_ram_threshold
      duration = "${5 * 60}s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period = "60s"
        per_series_aligner = "ALIGN_MAX"
        cross_series_reducer = "REDUCE_MAX"
      }
      filter = join(" AND ", [
        "metric.type = \"cloudsql.googleapis.com/database/memory/utilization\"",
        "resource.type = \"cloudsql_database\"",
        "resource.labels.database_id = \"${local.database_id}\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_NO_OP"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "db_disk" {
  display_name = "${local.monitoring_name_prefix}-disk"
  combiner = "OR"
  conditions {
    display_name = "high disk usage"
    condition_threshold {
      threshold_value = var.alert_disk_threshold
      duration = "${5 * 60}s"
      comparison = "COMPARISON_GT"
      trigger {
        count = 3
      }
      aggregations {
        alignment_period = "60s"
        per_series_aligner = "ALIGN_MAX"
        cross_series_reducer = "REDUCE_MAX"
      }
      filter = join(" AND ", [
        "metric.type = \"cloudsql.googleapis.com/database/disk/utilization\"",
        "resource.type = \"cloudsql_database\"",
        "resource.labels.database_id = \"${local.database_id}\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_NO_OP"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}
