terraform {
  required_version = "~> 1.0"
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 7.10"
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

data "google_artifact_registry_docker_image" "this" {
  count = var.image == null ? 1 : 0

  location = one(google_artifact_registry_repository.this[*]).location
  repository_id = one(google_artifact_registry_repository.this[*]).repository_id
  image_name = (
    var.image_version != null ? "${coalesce(var.image_name, var.name)}:${var.image_version}"
    : coalesce(var.image_name, var.name)
  )
}

# Cloud Run job
resource "google_project_service" "cloud_run" {
  service = "run.googleapis.com"
}

resource "google_cloud_run_v2_job" "this" {
  name = var.name
  location = var.region
  project = var.project_id

  template {
    task_count = 1
    template {
      execution_environment = "EXECUTION_ENVIRONMENT_GEN2"
      timeout = "${60 * 60}s"  # 60 minutes
      max_retries = 0

      service_account = local.service_account_email
      containers {
        image = (
          var.image != null ? var.image :
          one(data.google_artifact_registry_docker_image.this[*]).self_link
        )
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
        command = var.command
        args = var.args
      }
      volumes {
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
      template[0].template[0].containers[0].image,
    ]
  }
}
