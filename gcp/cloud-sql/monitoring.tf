# Dashboard
locals {
  database_id = "${var.project_id}:${google_sql_database_instance.this.name}"
}

resource "google_monitoring_dashboard" "this" {
  dashboard_json = templatefile(
    "${path.module}/dashboard.json",
    {
      "database_id": local.database_id,
      "alert_policy_name": {
        "db_cpu": google_monitoring_alert_policy.db_cpu.name,
        "db_ram": google_monitoring_alert_policy.db_ram.name,
        "db_disk": google_monitoring_alert_policy.db_disk.name,
      },
    },
  )
}

# Alerts
resource "google_monitoring_alert_policy" "db_cpu" {
  display_name = "${google_sql_database_instance.this.name}-db-cpu"
  combiner = "OR"
  conditions {
    display_name = "high CPU usage"
    condition_threshold {
      threshold_value = 0.8
      duration = "60s"
      comparison = "COMPARISON_GT"
      trigger {
        count = 3
      }
      aggregations {
        alignment_period = "60s"
        cross_series_reducer = "REDUCE_MAX"
        group_by_fields = ["resource.label.database_id"]
        per_series_aligner = "ALIGN_MAX"
      }
      filter = join(" ", [
        "resource.type = \"cloudsql_database\"",
        "AND resource.labels.database_id = \"${local.database_id}\"",
        "AND metric.type = \"cloudsql.googleapis.com/database/cpu/utilization\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_ACTIVE"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids
}

resource "google_monitoring_alert_policy" "db_ram" {
  display_name = "${google_sql_database_instance.this.name}-db-ram"
  combiner = "OR"
  conditions {
    display_name = "high RAM usage"
    condition_threshold {
      threshold_value = 0.8
      duration = "60s"
      comparison = "COMPARISON_GT"
      trigger {
        count = 1
      }
      aggregations {
        alignment_period = "60s"
        cross_series_reducer = "REDUCE_MAX"
        group_by_fields = ["resource.label.database_id"]
        per_series_aligner = "ALIGN_MAX"
      }
      filter = join(" ", [
        "resource.type = \"cloudsql_database\"",
        "AND resource.labels.database_id = \"${local.database_id}\"",
        "AND metric.type = \"cloudsql.googleapis.com/database/memory/utilization\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_ACTIVE"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids
}

resource "google_monitoring_alert_policy" "db_disk" {
  display_name = "${google_sql_database_instance.this.name}-db-disk"
  combiner = "OR"
  conditions {
    display_name = "high disk usage"
    condition_threshold {
      threshold_value = 0.8
      duration = "60s"
      comparison = "COMPARISON_GT"
      trigger {
        count = 1
      }
      aggregations {
        alignment_period = "60s"
        cross_series_reducer = "REDUCE_MAX"
        group_by_fields = ["resource.label.database_id"]
        per_series_aligner = "ALIGN_MAX"
      }
      filter = join(" ", [
        "resource.type = \"cloudsql_database\"",
        "AND resource.labels.database_id = \"${local.database_id}\"",
        "AND metric.type = \"cloudsql.googleapis.com/database/disk/utilization\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_ACTIVE"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids
}
