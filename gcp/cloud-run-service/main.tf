terraform {
  required_version = "~> 1.0"
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 6.19"
    }
  }
}

# Artifact registry
resource "google_project_service" "artifact_registry" {
  count = var.image == null ? 1 : 0

  service = "artifactregistry.googleapis.com"
}

resource "google_artifact_registry_repository" "this" {
  count = var.image == null ? 1 : 0

  location = var.region
  repository_id = var.name
  format = "DOCKER"

  cleanup_policies {
    id = "delete-old"
    action = "DELETE"
    condition {
      older_than = "${24 * 60 * 60}s"  # 1 day
    }
  }

  cleanup_policies {
    id = "keep-last-3"
    action = "KEEP"
    most_recent_versions {
      keep_count = 3
    }
  }

  depends_on = [google_project_service.artifact_registry]
}

# Cloud Run service
resource "google_project_service" "cloud_run" {
  service = "run.googleapis.com"
}

resource "google_cloud_run_v2_service" "this" {
  name = var.name
  location = var.region
  project = var.project_id

  ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  template {
    execution_environment = "EXECUTION_ENVIRONMENT_GEN2"
    max_instance_request_concurrency = 100
    session_affinity = false
    timeout = "30s"

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }
    service_account = google_service_account.this.email
    containers {
      image = var.image != null ? var.image : join("/", [
        "${one(google_artifact_registry_repository.this[*].location)}-docker.pkg.dev",
        var.project_id,
        one(google_artifact_registry_repository.this[*].repository_id),
        "${var.name}:${var.image_version}",
      ])
      ports {
        container_port = var.container_port
      }
      dynamic "env" {
        for_each = var.env

        content {
          name = env.key
          value = env.value
        }
      }
      dynamic "env" {
        for_each = var.env_secrets

        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret = env.value
              version = "latest"
            }
          }
        }
      }
      dynamic "volume_mounts" {
        for_each = length(var.cloud_sql_instances) > 0 ? [1] : []

        content {
          name = "cloudsql"
          mount_path = "/cloudsql"
        }
      }
      resources {
        limits = {
          cpu = var.server_cpu
          memory = var.server_memory
        }
        cpu_idle = true
        startup_cpu_boost = false
      }
      liveness_probe {
        timeout_seconds = 3
        period_seconds = 30
        failure_threshold = 3
        http_get {
          path = "/"
          port = var.container_port
        }
      }
      startup_probe {
        timeout_seconds = 3
        period_seconds = var.startup_probe_period_seconds
        failure_threshold = 3
        http_get {
          path = "/"
          port = var.container_port
        }
      }
    }
    dynamic "vpc_access" {
      for_each = var.egress_subnetwork_id != null ? [1] : []

      content {
        network_interfaces {
          subnetwork = var.egress_subnetwork_id
        }
        egress = "ALL_TRAFFIC"
      }
    }
    dynamic "volumes" {
      for_each = length(var.cloud_sql_instances) > 0 ? [1] : []

      content {
        name = "cloudsql"
        cloud_sql_instance {
          instances = [for instance in var.cloud_sql_instances : instance.connection_name]
        }
      }
    }
  }

  depends_on = [google_project_service.cloud_run]
  lifecycle {
    ignore_changes = [
      client,
      client_version,
      template[0].containers[0].image,
    ]
  }
}

# Backend service
# (https://cloud.google.com/load-balancing/docs/https/setup-global-ext-https-serverless)
resource "google_project_service" "compute_engine" {
  service = "compute.googleapis.com"
}

resource "google_compute_region_network_endpoint_group" "this" {
  name = "${var.name}-network-endpoint"
  region = google_cloud_run_v2_service.this.location
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = google_cloud_run_v2_service.this.name
  }

  depends_on = [google_project_service.compute_engine]
}

resource "google_compute_backend_service" "this" {
  name = "${var.name}-backend-service"
  connection_draining_timeout_sec = 30
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec = 30

  security_policy = one(google_compute_security_policy.this[*].id)

  backend {
    group = google_compute_region_network_endpoint_group.this.id
  }
}

# Load balancer routing
resource "google_compute_url_map" "this" {
  name = "${var.name}-service"
  default_service = google_compute_backend_service.this.id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [google_project_service.compute_engine]
}

resource "google_project_service" "certificate_manager" {
  service = "certificatemanager.googleapis.com"
}

resource "google_compute_managed_ssl_certificate" "this" {
  name = replace(var.domain, ".", "-")

  managed {
    domains = ["${var.domain}."]
  }

  depends_on = [google_project_service.certificate_manager, google_project_service.compute_engine]

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_target_https_proxy" "this" {
  name = "${var.name}-service"
  url_map = google_compute_url_map.this.id
  quic_override = "ENABLE"
  ssl_certificates = [google_compute_managed_ssl_certificate.this.id]
  http_keep_alive_timeout_sec = 610  # default value
}

resource "google_compute_global_address" "this" {
  name = "${var.name}-ip"
  address_type = "EXTERNAL"
  ip_version = "IPV4"

  depends_on = [google_project_service.compute_engine]
}

resource "google_compute_global_forwarding_rule" "service_https" {
  name = "${var.name}-service-https"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  target = google_compute_target_https_proxy.this.id
  ip_address = google_compute_global_address.this.address
  port_range = "443"
}

# HTTP to HTTPS redirection
resource "google_compute_url_map" "http_to_https" {
  name = "${var.name}-http-to-https"

  default_url_redirect {
    https_redirect = true
    strip_query = false
    redirect_response_code = "PERMANENT_REDIRECT"
  }

  depends_on = [google_project_service.compute_engine]
}

resource "google_compute_target_http_proxy" "http_to_https_proxy" {
  name = "${var.name}-http-to-https-proxy"
  url_map = google_compute_url_map.http_to_https.id
}

resource "google_compute_global_forwarding_rule" "service_http" {
  name = "${var.name}-service-http"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  target = google_compute_target_http_proxy.http_to_https_proxy.id
  ip_address = google_compute_global_address.this.address
  port_range = "80"
}

# DNS
data "google_dns_managed_zone" "this" {
  name = var.domain_managed_zone_name
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
