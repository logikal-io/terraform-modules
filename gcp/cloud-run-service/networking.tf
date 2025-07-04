# Firewall
resource "google_compute_security_policy" "this" {
  count = var.allowed_source_ip_ranges != null ? 1 : 0

  name = "${var.name}-service"

  # Allow rule
  rule {
    action = "allow"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = var.allowed_source_ip_ranges
      }
    }
    description = "Allow specific IP ranges"
  }

  # Default deny all rule
  rule {
    action = "deny(403)"
    priority = "2147483647"
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
