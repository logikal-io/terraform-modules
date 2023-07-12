terraform {
  required_version = "~> 1.0"
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 4.52"
    }
  }
}

locals {
  domain_id = replace(var.domain, ".", "-")
  website_id = "website-${local.domain_id}"
}

# Bucket
resource "google_storage_bucket" "website" {
  name = local.website_id
  location = var.bucket_location
  storage_class = "STANDARD"

  website {
    main_page_suffix = "index.html"
    not_found_page = "404/index.html"
  }

  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_member" "public" {
  bucket = google_storage_bucket.website.name
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

resource "google_compute_backend_bucket" "website" {
  name = "${local.website_id}-backend-bucket"
  bucket_name = google_storage_bucket.website.name
  enable_cdn = true
  edge_security_policy = google_compute_security_policy.cloud_armor_edge.id
  compression_mode = "AUTOMATIC"

  cdn_policy {
    cache_mode = (var.force_cache_all ? "FORCE_CACHE_ALL" : "CACHE_ALL_STATIC")
  }
}

# Global service routing
resource "google_compute_url_map" "website_service" {
  name = "${local.website_id}-service"
  default_service = google_compute_backend_bucket.website.id

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
      default_service = google_compute_backend_bucket.website.id
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

resource "google_compute_managed_ssl_certificate" "website" {
  name = local.domain_id

  managed {
    domains = ["${var.domain}."]
  }

  depends_on = [google_project_service.compute_engine]
}

resource "google_compute_target_https_proxy" "website_service" {
  name = "${local.website_id}-service"
  url_map = google_compute_url_map.website_service.id
  quic_override = "ENABLE"
  ssl_certificates = [google_compute_managed_ssl_certificate.website.id]
}

resource "google_compute_global_address" "website" {
  name = local.domain_id

  depends_on = [google_project_service.compute_engine]
}

resource "google_compute_global_forwarding_rule" "website_service" {
  name = "${local.website_id}-service"
  load_balancing_scheme = "EXTERNAL"
  target = google_compute_target_https_proxy.website_service.id
  ip_address = google_compute_global_address.website.address
  port_range = "443"
}

# Global HTTP to HTTPS redirection
resource "google_compute_url_map" "https_redirect" {
  name = "${local.website_id}-https-redirect"

  default_url_redirect {
    https_redirect = true
    strip_query = false
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

resource "google_compute_target_http_proxy" "https_redirect" {
  name = "${local.website_id}-https-redirect"
  url_map = google_compute_url_map.https_redirect.id
}

resource "google_compute_global_forwarding_rule" "https_redirect" {
  name = "${local.website_id}-https-redirect"
  load_balancing_scheme = "EXTERNAL"
  target = google_compute_target_http_proxy.https_redirect.id
  ip_address = google_compute_global_address.website.address
  port_range = "80"
}

# Logs
resource "google_project_service" "bigquery" {
  service = "bigquery.googleapis.com"
}

resource "google_bigquery_dataset" "website_logs" {
  dataset_id = replace("${local.website_id}-logs", "-", "_")
  location = var.bigquery_location
  delete_contents_on_destroy = false
  max_time_travel_hours = 48

  depends_on = [google_project_service.bigquery]
}

resource "google_logging_project_sink" "website_logs" {
  name = "${local.website_id}-logs"
  destination = "bigquery.googleapis.com/${google_bigquery_dataset.website_logs.id}"
  filter = join(" AND ", [
    "resource.type = http_load_balancer",
    join(" = ", [
      "resource.labels.forwarding_rule_name",
      google_compute_global_forwarding_rule.website_service.name,
    ]),
  ])

  unique_writer_identity = true

  bigquery_options {
    use_partitioned_tables = true
  }
}

resource "google_bigquery_dataset_iam_binding" "log_writer" {
  dataset_id = google_bigquery_dataset.website_logs.dataset_id
  role = "roles/bigquery.dataEditor"
  members = [google_logging_project_sink.website_logs.writer_identity]
}

# Uploader service account permissions
resource "google_storage_bucket_iam_member" "website_uploader_object_admin" {
  bucket = google_storage_bucket.website.name
  role = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.uploader_service_account_email}"
}

resource "google_project_iam_custom_role" "bucket_metadata_reader" {
  role_id = "BucketMetadataReader"
  title = "Bucket Metadata Reader"
  permissions = ["storage.buckets.get"]
}

resource "google_storage_bucket_iam_member" "website_uploader_bucket_metadata_reader" {
  bucket = google_storage_bucket.website.name
  role = google_project_iam_custom_role.bucket_metadata_reader.id
  member = "serviceAccount:${var.uploader_service_account_email}"
}

resource "google_project_iam_custom_role" "cdn_invalidator" {
  role_id = "CDNInvalidator"
  title = "CDN Invalidator"
  permissions = ["compute.urlMaps.get", "compute.urlMaps.invalidateCache"]
}

resource "google_project_iam_member" "website_cdn_invalidator" {
  project = var.project_id
  role = google_project_iam_custom_role.cdn_invalidator.id
  member = "serviceAccount:${var.uploader_service_account_email}"
}
