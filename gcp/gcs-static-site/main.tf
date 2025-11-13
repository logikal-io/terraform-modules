terraform {
  required_version = "~> 1.0"
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 7.10"
    }
  }
}

locals {
  domain_id = replace(var.domain, ".", "-")
  website_id = "website-${local.domain_id}"
}

# Bucket
resource "google_storage_bucket" "this" {
  name = local.website_id
  location = var.bucket_location
  storage_class = "STANDARD"

  website {
    main_page_suffix = "index.html"
    not_found_page = "404/index.html"
  }

  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_member" "bucket_public_access" {
  bucket = google_storage_bucket.this.name
  role = "roles/storage.objectViewer"
  member = "allUsers"
}

# Backend service
resource "google_project_service" "compute_engine" {
  service = "compute.googleapis.com"
}

resource "google_compute_security_policy" "cloud_armor_edge" {
  name = "${local.website_id}-cloud-armor-edge"
  type = "CLOUD_ARMOR_EDGE"

  depends_on = [google_project_service.compute_engine]
}

resource "google_compute_backend_bucket" "this" {
  name = "${local.website_id}-backend-bucket"
  bucket_name = google_storage_bucket.this.name
  enable_cdn = true
  edge_security_policy = google_compute_security_policy.cloud_armor_edge.id
  compression_mode = "AUTOMATIC"

  cdn_policy {
    cache_mode = (var.force_cache_all ? "FORCE_CACHE_ALL" : "CACHE_ALL_STATIC")
  }
}

# Load balancer routing
resource "google_compute_url_map" "this" {
  name = "${local.website_id}-service"
  default_service = google_compute_backend_bucket.this.id

  dynamic "host_rule" {
    for_each = var.www_redirect ? [1] : []

    content {
      hosts = ["www.${var.domain}"]
      path_matcher = "www-to-root"
    }
  }

  dynamic "path_matcher" {
    for_each = var.www_redirect ? [1] : []

    content {
      name = "www-to-root"

      default_url_redirect {
        host_redirect = var.domain
        redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
        strip_query = false
      }
    }
  }

  dynamic "host_rule" {
    for_each = length(var.redirects) > 0 ? [1] : []
    content {
      hosts = [var.domain]
      path_matcher = "redirects"
    }
  }

  dynamic "path_matcher" {
    for_each = length(var.redirects) > 0 ? [1] : []
    content {
      default_service = google_compute_backend_bucket.this.id
      name = "redirects"
      dynamic "path_rule" {
        for_each = var.redirects
        content {
          paths = path_rule.value["paths"]
          url_redirect {
            https_redirect = true
            path_redirect = path_rule.value["redirect"]
            redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
            strip_query = false
          }
        }
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_project_service" "certificate_manager" {
  service = "certificatemanager.googleapis.com"
}

resource "google_compute_managed_ssl_certificate" "this" {
  name = local.domain_id

  managed {
    domains = ["${var.domain}."]
  }

  depends_on = [google_project_service.certificate_manager, google_project_service.compute_engine]

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_managed_ssl_certificate" "www" {
  count = var.www_redirect ? 1 : 0

  name = "www-${replace(var.domain, ".", "-")}"

  managed {
    domains = ["www.${var.domain}."]
  }

  depends_on = [google_project_service.certificate_manager, google_project_service.compute_engine]

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_target_https_proxy" "this" {
  name = "${local.website_id}-service"
  url_map = google_compute_url_map.this.id
  quic_override = "ENABLE"
  ssl_certificates = compact([
    google_compute_managed_ssl_certificate.this.id,
    one(google_compute_managed_ssl_certificate.www[*].id),
  ])
}

resource "google_compute_global_address" "this" {
  name = local.domain_id

  depends_on = [google_project_service.compute_engine]
}

resource "google_compute_global_forwarding_rule" "service_https" {
  name = "${local.website_id}-service"
  load_balancing_scheme = "EXTERNAL"
  target = google_compute_target_https_proxy.this.id
  ip_address = google_compute_global_address.this.address
  port_range = "443"
}

# HTTP to HTTPS redirection
resource "google_compute_url_map" "http_to_https" {
  name = "${local.website_id}-http-to-https"

  default_url_redirect {
    https_redirect = true
    strip_query = false
    redirect_response_code = "PERMANENT_REDIRECT"
  }

  dynamic "host_rule" {
    for_each = length(var.redirects) > 0 ? ["host_rule"] : []
    content {
      hosts = [var.domain]
      path_matcher = "redirects"
    }
  }

  dynamic "path_matcher" {
    for_each = length(var.redirects) > 0 ? ["host_rule"] : []
    content {
      name = "redirects"
      default_url_redirect {
        https_redirect = true
        strip_query = false
      }
      dynamic "path_rule" {
        for_each = var.redirects
        content {
          paths = path_rule.value["paths"]
          url_redirect {
            https_redirect = true
            path_redirect = path_rule.value["redirect"]
            redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
            strip_query = false
          }
        }
      }
    }
  }

  depends_on = [google_project_service.compute_engine]

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_target_http_proxy" "http_to_https_proxy" {
  name = "${local.website_id}-http-to-https-proxy"
  url_map = google_compute_url_map.http_to_https.id
}

resource "google_compute_global_forwarding_rule" "service_http" {
  name = "${local.website_id}-service-http"
  load_balancing_scheme = "EXTERNAL"
  target = google_compute_target_http_proxy.http_to_https_proxy.id
  ip_address = google_compute_global_address.this.address
  port_range = "80"
}

# DNS
data "google_dns_managed_zone" "this" {
  name = coalesce(var.domain_managed_zone_name, replace(var.domain, ".", "-"))
  project = coalesce(var.domain_project_id, var.project_id)
}

resource "google_dns_record_set" "this" {
  name = "${var.domain}."
  type = "A"
  ttl = 300

  managed_zone = data.google_dns_managed_zone.this.name
  project = coalesce(var.domain_project_id, var.project_id)

  rrdatas = [google_compute_global_address.this.address]
}

resource "google_dns_record_set" "www" {
  count = var.www_redirect ? 1 : 0

  name = "www.${var.domain}."
  type = "CNAME"
  ttl = 300

  managed_zone = data.google_dns_managed_zone.this.name
  project = coalesce(var.domain_project_id, var.project_id)

  rrdatas = ["${var.domain}."]
}
