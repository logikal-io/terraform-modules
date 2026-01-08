# Metrics: https://docs.cloud.google.com/monitoring/api/metrics_gcp
# Policies: https://docs.cloud.google.com/monitoring/api/ref_v3/rest/v3/projects.alertPolicies

# Dashboard
resource "google_project_service" "monitoring" {
  service = "monitoring.googleapis.com"
}

locals {
  environment_name = google_composer_environment.this.name
  monitoring_name_prefix = "${local.environment_name}-airflow"
}

resource "google_monitoring_dashboard" "this" {
  dashboard_json = templatefile(
    "${path.module}/dashboard.json",
    {
      "name": local.monitoring_name_prefix,
      "environment_name": local.environment_name,
      "alert_policy_name": {
        # System health
        "environment_health": google_monitoring_alert_policy.environment_health.name,
        "web_server_health": google_monitoring_alert_policy.web_server_health.name,
        "scheduler_heartbeats": google_monitoring_alert_policy.scheduler_heartbeats.name,
        "db_health": google_monitoring_alert_policy.db_health.name,
        # Errors
        "dag_parse_errors": google_monitoring_alert_policy.dag_parse_errors.name,
        "dag_load_time": google_monitoring_alert_policy.dag_load_time.name,
        "sla_callback_fails": google_monitoring_alert_policy.sla_callback_fails.name,
        "orphaned_tasks": google_monitoring_alert_policy.orphaned_tasks.name,
        # Resource issues
        "executor_open_slots": google_monitoring_alert_policy.executor_open_slots.name,
        "scheduler_pod_evictions": google_monitoring_alert_policy.scheduler_pod_evictions.name,
        "worker_pod_evictions": google_monitoring_alert_policy.worker_pod_evictions.name,
        "dag_run_schedule_delay": google_monitoring_alert_policy.dag_run_schedule_delay.name,
        # Database
        "db_cpu": google_monitoring_alert_policy.db_cpu.name,
        "db_ram": google_monitoring_alert_policy.db_ram.name,
        "db_disk": google_monitoring_alert_policy.db_disk.name,
      },
    },
  )

  depends_on = [google_project_service.monitoring]
}

# Alerts
resource "google_monitoring_alert_policy" "environment_health" {
  display_name = "${local.monitoring_name_prefix}-environment-health"
  combiner = "OR"
  conditions {
    display_name = "unhealthy environment"
    condition_threshold {
      threshold_value = 1
      duration = "${10 * 60}s" # sampled every 300s, +delay up to 120s (overall ~7 minutes)
      comparison = "COMPARISON_LT"
      aggregations {
        alignment_period = "300s"
        per_series_aligner = "ALIGN_COUNT_TRUE"
        cross_series_reducer = "REDUCE_NONE"
      }
      filter = join(" AND ", [
        "metric.type = \"composer.googleapis.com/environment/healthy\"",
        "resource.type = \"cloud_composer_environment\"",
        "resource.label.environment_name = \"${local.environment_name}\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_NO_OP"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "web_server_health" {
  display_name = "${local.monitoring_name_prefix}-web-server-health"
  combiner = "OR"
  conditions {
    display_name = "unhealthy web server"
    condition_threshold {
      threshold_value = 1
      duration = "${5 * 60}s"
      comparison = "COMPARISON_LT"
      aggregations {
        alignment_period = "60s"
        per_series_aligner = "ALIGN_COUNT_TRUE"
        cross_series_reducer = "REDUCE_NONE"
      }
      filter = join(" AND ", [
        "metric.type = \"composer.googleapis.com/environment/web_server/health\"",
        "resource.type = \"cloud_composer_environment\"",
        "resource.label.environment_name = \"${local.environment_name}\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_NO_OP"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "scheduler_heartbeats" {
  display_name = "${local.monitoring_name_prefix}-scheduler-heartbeats"
  combiner = "OR"
  conditions {
    display_name = "unhealthy scheduler"
    condition_threshold {
      threshold_value = 1
      duration = "${5 * 60}s"
      comparison = "COMPARISON_LT"
      aggregations {
        alignment_period = "60s"
        per_series_aligner = "ALIGN_SUM"
        cross_series_reducer = "REDUCE_NONE"
      }
      filter = join(" AND ", [
        "metric.type = \"composer.googleapis.com/environment/scheduler_heartbeat_count\"",
        "resource.type = \"cloud_composer_environment\"",
        "resource.label.environment_name = \"${local.environment_name}\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_NO_OP"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "db_health" {
  display_name = "${local.monitoring_name_prefix}-db-health"
  combiner = "OR"
  conditions {
    display_name = "unhealthy database"
    condition_threshold {
      threshold_value = 1
      duration = "${5 * 60}s"
      comparison = "COMPARISON_LT"
      aggregations {
        alignment_period = "60s"
        per_series_aligner = "ALIGN_COUNT_TRUE"
        cross_series_reducer = "REDUCE_NONE"
      }
      filter = join(" AND ", [
        "metric.type = \"composer.googleapis.com/environment/database_health\"",
        "resource.type = \"cloud_composer_environment\"",
        "resource.label.environment_name = \"${local.environment_name}\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_NO_OP"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "dag_parse_errors" {
  display_name = "${local.monitoring_name_prefix}-dag-parse-errors"
  combiner = "OR"
  conditions {
    display_name = "DAG parse error"
    condition_threshold {
      threshold_value = 0
      duration = "${5 * 60}s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period = "60s"
        per_series_aligner = "ALIGN_SUM"
        cross_series_reducer = "REDUCE_NONE"
      }
      filter = join(" AND ", [
        "metric.type = \"composer.googleapis.com/environment/dag_processing/parse_error_count\"",
        "resource.type = \"cloud_composer_environment\"",
        "resource.label.environment_name = \"${local.environment_name}\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_NO_OP"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "dag_load_time" {
  display_name = "${local.monitoring_name_prefix}-dag-load-time"
  combiner = "OR"
  conditions {
    display_name = "high DAG load time"
    condition_threshold {
      threshold_value = 10 * 1000 # ms
      duration = "${5 * 60}s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period = "${5 * 60}s"
        per_series_aligner = "ALIGN_MAX"
        cross_series_reducer = "REDUCE_NONE"
      }
      filter = join(" AND ", [
        "metric.type = \"composer.googleapis.com/environment/dag_processing/last_duration\"",
        "resource.type = \"cloud_composer_environment\"",
        "resource.label.environment_name = \"${local.environment_name}\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_NO_OP"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "sla_callback_fails" {
  display_name = "${local.monitoring_name_prefix}-sla-callback-fails"
  combiner = "OR"
  conditions {
    display_name = "SLA callback failure"
    condition_threshold {
      threshold_value = 0
      duration = "${5 * 60}s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period = "${5 * 60}s"
        per_series_aligner = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_NONE"
      }
      filter = join(" AND ", [
        "metric.type = \"composer.googleapis.com/environment/sla_callback_notification_failure_count\"",
        "resource.type = \"cloud_composer_environment\"",
        "resource.label.environment_name = \"${local.environment_name}\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_NO_OP"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "orphaned_tasks" {
  display_name = "${local.monitoring_name_prefix}-orphaned-tasks"
  combiner = "OR"
  conditions {
    display_name = "orphaned task"
    condition_threshold {
      threshold_value = 0
      duration = "${5 * 60}s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period = "${5 * 60}s"
        per_series_aligner = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_NONE"
      }
      filter = join(" AND ", [
        "metric.type = \"composer.googleapis.com/environment/scheduler/task/orphan_count\"",
        "resource.type = \"cloud_composer_environment\"",
        "resource.label.environment_name = \"${local.environment_name}\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_NO_OP"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "executor_open_slots" {
  display_name = "${local.monitoring_name_prefix}-executor-open-slots"
  combiner = "OR"
  conditions {
    display_name = "low executor open slots"
    condition_threshold {
      threshold_value = 5
      duration = "${5 * 60}s"
      comparison = "COMPARISON_LT"
      aggregations {
        alignment_period = "60s"
        per_series_aligner = "ALIGN_MIN"
        cross_series_reducer = "REDUCE_NONE"
      }
      filter = join(" AND ", [
        "metric.type = \"composer.googleapis.com/environment/executor/open_slots\"",
        "resource.type = \"cloud_composer_environment\"",
        "resource.label.environment_name = \"${local.environment_name}\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_NO_OP"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "scheduler_pod_evictions" {
  display_name = "${local.monitoring_name_prefix}-scheduler-pod-evictions"
  combiner = "OR"
  conditions {
    display_name = "scheduler pod eviction"
    condition_threshold {
      threshold_value = 0
      duration = "${5 * 60}s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period = "${5 * 60}s"
        per_series_aligner = "ALIGN_SUM"
        cross_series_reducer = "REDUCE_NONE"
      }
      filter = join(" AND ", [
        "metric.type = \"composer.googleapis.com/environment/scheduler/pod_eviction_count\"",
        "resource.type = \"cloud_composer_environment\"",
        "resource.label.environment_name = \"${local.environment_name}\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_NO_OP"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "worker_pod_evictions" {
  display_name = "${local.monitoring_name_prefix}-worker-pod-evictions"
  combiner = "OR"
  conditions {
    display_name = "worker pod eviction"
    condition_threshold {
      threshold_value = 0
      duration = "${5 * 60}s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period = "${5 * 60}s"
        per_series_aligner = "ALIGN_SUM"
        cross_series_reducer = "REDUCE_NONE"
      }
      filter = join(" AND ", [
        "metric.type = \"composer.googleapis.com/environment/worker/pod_eviction_count\"",
        "resource.type = \"cloud_composer_environment\"",
        "resource.label.environment_name = \"${local.environment_name}\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_NO_OP"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "dag_run_schedule_delay" {
  display_name = "${local.monitoring_name_prefix}-dag-run-schedule-delay"
  combiner = "OR"
  conditions {
    display_name = "delayed DAG execution"
    condition_threshold {
      threshold_value = 10 * 1000 # ms
      duration = "${5 * 60}s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period = "${5 * 60}s"
        per_series_aligner = "ALIGN_MAX"
        cross_series_reducer = "REDUCE_NONE"
      }
      filter = join(" AND ", [
        "metric.type = \"composer.googleapis.com/workflow/schedule_delay\"",
        "resource.type = \"internal_composer_workflow\"",
        "resource.label.environment_name = \"${local.environment_name}\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_NO_OP"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "db_cpu" {
  display_name = "${local.monitoring_name_prefix}-db-cpu"
  combiner = "OR"
  conditions {
    display_name = "high database CPU usage"
    condition_threshold {
      threshold_value = 0.8
      duration = "${5 * 60}s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period = "60s"
        per_series_aligner = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_NONE"
      }
      filter = join(" AND ", [
        "metric.type = \"composer.googleapis.com/environment/database/cpu/utilization\"",
        "resource.type = \"cloud_composer_environment\"",
        "resource.label.environment_name = \"${local.environment_name}\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_NO_OP"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "db_ram" {
  display_name = "${local.monitoring_name_prefix}-db-ram"
  combiner = "OR"
  conditions {
    display_name = "high database RAM usage"
    condition_threshold {
      threshold_value = 0.8
      duration = "${5 * 60}s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period = "60s"
        per_series_aligner = "ALIGN_MAX"
      }
      filter = join(" AND ", [
        "metric.type = \"composer.googleapis.com/environment/database/memory/utilization\"",
        "resource.type = \"cloud_composer_environment\"",
        "resource.label.environment_name = \"${local.environment_name}\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_NO_OP"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "db_disk" {
  display_name = "${local.monitoring_name_prefix}-db-disk"
  combiner = "OR"
  conditions {
    display_name = "high database disk usage"
    condition_threshold {
      threshold_value = 0.8
      duration = "${5 * 60}s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period = "60s"
        per_series_aligner = "ALIGN_MAX"
        cross_series_reducer = "REDUCE_NONE"
      }
      filter = join(" AND ", [
        "metric.type = \"composer.googleapis.com/environment/database/disk/utilization\"",
        "resource.type = \"cloud_composer_environment\"",
        "resource.label.environment_name = \"${local.environment_name}\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_NO_OP"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}
