# Dashboard
resource "google_monitoring_dashboard" "this" {
  dashboard_json = templatefile(
    "${path.module}/dashboard.json",
    {
      "project_id": var.project_id,
      "service_name": google_cloud_run_v2_service.this.name,
      "url_map_name": google_compute_url_map.this.name,
      "alert_policy_name": {
        "service_cpu": google_monitoring_alert_policy.service_cpu.name,
        "service_ram": google_monitoring_alert_policy.service_ram.name,
      },
    },
  )
}

# Service monitoring
resource "google_monitoring_service" "this" {
  service_id = google_cloud_run_v2_service.this.name
  display_name = google_cloud_run_v2_service.this.name

  basic_service {
    service_type = "CLOUD_RUN"
    service_labels = {
      location = var.region
      service_name = google_cloud_run_v2_service.this.name
    }
  }
}

# SLO
resource "google_monitoring_slo" "availability" {
  service = google_monitoring_service.this.service_id

  slo_id = "${google_cloud_run_v2_service.this.name}-availability"
  display_name = "${google_cloud_run_v2_service.this.name} service availability"

  goal = 0.995
  calendar_period = "MONTH"

  basic_sli {
    availability {}
  }
}

# Uptime check
resource "google_monitoring_uptime_check_config" "this" {
  display_name = "${google_cloud_run_v2_service.this.name}-uptime"
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
}

# Alerts
resource "google_monitoring_alert_policy" "service_cpu" {
  display_name = "${google_cloud_run_v2_service.this.name}-cpu"
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
        cross_series_reducer = "REDUCE_PERCENTILE_99"
        group_by_fields = ["resource.label.service_name"]
        per_series_aligner = "ALIGN_DELTA"
      }
      filter = join(" ", [
        "resource.type = \"cloud_run_revision\"",
        "AND resource.labels.service_name = \"${google_cloud_run_v2_service.this.name}\"",
        "AND metric.type = \"run.googleapis.com/container/cpu/utilizations\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_ACTIVE"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids
}

resource "google_monitoring_alert_policy" "service_ram" {
  display_name = "${google_cloud_run_v2_service.this.name}-ram"
  combiner = "OR"
  conditions {
    display_name = "high RAM usage"
    condition_threshold {
      threshold_value = 0.8
      duration = "60s"
      comparison = "COMPARISON_GT"
      trigger {
        count = 3
      }
      aggregations {
        alignment_period = "60s"
        cross_series_reducer = "REDUCE_PERCENTILE_99"
        group_by_fields = ["resource.label.service_name"]
        per_series_aligner = "ALIGN_DELTA"
      }
      filter = join(" ", [
        "resource.type = \"cloud_run_revision\"",
        "AND resource.labels.service_name = \"${google_cloud_run_v2_service.this.name}\"",
        "AND metric.type = \"run.googleapis.com/container/memory/utilizations\"",
      ])
      evaluation_missing_data = "EVALUATION_MISSING_DATA_ACTIVE"
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids
}

resource "google_monitoring_alert_policy" "service_latency" {
  display_name = "${google_cloud_run_v2_service.this.name}-latency"
  combiner = "OR"
  conditions {
    display_name = "high request latency"
    condition_threshold {
      threshold_value = 10000
      duration = "0s"
      comparison = "COMPARISON_GT"
      trigger {
        count = 1
      }
      aggregations {
        alignment_period = "300s"
        per_series_aligner = "ALIGN_PERCENTILE_95"
      }
      filter = join(" ", [
        "resource.type = \"cloud_run_revision\"",
        "AND resource.labels.service_name = \"${google_cloud_run_v2_service.this.name}\"",
        "AND metric.type = \"run.googleapis.com/request_latencies\"",
      ])
    }
  }
  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids
}

resource "google_monitoring_alert_policy" "uptime_check_failure" {
  display_name = "${google_cloud_run_v2_service.this.name}-uptime-check"
  combiner = "OR"
  conditions {
    display_name = "uptime check failure"
    condition_threshold {
      threshold_value = 1
      duration = "60s"
      comparison = "COMPARISON_GT"
      trigger {
        count = 1
      }
      aggregations {
        alignment_period = "1200s"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
        group_by_fields = [
          "resource.label.project_id",
          "resource.label.host"
        ]
        per_series_aligner = "ALIGN_NEXT_OLDER"
      }
      filter = join(" ", [
        "resource.type = \"uptime_url\"",
        "AND metric.type = \"monitoring.googleapis.com/uptime_check/check_passed\"",
        "AND metric.labels.check_id =",
        "\"${google_monitoring_uptime_check_config.this.uptime_check_id}\"",
      ])
    }
  }

  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids
}

resource "google_monitoring_alert_policy" "error_rate" {
  display_name = "${google_cloud_run_v2_service.this.name}-error-rate"
  combiner = "OR"

  conditions {
    display_name = "high request error rate"
    condition_threshold {
      threshold_value = 10
      duration = "0s"
      comparison = "COMPARISON_GT"
      trigger {
        percent = 10
      }
      aggregations {
        alignment_period = "300s"
        per_series_aligner = "ALIGN_RATE"
      }
      filter = join(" ", [
        "resource.type = \"cloud_run_revision\"",
        "AND resource.labels.service_name = \"${google_cloud_run_v2_service.this.name}\"",
        "AND metric.type = \"run.googleapis.com/request_count\"",
        "AND metric.labels.response_code_class = \"5xx\"",
      ])
    }
  }

  severity = var.alert_severity
  notification_channels = var.alert_notification_channel_ids
}
