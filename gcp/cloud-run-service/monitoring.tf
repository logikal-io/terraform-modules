# Metrics: https://docs.cloud.google.com/monitoring/api/metrics_gcp
# Policies: https://docs.cloud.google.com/monitoring/api/ref_v3/rest/v3/projects.alertPolicies

# Dashboard
resource "google_project_service" "monitoring" {
  service = "monitoring.googleapis.com"
}

locals {
  service_name = google_cloud_run_v2_service.this.name
  monitoring_name_prefix = "${local.service_name}-service"
}

resource "google_monitoring_dashboard" "this" {
  dashboard_json = templatefile(
    "${path.module}/dashboard.json",
    {
      "name": local.monitoring_name_prefix,
      "project_id": var.project_id,
      "service_name": local.service_name,
      "url_map_name": google_compute_url_map.this.name,
      "alert_policy_name": {
        "service_cpu": google_monitoring_alert_policy.service_cpu.name,
        "service_ram": google_monitoring_alert_policy.service_ram.name,
        "service_latency": google_monitoring_alert_policy.service_latency.name,
        "uptime_check_failure": google_monitoring_alert_policy.uptime_check_failure.name,
        "server_error": google_monitoring_alert_policy.server_error.name,
      },
    },
  )

  depends_on = [google_project_service.monitoring]
}

# Service monitoring
resource "google_monitoring_service" "this" {
  service_id = local.service_name
  display_name = local.monitoring_name_prefix

  basic_service {
    service_type = "CLOUD_RUN"
    service_labels = {
      location = var.region
      service_name = local.service_name
    }
  }

  depends_on = [google_project_service.monitoring]
}

# SLO
resource "google_monitoring_slo" "availability" {
  service = google_monitoring_service.this.service_id

  slo_id = "${local.monitoring_name_prefix}-availability"
  display_name = "${local.service_name} service availability"

  goal = var.availability_slo_goal
  calendar_period = "MONTH"

  basic_sli {
    availability {}
  }

  depends_on = [google_project_service.monitoring]
}

# Uptime check
resource "google_monitoring_uptime_check_config" "this" {
  display_name = "${local.monitoring_name_prefix}-uptime"
  timeout = "10s"
  period = "60s"

  http_check {
    path = "/"
    port = "443"
    use_ssl = true
    validate_ssl = true

    accepted_response_status_codes {
      status_class = "STATUS_CLASS_2XX"
    }
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host = var.domain
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [google_project_service.monitoring]
}

# Alerts
resource "google_monitoring_alert_policy" "service_cpu" {
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
        per_series_aligner = "ALIGN_PERCENTILE_99"
        group_by_fields = ["resource.label.revision_name"]
        cross_series_reducer = "REDUCE_NONE"
      }
      filter = join(" AND ", [
        "metric.type = \"run.googleapis.com/container/cpu/utilizations\"",
        "resource.type = \"cloud_run_revision\"",
        "resource.label.service_name = \"${local.service_name}\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_NO_OP"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "service_cpu_missing" {
  display_name = "${local.monitoring_name_prefix}-cpu-missing"
  combiner = "OR"
  conditions {
    display_name = "missing CPU usage data"
    condition_absent {
      duration = "${5 * 60}s"
      aggregations {
        alignment_period = "60s"
        per_series_aligner = "ALIGN_PERCENTILE_99"
        group_by_fields = ["resource.label.revision_name"]
        cross_series_reducer = "REDUCE_NONE"
      }
      filter = join(" AND ", [
        "metric.type = \"run.googleapis.com/container/cpu/utilizations\"",
        "resource.type = \"cloud_run_revision\"",
        "resource.label.service_name = \"${local.service_name}\"",
      ])
      trigger {
        percent = 100
      }
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "service_ram" {
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
        per_series_aligner = "ALIGN_PERCENTILE_99"
        group_by_fields = ["resource.label.revision_name"]
        cross_series_reducer = "REDUCE_NONE"
      }
      filter = join(" AND ", [
        "metric.type = \"run.googleapis.com/container/memory/utilizations\"",
        "resource.type = \"cloud_run_revision\"",
        "resource.label.service_name = \"${local.service_name}\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_NO_OP"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "service_ram_missing" {
  display_name = "${local.monitoring_name_prefix}-ram-missing"
  combiner = "OR"
  conditions {
    display_name = "missing RAM usage data"
    condition_absent {
      duration = "${5 * 60}s"
      aggregations {
        alignment_period = "60s"
        per_series_aligner = "ALIGN_PERCENTILE_99"
        group_by_fields = ["resource.label.revision_name"]
        cross_series_reducer = "REDUCE_NONE"
      }
      filter = join(" AND ", [
        "metric.type = \"run.googleapis.com/container/memory/utilizations\"",
        "resource.type = \"cloud_run_revision\"",
        "resource.label.service_name = \"${local.service_name}\"",
      ])
      trigger {
        percent = 100
      }
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "service_latency" {
  display_name = "${local.monitoring_name_prefix}-latency"
  combiner = "OR"
  conditions {
    display_name = "high request latency"
    condition_threshold {
      threshold_value = var.alert_latency_threshold_ms
      duration = "60s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period = "60s"
        per_series_aligner = "ALIGN_PERCENTILE_99"
        group_by_fields = ["resource.label.revision_name"]
        cross_series_reducer = "REDUCE_NONE"
      }
      filter = join(" AND ", [
        "metric.type = \"run.googleapis.com/request_latencies\"",
        "resource.type = \"cloud_run_revision\"",
        "resource.label.service_name = \"${local.service_name}\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_NO_OP"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

locals {
  uptime_check_id = google_monitoring_uptime_check_config.this.uptime_check_id
}

resource "google_monitoring_alert_policy" "uptime_check_failure" {
  display_name = "${local.monitoring_name_prefix}-uptime-check"
  combiner = "OR"
  conditions {
    display_name = "uptime check failure"
    condition_threshold {
      threshold_value = 0
      duration = "${5 * 60}s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period = "60s"
        per_series_aligner = "ALIGN_COUNT_FALSE"
        cross_series_reducer = "REDUCE_SUM"
      }
      filter = join(" AND ", [
        "resource.type = \"uptime_url\"",
        "metric.type = \"monitoring.googleapis.com/uptime_check/check_passed\"",
        "metric.label.check_id = \"${local.uptime_check_id}\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_ACTIVE"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "server_error" {
  display_name = "${local.monitoring_name_prefix}-server-error"
  combiner = "OR"

  conditions {
    display_name = "server error"
    condition_threshold {
      threshold_value = 0
      duration = "60s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period = "60s"
        per_series_aligner = "ALIGN_SUM"
        group_by_fields = ["resource.label.revision_name"]
        cross_series_reducer = "REDUCE_NONE"
      }
      filter = join(" AND ", [
        "metric.type = \"run.googleapis.com/request_count\"",
        "metric.label.response_code_class = \"5xx\"",
        "resource.type = \"cloud_run_revision\"",
        "resource.label.service_name = \"${local.service_name}\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_NO_OP"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids

  depends_on = [google_project_service.monitoring]
}
