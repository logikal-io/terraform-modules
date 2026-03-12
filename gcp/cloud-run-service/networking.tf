# Firewall
locals {
  uptime_check_ips = [
    # See https://cloud.google.com/monitoring/uptime-checks/using-uptime-checks
    for entry in jsondecode(file("${path.module}/uptime_check_source_ips.json"))
    : entry["ipAddress"]
  ]
}

resource "google_compute_security_policy" "this" {
  name = "${var.name}-service"

  # Only allow hostname
  rule {
    action = "deny(403)"
    priority = 1000
    match {
      expr {
        expression = "request.headers['host'] != '${var.domain}'"
      }
    }
    description = "Deny IP-based access"
  }

  # IP range rules
  dynamic "rule" {
    for_each = (
      var.allowed_source_ip_ranges != null ?
      chunklist(var.allowed_source_ip_ranges, 10) # the limit is 10 IP ranges per rule
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
      description = "Allow specific IP ranges"
    }
  }

  dynamic "rule" {
    for_each = (
      var.allowed_source_ip_ranges != null && var.allow_uptime_check_source_ips ?
      chunklist(local.uptime_check_ips, 10) # the limit is 10 IP ranges per rule
      : []
    )

    content {
      action = "allow"
      priority = 3000 + rule.key
      match {
        versioned_expr = "SRC_IPS_V1"
        config {
          src_ip_ranges = rule.value
        }
      }
      description = "Allow uptime check source IPs"
    }
  }

  # Default rule
  rule {
    action = var.allowed_source_ip_ranges != null ? "deny(403)" : "allow"
    priority = 2147483647
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = var.allowed_source_ip_ranges != null ? "Default deny all" : "Default allow all"
  }

  depends_on = [google_project_service.compute_engine]
}
