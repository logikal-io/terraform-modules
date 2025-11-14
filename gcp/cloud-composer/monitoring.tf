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
        "database_cpu_usage_time": google_monitoring_alert_policy.database_cpu_usage_time.name,
        "parse_error_count": google_monitoring_alert_policy.parse_error_count.name,
        "finished_task_instance_count": google_monitoring_alert_policy.finished_task_instance_count.name,
        "executor_running_tasks": google_monitoring_alert_policy.executor_running_tasks.name,
        "failed_sla_callback_notifications": google_monitoring_alert_policy.failed_sla_callback_notifications.name,
        "unfinished_task_instances": google_monitoring_alert_policy.unfinished_task_instances.name,
        "orphaned_task_count": google_monitoring_alert_policy.orphaned_task_count.name,
      },
    },
  )

  depends_on = [google_project_service.monitoring]
}

# Service monitoring
#resource "google_monitoring_service" "this" {
#  service_id = google_composer_environment.this.name
#  display_name = google_composer_environment.this.name

#  basic_service {
#    service_type = "CLOUD_COMPOSER"
#    service_labels = {
#      location = var.region
#      service_name = google_composer_environment.this.name
#    }
#  }

#  depends_on = [google_project_service.monitoring]
#}

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
  #notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "database_cpu_usage_time" {
  display_name = "${google_composer_environment.this.name}-database-cpu-usage-time"
  combiner = "OR"
  conditions {
    display_name = "Database CPU usage time"
    condition_threshold {
      threshold_value = 0.8
      duration = "300s"
      comparison = "COMPARISON_GT"
      trigger {
        count = 1
      }
      aggregations {
        alignment_period = "60s"
        cross_series_reducer = "REDUCE_PERCENTILE_99"
        group_by_fields = ["resource.label.environment_name"]
        per_series_aligner = "ALIGN_RATE"
      }
      filter = join(" ", [
        "resource.type = \"cloud_composer_environment\"",
        "AND resource.labels.environment_name = \"${google_composer_environment.this.name}\"",
        "AND metric.type = \"composer.googleapis.com/environment/database/cpu/usage_time\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"
    }
  }
  severity = var.alert_severity
  #notification_channels = var.alert_notification_channel_ids

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
  #notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "finished_task_instance_count" {
  display_name = "${google_composer_environment.this.name}-finished-task-instance-count"
  combiner = "OR"
  conditions {
    display_name = "Finished task instance count"
    condition_threshold {
      threshold_value = 0
      duration = "600s"
      comparison = "COMPARISON_LT"
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
        "AND metric.type = \"composer.googleapis.com/environment/finished_task_instance_count\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"
    }
  }
  severity = var.alert_severity
  #notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "executor_running_tasks" {
  display_name = "${google_composer_environment.this.name}-executor-running-tasks"
  combiner = "OR"
  conditions {
    display_name = "Executor running tasks"
    condition_threshold {
      threshold_value = 10 # not sure
      duration = "600s"
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
        "AND metric.type = \"composer.googleapis.com/environment/executor/running_tasks\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"
    }
  }
  severity = var.alert_severity
  #notification_channels = var.alert_notification_channel_ids

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
  #notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "unfinished_task_instances" {
  display_name = "${google_composer_environment.this.name}-unfinished-task-instances"
  combiner = "OR"
  conditions {
    display_name = "Unfinished task instances"
    condition_threshold {
      threshold_value = 5
      duration = "600s"
      comparison = "COMPARISON_GT"
      trigger {
        count = 1
      }
      aggregations {
        alignment_period = "300s"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields = ["resource.label.environment_name"]
        per_series_aligner = "ALIGN_SUM"
      }
      filter = join(" ", [
        "resource.type = \"cloud_composer_environment\"",
        "AND resource.labels.environment_name = \"${google_composer_environment.this.name}\"",
        "AND metric.type = \"composer.googleapis.com/environment/unfinished_task_instances\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"
    }
  }
  severity = var.alert_severity
  #notification_channels = var.alert_notification_channel_ids

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
  #notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}
