# Firewall
locals {
  uptime_check_ips = [
    # See https://cloud.google.com/monitoring/uptime-checks/using-uptime-checks
    for entry in jsondecode(file("${path.module}/uptime_check_source_ips.json"))
    : entry["ipAddress"]
  ]
}

resource "google_compute_security_policy" "this" {
  count = var.allowed_source_ip_ranges != null ? 1 : 0

  name = "${var.name}-service"

  # Allow rules
  dynamic "rule" {
    for_each = (
      var.allowed_source_ip_ranges != null ?
      chunklist(var.allowed_source_ip_ranges, 10) # the limit is 10 IP ranges per rule
      : []
    )

    content {
      action   = "allow"
      priority = 1000 + rule.key
      match {
        versioned_expr = "SRC_IPS_V1"
        config {
          src_ip_ranges = rule.value
        }
      }
      description = "Allow specific IP ranges"
    }
  }

  dynamic "rule" {
    for_each = (
      var.allow_uptime_check_source_ips ?
      chunklist(local.uptime_check_ips, 10) # the limit is 10 IP ranges per rule
      : []
    )

    content {
      action = "allow"
      priority = 2000 + rule.key
      match {
        versioned_expr = "SRC_IPS_V1"
        config {
          src_ip_ranges = rule.value
        }
      }
      description = "Allow uptime check source IPs"
    }
  }

  # Default deny all rule
  rule {
    action = "deny(403)"
    priority = 2147483647
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default deny all"
  }

  depends_on = [google_project_service.compute_engine]
}
