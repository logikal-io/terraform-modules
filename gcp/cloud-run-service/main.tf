terraform {
  required_version = "~> 1.0"
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 6.19"
    }
  }
}

# Cloud Run service
resource "google_project_service" "cloud_run" {
  service = "run.googleapis.com"
}

resource "google_cloud_run_v2_service" "service" {
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
    service_account = google_service_account.service.email
    containers {
      name = var.project
      image = var.image
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
      volume_mounts {
        name = "cloudsql"
        mount_path = "/cloudsql"
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
        period_seconds = 10
        failure_threshold = 5
        http_get {
          path = "/"
          port = var.container_port
        }
      }
    }
    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = var.cloud_sql_instances
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

resource "google_compute_region_network_endpoint_group" "service" {
  name = "${var.name}-network-endpoint"
  region = google_cloud_run_v2_service.service.location
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = google_cloud_run_v2_service.service.name
  }

  depends_on = [google_project_service.compute_engine]
}

resource "google_compute_backend_service" "service" {
  name = "${var.name}-backend-service"
  connection_draining_timeout_sec = 30
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec = 30

  security_policy = var.security_policy

  backend {
    group = google_compute_region_network_endpoint_group.service.id
  }
}

# Load balancer routing
resource "google_compute_url_map" "service" {
  name = "${var.name}-service"
  default_service = google_compute_backend_service.service.id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [google_project_service.compute_engine]
}

resource "google_project_service" "certificate_manager" {
  service = "certificatemanager.googleapis.com"
}

resource "google_compute_managed_ssl_certificate" "service" {
  name = replace(var.domain, ".", "-")

  managed {
    domains = ["${var.domain}."]
  }

  depends_on = [google_project_service.certificate_manager, google_project_service.compute_engine]
}

resource "google_compute_target_https_proxy" "service" {
  name = "${var.name}-service"
  url_map = google_compute_url_map.service.id
  quic_override = "ENABLE"
  ssl_certificates = [google_compute_managed_ssl_certificate.service.id]
  http_keep_alive_timeout_sec = 610  # default value
}

resource "google_compute_global_address" "service" {
  name = "${var.name}-ip"
  address_type = "EXTERNAL"
  ip_version = "IPV4"

  depends_on = [google_project_service.compute_engine]
}

resource "google_compute_global_forwarding_rule" "service_https" {
  name = "${var.name}-service-https"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  target = google_compute_target_https_proxy.service.id
  ip_address = google_compute_global_address.service.address
  port_range = "443"
}

# HTTP to HTTPS redirection
resource "google_compute_url_map" "http_to_https" {
  # name = "${var.name}-http-to-https"  # TODO
  name = "http-to-https"

  default_url_redirect {
    https_redirect = true
    strip_query = false
    redirect_response_code = "PERMANENT_REDIRECT"
  }

  depends_on = [google_project_service.compute_engine]
}

resource "google_compute_target_http_proxy" "http_to_https_proxy" {
  # name = "${var.name}-http-to-https-proxy"  # TODO
  name = "http-to-https-proxy"
  url_map = google_compute_url_map.http_to_https.id
}

resource "google_compute_global_forwarding_rule" "service_http" {
  name = "${var.name}-service-http"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  target = google_compute_target_http_proxy.http_to_https_proxy.id
  ip_address = google_compute_global_address.service.address
  port_range = "80"
}
