# Dashboard
resource "google_project_service" "monitoring" {
  service = "monitoring.googleapis.com"
}

resource "google_monitoring_dashboard" "this" {
  dashboard_json = templatefile(
    "${path.module}/dashboard.json",
    {
      "project_id": var.project_id,
      "environment_name": google_composer_environment.this.name,
      "alert_policy_name": {
        "scheduler_heartbeats": google_monitoring_alert_policy.scheduler_heartbeats.name,
        "parse_error_count": google_monitoring_alert_policy.parse_error_count.name,
        "failed_sla_callback_notifications": google_monitoring_alert_policy.failed_sla_callback_notifications.name,
        "orphaned_task_count": google_monitoring_alert_policy.orphaned_task_count.name,
        "dag_run_schedule_delay": google_monitoring_alert_policy.dag_run_schedule_delay.name,
      },
    },
  )

  depends_on = [google_project_service.monitoring]
}

# Alerts
resource "google_monitoring_alert_policy" "scheduler_heartbeats" {
  display_name = "${google_composer_environment.this.name}-scheduler-heatbeats"
  combiner = "OR"
  conditions {
    display_name = "Scheduler heartbeats"
    condition_threshold {
      threshold_value = 0
      duration = "600s"
      comparison = "COMPARISON_LT"
      trigger {
        count = 1
      }
      aggregations {
        alignment_period = "60s"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields = ["resource.label.environment_name"]
        per_series_aligner = "ALIGN_SUM"
      }
      filter = join(" ", [
        "resource.type = \"cloud_composer_environment\"",
        "AND resource.labels.environment_name = \"${google_composer_environment.this.name}\"",
        "AND metric.type = \"composer.googleapis.com/environment/scheduler_heartbeat_count\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_ACTIVE"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "parse_error_count" {
  display_name = "${google_composer_environment.this.name}-parse-error-count"
  combiner = "OR"
  conditions {
    display_name = "Parse error count"
    condition_threshold {
      threshold_value = 0
      duration = "60s"
      comparison = "COMPARISON_GT"
      trigger {
        count = 1
      }
      aggregations {
        alignment_period = "60s"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields = ["resource.label.environment_name"]
        per_series_aligner = "ALIGN_SUM"
      }
      filter = join(" ", [
        "resource.type = \"cloud_composer_environment\"",
        "AND resource.labels.environment_name = \"${google_composer_environment.this.name}\"",
        "AND metric.type = \"composer.googleapis.com/environment/dag_processing/parse_error_count\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "failed_sla_callback_notifications" {
  display_name = "${google_composer_environment.this.name}-failed-sla-callback-notifications"
  combiner = "OR"
  conditions {
    display_name = "failed SLA callback notifications"
    condition_threshold {
      threshold_value = 0
      duration = "60s"
      comparison = "COMPARISON_GT"
      trigger {
        count = 1
      }
      aggregations {
        alignment_period = "60s"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields = ["resource.label.environment_name"]
        per_series_aligner = "ALIGN_DELTA"
      }
      filter = join(" ", [
        "resource.type = \"cloud_composer_environment\"",
        "AND resource.labels.environment_name = \"${google_composer_environment.this.name}\"",
        "AND metric.type = \"composer.googleapis.com/environment/sla_callback_notification_failure_count\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "orphaned_task_count" {
  display_name = "${google_composer_environment.this.name}-orphaned-task-count"
  combiner = "OR"
  conditions {
    display_name = "Orphaned task count"
    condition_threshold {
      threshold_value = 0
      duration = "300s"
      comparison = "COMPARISON_GT"
      trigger {
        count = 1
      }
      aggregations {
        alignment_period = "300s"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields = ["resource.label.environment_name"]
        per_series_aligner = "ALIGN_DELTA"
      }
      filter = join(" ", [
        "resource.type = \"cloud_composer_environment\"",
        "AND resource.labels.environment_name = \"${google_composer_environment.this.name}\"",
        "AND metric.type = \"composer.googleapis.com/environment/scheduler/task/orphan_count\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "dag_run_schedule_delay" {
  display_name = "${google_composer_environment.this.name}-dag-run-schedule-delay"
  combiner = "OR"
  conditions {
    display_name = "DAG run schedule delay"
    condition_threshold {
      threshold_value = 60
      duration = "60s"
      comparison = "COMPARISON_GT"
      trigger {
        count = 1
      }
      aggregations {
        alignment_period = "300s"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields = ["resource.label.environment_name"]
        per_series_aligner = "ALIGN_DELTA"
      }
      filter = join(" ", [
        "resource.type = \"cloud_composer_environment\"",
        "AND resource.labels.environment_name = \"${google_composer_environment.this.name}\"",
        "AND metric.type = \"composer.googleapis.com/workflow/schedule_delay\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "dag_file_load_time" {
  display_name = "${google_composer_environment.this.name}-dag-file-load-time"
  combiner = "OR"
  conditions {
    display_name = "DAG file load time"
    condition_threshold {
      threshold_value = 10
      duration = "180s"
      comparison = "COMPARISON_GT"
      trigger {
        count = 1
      }
      aggregations {
        alignment_period = "60s"
        cross_series_reducer = "REDUCE_PERCENTILE_95"
        group_by_fields = ["resource.label.environment_name"]
        per_series_aligner = "ALIGN_PERCENTILE_95"
      }
      filter = join(" ", [
        "resource.type = \"cloud_composer_environment\"",
        "AND resource.labels.environment_name = \"${google_composer_environment.this.name}\"",
        "AND metric.type = \"composer.googleapis.com/environment/dag_processing/last_duration\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}
