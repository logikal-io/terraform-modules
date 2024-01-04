terraform {
  required_version = "~> 1.0"
  required_providers {
    random = {
      source = "hashicorp/random"
      version = "~> 3.6"
    }
    google = {
      source = "hashicorp/google"
      version = "~> 5.9"
    }
    google-beta = {
      source = "hashicorp/google-beta"
      version = "~> 5.9"
    }
  }
}

# Secret key
resource "google_project_service" "secret_manager" {
  service = "secretmanager.googleapis.com"
}

resource "random_password" "website_secret_key" {
  length = 50
}

resource "google_secret_manager_secret" "website_secret_key" {
  secret_id = "${var.name}-website-secret-key"
  replication {
    auto {}
  }

  depends_on = [google_project_service.secret_manager]
}

resource "google_secret_manager_secret_version" "website_secret_key" {
  secret = google_secret_manager_secret.website_secret_key.id
  secret_data = random_password.website_secret_key.result
}

# Artifact Registry
resource "google_project_service" "artifact_registry" {
  service = "artifactregistry.googleapis.com"
}

resource "google_artifact_registry_repository" "website" {
  provider = google-beta  # needed for cleanup_policies

  location = var.region
  repository_id = "website"
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
}

# Website service
resource "google_project_service" "cloud_run" {
  service = "run.googleapis.com"
}

resource "google_cloud_run_v2_service" "website" {
  name = "${var.name}-website"
  location = google_artifact_registry_repository.website.location
  project = var.project_id

  ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  traffic {
    type = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  template {
    execution_environment = "EXECUTION_ENVIRONMENT_GEN2"
    max_instance_request_concurrency = 100
    session_affinity = false
    timeout = "30s"

    scaling {
      min_instance_count = 1
      max_instance_count = 2
    }
    service_account = google_service_account.website_service.email
    containers {
      name = var.name
      image = join("/", [
        "${google_artifact_registry_repository.website.location}-docker.pkg.dev",
        var.project_id,
        google_artifact_registry_repository.website.repository_id,
        "${var.name}:${var.image_tag}",
      ])
      ports {
        container_port = 8080
      }
      env {
        name = "WORKERS"
        value = var.server_cpu
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
          port = 8080
        }
      }
      startup_probe {
        timeout_seconds = 3
        period_seconds = 10
        failure_threshold = 5
        http_get {
          path = "/"
          port = 8080
        }
      }
    }
    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.website.connection_name]
      }
    }
  }

  depends_on = [
    # Services
    google_project_service.cloud_run,
    # Accesses
    google_secret_manager_secret_iam_member.secret_access_for_website_service_user,
    google_project_iam_member.cloud_sql_access_for_website_service_user,
  ]
  lifecycle {
    ignore_changes = [template[0].containers[0].image]
  }
}

# Command job
resource "google_cloud_run_v2_job" "website_command" {
  name = "${var.name}-website-command"
  location = google_artifact_registry_repository.website.location
  project = var.project_id

  template {
    task_count = 1
    template {
      execution_environment = "EXECUTION_ENVIRONMENT_GEN2"
      timeout = "${30 * 60}s"  # 30 minutes
      max_retries = 0

      service_account = google_service_account.website_service.email
      containers {
        name = var.name
        image = join("/", [
          "${google_artifact_registry_repository.website.location}-docker.pkg.dev",
          var.project_id,
          google_artifact_registry_repository.website.repository_id,
          "${var.name}:${var.image_tag}",
        ])
        env {
          name = "DJANGO_SETTINGS_MODULE"
          value = "${var.name}.settings.production"
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
        }
        command = ["orb", "app", "--command"]
        args = ["manage"]
      }
      volumes {
        name = "cloudsql"
        cloud_sql_instance {
          instances = [google_sql_database_instance.website.connection_name]
        }
      }
    }
  }

  depends_on = [google_project_service.cloud_run]
  lifecycle {
    ignore_changes = [template[0].template[0].containers[0].image]
  }
}

# Backend service
resource "google_project_service" "compute_engine" {
  service = "compute.googleapis.com"
}

resource "google_compute_region_network_endpoint_group" "website" {
  name = "${var.name}-website-network-endpoint"
  region = google_cloud_run_v2_service.website.location
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = google_cloud_run_v2_service.website.name
  }

  depends_on = [google_project_service.compute_engine]
}

resource "google_compute_backend_service" "website" {
  name = "${var.name}-website-backend-service"
  connection_draining_timeout_sec = 30
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec = 30

  backend {
    group = google_compute_region_network_endpoint_group.website.id
  }
}

# Load balancer routing
resource "google_compute_url_map" "website_service" {
  name = "${var.name}-website-service"
  default_service = google_compute_backend_service.website.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_project_service" "certificate_manager" {
  service = "certificatemanager.googleapis.com"
}

resource "google_compute_managed_ssl_certificate" "website" {
  name = replace(var.domain, ".", "-")

  managed {
    domains = ["${var.domain}."]
  }

  depends_on = [google_project_service.certificate_manager, google_project_service.compute_engine]
}

resource "google_compute_target_https_proxy" "website_service" {
  name = "${var.name}-website-service"
  url_map = google_compute_url_map.website_service.id
  quic_override = "ENABLE"
  ssl_certificates = [google_compute_managed_ssl_certificate.website.id]
  http_keep_alive_timeout_sec = 610  # default value
}

resource "google_compute_global_address" "website" {
  name = "${var.name}-website-ip"
  address_type = "EXTERNAL"
  ip_version = "IPV4"

  depends_on = [google_project_service.compute_engine]
}

resource "google_compute_global_forwarding_rule" "website_service" {
  name = "${var.name}-website-service"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  target = google_compute_target_https_proxy.website_service.id
  ip_address = google_compute_global_address.website.address
  port_range = "443"
}
